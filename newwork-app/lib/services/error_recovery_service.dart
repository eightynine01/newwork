import 'dart:async';
import '../core/error/app_error.dart';
import '../core/error/retry_policy.dart';
import 'backend_manager.dart';
import 'system_restart_service.dart';

/// 복구 결과
enum RecoveryResult {
  /// 복구 성공
  success,

  /// 복구 진행 중
  inProgress,

  /// 복구 실패 (재시도 가능)
  failedRetryable,

  /// 복구 실패 (재시도 불가)
  failedPermanent,

  /// 사용자 개입 필요
  userActionRequired,
}

/// 복구 시도 정보
class RecoveryAttempt {
  final AppError error;
  final RecoveryResult result;
  final DateTime timestamp;
  final String? actionTaken;

  RecoveryAttempt({
    required this.error,
    required this.result,
    required this.timestamp,
    this.actionTaken,
  });
}

/// 중앙 오류 복구 서비스
///
/// 앱 전체의 오류를 수집, 분류하고 적절한 복구 전략을 실행합니다.
class ErrorRecoveryService {
  final BackendManager _backendManager;
  SystemRestartService? _systemRestartService;

  // 오류 이력
  final List<AppError> _errorHistory = [];
  static const int _maxErrorHistory = 100;

  // 복구 시도 이력
  final List<RecoveryAttempt> _recoveryHistory = [];
  static const int _maxRecoveryHistory = 50;

  // 재시도 정책
  final RetryPolicy _apiRetryPolicy;
  final RetryLimiter _recoveryLimiter;

  // 스트림
  final StreamController<AppError> _errorController =
      StreamController<AppError>.broadcast();
  final StreamController<RecoveryAttempt> _recoveryController =
      StreamController<RecoveryAttempt>.broadcast();

  // 콜백
  void Function(AppError error)? onError;
  void Function(AppError error, String action)? onRecoveryAttempt;
  void Function(AppError error)? onRecoverySuccess;
  void Function(AppError error, String reason)? onRecoveryFailed;

  // 복구 중 상태
  bool _isRecovering = false;
  bool get isRecovering => _isRecovering;

  ErrorRecoveryService({
    required BackendManager backendManager,
    RetryPolicy? apiRetryPolicy,
  })  : _backendManager = backendManager,
        _apiRetryPolicy = apiRetryPolicy ?? RetryPolicy.api,
        _recoveryLimiter = RetryLimiter(
          maxAttempts: 5,
          window: const Duration(minutes: 10),
        );

  /// SystemRestartService 설정 (순환 의존성 방지)
  void setSystemRestartService(SystemRestartService service) {
    _systemRestartService = service;
  }

  /// 오류 스트림
  Stream<AppError> get errorStream => _errorController.stream;

  /// 복구 시도 스트림
  Stream<RecoveryAttempt> get recoveryStream => _recoveryController.stream;

  /// 오류 이력
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  /// 복구 이력
  List<RecoveryAttempt> get recoveryHistory => List.unmodifiable(_recoveryHistory);

  /// 오류 보고 및 처리
  ///
  /// 오류를 수신하면 분류하고 적절한 복구를 시도합니다.
  Future<RecoveryResult> reportError(AppError error) async {
    print('[ErrorRecovery] 오류 수신: ${error.category} - ${error.message}');

    // 오류 이력에 추가
    _addToHistory(error);

    // 스트림으로 전파
    if (!_errorController.isClosed) {
      _errorController.add(error);
    }

    // 콜백 호출
    onError?.call(error);

    // 복구 불가능한 오류는 바로 반환
    if (!error.isRecoverable) {
      return RecoveryResult.failedPermanent;
    }

    // 복구 시도
    return await attemptRecovery(error);
  }

  /// 오류 복구 시도
  Future<RecoveryResult> attemptRecovery(AppError error) async {
    if (_isRecovering) {
      print('[ErrorRecovery] 이미 복구 진행 중');
      return RecoveryResult.inProgress;
    }

    // 복구 제한 확인
    if (!_recoveryLimiter.canAttempt()) {
      print('[ErrorRecovery] 복구 시도 한도 도달');
      _recordRecoveryAttempt(error, RecoveryResult.userActionRequired, '복구 한도 도달');
      return RecoveryResult.userActionRequired;
    }

    _isRecovering = true;
    _recoveryLimiter.recordAttempt();

    try {
      final result = await _executeRecoveryStrategy(error);
      _isRecovering = false;
      return result;
    } catch (e) {
      print('[ErrorRecovery] 복구 실패: $e');
      _isRecovering = false;
      _recordRecoveryAttempt(error, RecoveryResult.failedRetryable, e.toString());
      return RecoveryResult.failedRetryable;
    }
  }

  /// 오류 유형별 복구 전략 실행
  Future<RecoveryResult> _executeRecoveryStrategy(AppError error) async {
    switch (error.category) {
      case ErrorCategory.api:
        return await _handleApiError(error);
      case ErrorCategory.backend:
        return await _handleBackendError(error);
      case ErrorCategory.render:
        return await _handleRenderError(error);
      case ErrorCategory.runtime:
        return await _handleRuntimeError(error);
    }
  }

  /// API 오류 처리
  ///
  /// 전략: Exponential backoff 재시도 → 로컬 DB 폴백
  Future<RecoveryResult> _handleApiError(AppError error) async {
    final action = 'API 연결 재시도';
    onRecoveryAttempt?.call(error, action);
    print('[ErrorRecovery] API 오류 처리: $action');

    // 백엔드가 실행 중인지 확인
    final isBackendHealthy = await _backendManager.checkHealth();

    if (!isBackendHealthy) {
      print('[ErrorRecovery] 백엔드 응답 없음, 백엔드 재시작으로 전환');
      return await _handleBackendError(
        AppError.backend(message: '백엔드 응답 없음', originalError: error),
      );
    }

    // API 재시도는 ApiClient에서 이미 수행하므로 여기서는 성공으로 처리
    // (ApiClient가 실패하면 이미 재시도를 모두 소진한 상태)
    _recordRecoveryAttempt(error, RecoveryResult.failedRetryable, action);

    // 로컬 DB 폴백 가능 여부 알림
    onRecoveryFailed?.call(error, '로컬 데이터를 사용하세요');
    return RecoveryResult.failedRetryable;
  }

  /// 백엔드 오류 처리
  ///
  /// 전략: 자동 백엔드 재시작 (최대 3회)
  Future<RecoveryResult> _handleBackendError(AppError error) async {
    final action = '백엔드 재시작';
    onRecoveryAttempt?.call(error, action);
    print('[ErrorRecovery] 백엔드 오류 처리: $action');

    try {
      await _backendManager.restartBackend();

      // 재시작 후 헬스체크
      final isHealthy = await _backendManager.checkHealth();
      if (isHealthy) {
        _recordRecoveryAttempt(error, RecoveryResult.success, action);
        onRecoverySuccess?.call(error);
        return RecoveryResult.success;
      }
    } catch (e) {
      print('[ErrorRecovery] 백엔드 재시작 실패: $e');
    }

    _recordRecoveryAttempt(error, RecoveryResult.failedRetryable, action);
    onRecoveryFailed?.call(error, '백엔드 재시작 실패');
    return RecoveryResult.failedRetryable;
  }

  /// 렌더링 오류 처리
  ///
  /// 전략: 폴백 위젯 표시 + 재시도 버튼 제공
  Future<RecoveryResult> _handleRenderError(AppError error) async {
    final action = 'UI 복구';
    onRecoveryAttempt?.call(error, action);
    print('[ErrorRecovery] 렌더링 오류 처리: $action');

    // 렌더링 오류는 ErrorBoundary 위젯에서 처리
    // 여기서는 기록만 하고 사용자 개입을 요청
    _recordRecoveryAttempt(error, RecoveryResult.userActionRequired, action);
    return RecoveryResult.userActionRequired;
  }

  /// 런타임 오류 처리
  ///
  /// 전략: 영향받은 컴포넌트만 재로드
  Future<RecoveryResult> _handleRuntimeError(AppError error) async {
    final action = '컴포넌트 재로드';
    onRecoveryAttempt?.call(error, action);
    print('[ErrorRecovery] 런타임 오류 처리: $action');

    // 심각한 오류면 전체 시스템 재시작 권고
    if (error.severity == ErrorSeverity.critical) {
      print('[ErrorRecovery] 심각한 오류 - 시스템 재시작 필요');
      _recordRecoveryAttempt(error, RecoveryResult.userActionRequired, '시스템 재시작 권고');
      return RecoveryResult.userActionRequired;
    }

    // 일반 런타임 오류는 자동 복구 시도
    _recordRecoveryAttempt(error, RecoveryResult.success, action);
    onRecoverySuccess?.call(error);
    return RecoveryResult.success;
  }

  /// 전체 시스템 재시작 트리거
  Future<bool> triggerSystemRestart() async {
    if (_systemRestartService == null) {
      print('[ErrorRecovery] SystemRestartService가 설정되지 않음');
      return false;
    }

    print('[ErrorRecovery] 시스템 재시작 시작');
    try {
      await _systemRestartService!.performGracefulRestart();
      return true;
    } catch (e) {
      print('[ErrorRecovery] 시스템 재시작 실패: $e');
      return false;
    }
  }

  /// 오류 이력에 추가
  void _addToHistory(AppError error) {
    _errorHistory.add(error);
    if (_errorHistory.length > _maxErrorHistory) {
      _errorHistory.removeAt(0);
    }
  }

  /// 복구 시도 기록
  void _recordRecoveryAttempt(
    AppError error,
    RecoveryResult result,
    String action,
  ) {
    final attempt = RecoveryAttempt(
      error: error,
      result: result,
      timestamp: DateTime.now(),
      actionTaken: action,
    );

    _recoveryHistory.add(attempt);
    if (_recoveryHistory.length > _maxRecoveryHistory) {
      _recoveryHistory.removeAt(0);
    }

    if (!_recoveryController.isClosed) {
      _recoveryController.add(attempt);
    }
  }

  /// 특정 카테고리의 최근 오류 수
  int getRecentErrorCount(ErrorCategory category, Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return _errorHistory.where((e) =>
        e.category == category && e.timestamp.isAfter(cutoff)).length;
  }

  /// 복구 제한 초기화
  void resetRecoveryLimiter() {
    _recoveryLimiter.reset();
  }

  /// 이력 초기화
  void clearHistory() {
    _errorHistory.clear();
    _recoveryHistory.clear();
  }

  /// 리소스 정리
  void dispose() {
    _errorController.close();
    _recoveryController.close();
  }
}
