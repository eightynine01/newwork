import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../core/error/app_error.dart';
import '../core/error/retry_policy.dart';

/// 백엔드 연결 상태
enum BackendStatus {
  /// 시작되지 않음
  stopped,

  /// 시작 중
  starting,

  /// 정상 실행 중
  running,

  /// 응답 없음 (헬스체크 실패)
  unresponsive,

  /// 재시작 중
  restarting,

  /// 오류 발생
  error,
}

/// 백엔드 헬스 정보
class BackendHealth {
  final BackendStatus status;
  final DateTime timestamp;
  final int? latencyMs;
  final String? errorMessage;
  final int consecutiveFailures;

  BackendHealth({
    required this.status,
    required this.timestamp,
    this.latencyMs,
    this.errorMessage,
    this.consecutiveFailures = 0,
  });

  bool get isHealthy => status == BackendStatus.running;

  BackendHealth copyWith({
    BackendStatus? status,
    DateTime? timestamp,
    int? latencyMs,
    String? errorMessage,
    int? consecutiveFailures,
  }) {
    return BackendHealth(
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      latencyMs: latencyMs ?? this.latencyMs,
      errorMessage: errorMessage,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    );
  }
}

/// Python 백엔드 프로세스를 관리하는 서비스
///
/// NewWork 앱이 시작될 때 번들된 Python 백엔드를 자동으로 시작하고,
/// 헬스 모니터링을 통해 장애를 감지하고 자동으로 복구합니다.
class BackendManager {
  Process? _backendProcess;
  final int port;
  final String host;

  // 헬스 모니터링
  Timer? _healthCheckTimer;
  final Duration _healthCheckInterval;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;

  // 자동 재시작 제한
  final RetryLimiter _restartLimiter;

  // 상태 스트림
  final StreamController<BackendHealth> _healthController =
      StreamController<BackendHealth>.broadcast();

  // 오류 콜백
  void Function(AppError error)? onError;

  BackendManager({
    this.port = 8000,
    this.host = '127.0.0.1',
    Duration? healthCheckInterval,
  })  : _healthCheckInterval = healthCheckInterval ?? const Duration(seconds: 10),
        _restartLimiter = RetryLimiter(
          maxAttempts: 3,
          window: const Duration(minutes: 5),
        );

  bool get isRunning => _backendProcess != null;

  /// 헬스 상태 스트림
  Stream<BackendHealth> get healthStream => _healthController.stream;

  /// 현재 상태
  BackendStatus _currentStatus = BackendStatus.stopped;
  BackendStatus get currentStatus => _currentStatus;

  /// 백엔드 서버 시작
  ///
  /// 앱 번들 내 Python 백엔드 실행 파일을 찾아 실행합니다.
  /// 서버가 준비될 때까지 대기합니다.
  ///
  /// Throws:
  ///   - [BackendStartException] 백엔드 시작 실패 시
  Future<void> startBackend() async {
    if (_backendProcess != null) {
      print('Backend already running');
      return;
    }

    _updateStatus(BackendStatus.starting);

    try {
      // 백엔드 실행 파일 경로
      final backendPath = await _getBackendExecutablePath();

      print('Starting backend from: $backendPath');

      // 실행 파일 존재 확인
      if (!await File(backendPath).exists()) {
        throw BackendStartException(
          'Backend executable not found at: $backendPath',
        );
      }

      // Python 백엔드 실행
      _backendProcess = await Process.start(
        backendPath,
        [
          '--host',
          host,
          '--port',
          port.toString(),
        ],
        mode: ProcessStartMode.detachedWithStdio,
      );

      // 프로세스 출력 로깅
      _backendProcess!.stdout.listen((data) {
        print('[Backend] ${String.fromCharCodes(data)}');
      });

      _backendProcess!.stderr.listen((data) {
        print('[Backend Error] ${String.fromCharCodes(data)}');
      });

      // 프로세스 종료 감지
      _backendProcess!.exitCode.then((exitCode) {
        print('Backend process exited with code: $exitCode');
        final wasRunning = _currentStatus == BackendStatus.running;
        _backendProcess = null;

        if (exitCode != 0 && exitCode != 15) {
          // SIGTERM (15)이 아닌 비정상 종료
          print('Backend crashed! Exit code: $exitCode');
          _handleBackendCrash(exitCode);
        } else if (wasRunning) {
          _updateStatus(BackendStatus.stopped);
        }
      });

      // 서버 준비 대기
      await _waitForBackend();

      _updateStatus(BackendStatus.running);
      _consecutiveFailures = 0;

      // 헬스 모니터링 시작
      _startHealthMonitor();

      print('✓ Backend started successfully on http://$host:$port');
    } catch (e) {
      _backendProcess = null;
      _updateStatus(BackendStatus.error, errorMessage: e.toString());
      throw BackendStartException('Failed to start backend: $e');
    }
  }

  /// 백엔드 서버 중지
  ///
  /// 실행 중인 백엔드 프로세스를 정상적으로 종료합니다.
  /// SIGTERM을 전송하고, 타임아웃 후에도 종료되지 않으면 SIGKILL을 전송합니다.
  Future<void> stopBackend() async {
    _stopHealthMonitor();

    if (_backendProcess == null) {
      print('Backend not running');
      return;
    }

    try {
      print('Stopping backend...');

      // SIGTERM 전송
      _backendProcess!.kill(ProcessSignal.sigterm);

      // 3초간 정상 종료 대기
      final exitCode = await _backendProcess!.exitCode.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('Backend did not stop gracefully, forcing...');
          _backendProcess!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );

      print('Backend stopped with exit code: $exitCode');
      _backendProcess = null;
      _updateStatus(BackendStatus.stopped);
    } catch (e) {
      print('Error stopping backend: $e');
      _backendProcess = null;
      _updateStatus(BackendStatus.stopped);
    }
  }

  /// 백엔드 재시작
  Future<void> restartBackend() async {
    _updateStatus(BackendStatus.restarting);
    await stopBackend();
    await Future.delayed(const Duration(seconds: 1));
    await startBackend();
  }

  /// 헬스 모니터링 시작
  void _startHealthMonitor() {
    _stopHealthMonitor();

    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) async {
      await _performHealthCheck();
    });

    print('Health monitoring started (interval: ${_healthCheckInterval.inSeconds}s)');
  }

  /// 헬스 모니터링 중지
  void _stopHealthMonitor() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// 헬스체크 수행
  Future<void> _performHealthCheck() async {
    if (_backendProcess == null) return;

    final stopwatch = Stopwatch()..start();
    final isHealthy = await checkHealth();
    stopwatch.stop();

    if (isHealthy) {
      if (_consecutiveFailures > 0) {
        print('Backend recovered after $_consecutiveFailures failures');
      }
      _consecutiveFailures = 0;
      _emitHealth(BackendHealth(
        status: BackendStatus.running,
        timestamp: DateTime.now(),
        latencyMs: stopwatch.elapsedMilliseconds,
        consecutiveFailures: 0,
      ));
    } else {
      _consecutiveFailures++;
      print('Health check failed ($_consecutiveFailures/$_maxConsecutiveFailures)');

      _emitHealth(BackendHealth(
        status: BackendStatus.unresponsive,
        timestamp: DateTime.now(),
        errorMessage: 'Health check failed',
        consecutiveFailures: _consecutiveFailures,
      ));

      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        print('Max consecutive failures reached, attempting auto-restart...');
        await _attemptAutoRestart();
      }
    }
  }

  /// 자동 재시작 시도
  Future<void> _attemptAutoRestart() async {
    if (!_restartLimiter.canAttempt()) {
      final waitTime = _restartLimiter.waitTime;
      print('Auto-restart limit reached. Wait ${waitTime?.inSeconds}s');

      final error = AppError.backend(
        message: '자동 재시작 한도에 도달했습니다. 수동 재시작이 필요합니다.',
      );
      onError?.call(error);
      _updateStatus(BackendStatus.error, errorMessage: error.message);
      return;
    }

    _restartLimiter.recordAttempt();
    print('Auto-restart attempt ${3 - _restartLimiter.remainingAttempts}/3');

    try {
      await restartBackend();
      print('Auto-restart successful');
    } catch (e) {
      print('Auto-restart failed: $e');
      final error = AppError.backend(
        message: '백엔드 자동 재시작 실패',
        originalError: e,
      );
      onError?.call(error);
    }
  }

  /// 백엔드 크래시 처리
  void _handleBackendCrash(int exitCode) {
    _updateStatus(BackendStatus.error, errorMessage: 'Exit code: $exitCode');

    final error = BackendCrashException(
      '백엔드가 예상치 못하게 종료되었습니다',
      exitCode: exitCode,
    );
    onError?.call(error.toAppError());

    // 자동 재시작 시도
    _attemptAutoRestart();
  }

  /// 상태 업데이트
  void _updateStatus(BackendStatus status, {String? errorMessage}) {
    _currentStatus = status;
    _emitHealth(BackendHealth(
      status: status,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
      consecutiveFailures: _consecutiveFailures,
    ));
  }

  /// 헬스 상태 전파
  void _emitHealth(BackendHealth health) {
    if (!_healthController.isClosed) {
      _healthController.add(health);
    }
  }

  /// 백엔드 실행 파일 경로 찾기
  ///
  /// OS별로 앱 번들 내 백엔드 바이너리 위치가 다릅니다:
  /// - macOS: .app/Contents/Resources/backend/
  /// - Linux: 실행파일과 같은 디렉토리
  /// - Windows: 실행파일과 같은 디렉토리
  Future<String> _getBackendExecutablePath() async {
    final executableDir = path.dirname(Platform.resolvedExecutable);

    if (Platform.isMacOS) {
      // macOS 앱 번들 구조
      return path.join(
        executableDir,
        '..',
        'Resources',
        'backend',
        'newwork-backend',
      );
    } else if (Platform.isLinux) {
      // Linux 디렉토리 구조
      return path.join(
        executableDir,
        'backend',
        'newwork-backend',
      );
    } else if (Platform.isWindows) {
      // Windows 디렉토리 구조
      return path.join(
        executableDir,
        'backend',
        'newwork-backend.exe',
      );
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }
  }

  /// 백엔드 서버가 준비될 때까지 대기
  ///
  /// Health check 엔드포인트에 최대 30번 (15초) 요청을 시도합니다.
  ///
  /// Throws:
  ///   - [BackendStartException] 타임아웃 시
  Future<void> _waitForBackend() async {
    const maxAttempts = 30;
    const delayBetweenAttempts = Duration(milliseconds: 500);

    for (int i = 0; i < maxAttempts; i++) {
      try {
        final response = await http
            .get(Uri.parse('http://$host:$port/health'))
            .timeout(const Duration(seconds: 1));

        if (response.statusCode == 200) {
          print('Backend health check passed (attempt ${i + 1}/$maxAttempts)');
          return;
        }
      } catch (e) {
        // 연결 실패는 정상 (서버가 아직 시작 중)
        if (i % 5 == 0) {
          // 5번마다 로그
          print('Waiting for backend... (attempt ${i + 1}/$maxAttempts)');
        }
      }

      await Future.delayed(delayBetweenAttempts);
    }

    throw BackendStartException(
      'Backend failed to start within timeout (${maxAttempts * 500}ms)',
    );
  }

  /// 백엔드 헬스 체크
  ///
  /// Returns: 백엔드가 정상 응답하면 true
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('http://$host:$port/health'))
          .timeout(const Duration(seconds: 2));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 재시작 제한 초기화
  void resetRestartLimiter() {
    _restartLimiter.reset();
  }

  /// 리소스 정리
  void dispose() {
    _stopHealthMonitor();
    _healthController.close();
  }
}

/// 백엔드 시작 실패 예외
class BackendStartException implements Exception {
  final String message;

  BackendStartException(this.message);

  @override
  String toString() => 'BackendStartException: $message';
}
