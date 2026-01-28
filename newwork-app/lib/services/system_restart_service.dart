import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backend_manager.dart';
import '../data/providers/storage_provider.dart';

/// 재시작 단계
enum RestartPhase {
  /// 유휴 상태
  idle,

  /// 준비 단계 - 진행 중 작업 완료, 상태 저장
  prepare,

  /// 종료 단계 - 백엔드 종료
  shutdown,

  /// 재시작 단계 - 백엔드 재시작, 헬스체크 대기
  restart,

  /// 복구 단계 - 프로바이더 새로고침, UI 복원
  recover,

  /// 완료
  completed,

  /// 실패
  failed,
}

/// 재시작 진행 상황
class RestartProgress {
  final RestartPhase phase;
  final double progress; // 0.0 ~ 1.0
  final String message;
  final String? errorMessage;
  final DateTime timestamp;

  RestartProgress({
    required this.phase,
    required this.progress,
    required this.message,
    this.errorMessage,
  }) : timestamp = DateTime.now();

  bool get isComplete => phase == RestartPhase.completed;
  bool get isFailed => phase == RestartPhase.failed;
  bool get isInProgress => !isComplete && !isFailed && phase != RestartPhase.idle;
}

/// 저장된 앱 상태
class SavedAppState {
  final String? activeSessionId;
  final int? activeTabIndex;
  final String? activeWorkspaceId;
  final Map<String, dynamic>? additionalData;
  final DateTime savedAt;

  SavedAppState({
    this.activeSessionId,
    this.activeTabIndex,
    this.activeWorkspaceId,
    this.additionalData,
  }) : savedAt = DateTime.now();

  Map<String, dynamic> toJson() => {
        'activeSessionId': activeSessionId,
        'activeTabIndex': activeTabIndex,
        'activeWorkspaceId': activeWorkspaceId,
        'additionalData': additionalData,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedAppState.fromJson(Map<String, dynamic> json) {
    return SavedAppState(
      activeSessionId: json['activeSessionId'] as String?,
      activeTabIndex: json['activeTabIndex'] as int?,
      activeWorkspaceId: json['activeWorkspaceId'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }
}

/// 시스템 재시작 서비스
///
/// 전체 시스템(백엔드 + 프론트엔드 상태)을 안전하게 재시작합니다.
class SystemRestartService {
  final BackendManager _backendManager;
  final StorageProvider _storage;
  final WidgetRef? _ref;

  // 재시작 설정
  static const Duration _phaseTimeout = Duration(seconds: 30);
  static const String _savedStateKey = 'system_restart_saved_state';

  // 상태
  RestartPhase _currentPhase = RestartPhase.idle;
  RestartPhase get currentPhase => _currentPhase;

  // 진행 상황 스트림
  final StreamController<RestartProgress> _progressController =
      StreamController<RestartProgress>.broadcast();

  // 콜백
  void Function()? onPrepare;
  void Function()? onShutdown;
  void Function()? onRestart;
  void Function()? onRecover;
  void Function()? onComplete;
  void Function(String error)? onFailed;

  // 프로바이더 새로고침 콜백
  Future<void> Function()? refreshProviders;

  SystemRestartService({
    required BackendManager backendManager,
    required StorageProvider storage,
    WidgetRef? ref,
  })  : _backendManager = backendManager,
        _storage = storage,
        _ref = ref;

  /// 진행 상황 스트림
  Stream<RestartProgress> get progressStream => _progressController.stream;

  /// 현재 진행 중인지 확인
  bool get isRestarting => _currentPhase != RestartPhase.idle &&
      _currentPhase != RestartPhase.completed &&
      _currentPhase != RestartPhase.failed;

  /// 우아한 재시작 수행
  ///
  /// 4단계 프로토콜을 순차적으로 실행합니다:
  /// 1. PREPARE  → 진행 중 작업 완료, 상태 저장
  /// 2. SHUTDOWN → 백엔드 종료
  /// 3. RESTART  → 백엔드 재시작, 헬스체크 대기
  /// 4. RECOVER  → 프로바이더 새로고침, UI 복원
  Future<bool> performGracefulRestart({
    SavedAppState? stateToSave,
  }) async {
    if (isRestarting) {
      print('[SystemRestart] 이미 재시작 진행 중');
      return false;
    }

    print('[SystemRestart] 시스템 재시작 시작');
    final stopwatch = Stopwatch()..start();

    try {
      // Phase 1: PREPARE
      await _executePhase(
        RestartPhase.prepare,
        0.1,
        '재시작 준비 중...',
        () async {
          onPrepare?.call();
          if (stateToSave != null) {
            await _saveState(stateToSave);
          }
        },
      );

      // Phase 2: SHUTDOWN
      await _executePhase(
        RestartPhase.shutdown,
        0.3,
        '백엔드 종료 중...',
        () async {
          onShutdown?.call();
          await _backendManager.stopBackend();
        },
      );

      // 짧은 대기
      await Future.delayed(const Duration(milliseconds: 500));

      // Phase 3: RESTART
      await _executePhase(
        RestartPhase.restart,
        0.6,
        '백엔드 재시작 중...',
        () async {
          onRestart?.call();
          await _backendManager.startBackend();

          // 헬스체크 대기
          _emitProgress(RestartPhase.restart, 0.7, '헬스체크 대기 중...');
          final isHealthy = await _waitForHealthy();
          if (!isHealthy) {
            throw Exception('백엔드 헬스체크 실패');
          }
        },
      );

      // Phase 4: RECOVER
      await _executePhase(
        RestartPhase.recover,
        0.9,
        '상태 복원 중...',
        () async {
          onRecover?.call();
          await refreshProviders?.call();
        },
      );

      // 완료
      _currentPhase = RestartPhase.completed;
      _emitProgress(RestartPhase.completed, 1.0, '재시작 완료');
      onComplete?.call();

      stopwatch.stop();
      print('[SystemRestart] 재시작 완료 (${stopwatch.elapsedMilliseconds}ms)');
      return true;

    } catch (e) {
      print('[SystemRestart] 재시작 실패: $e');
      _currentPhase = RestartPhase.failed;
      _emitProgress(RestartPhase.failed, 0, '재시작 실패', errorMessage: e.toString());
      onFailed?.call(e.toString());
      return false;
    }
  }

  /// 단계 실행
  Future<void> _executePhase(
    RestartPhase phase,
    double progress,
    String message,
    Future<void> Function() action,
  ) async {
    _currentPhase = phase;
    _emitProgress(phase, progress, message);
    print('[SystemRestart] Phase: $phase - $message');

    try {
      await action().timeout(_phaseTimeout);
    } on TimeoutException {
      throw Exception('$phase 단계 타임아웃 (${_phaseTimeout.inSeconds}초)');
    }
  }

  /// 백엔드 헬스체크 대기
  Future<bool> _waitForHealthy({int maxAttempts = 10}) async {
    for (int i = 0; i < maxAttempts; i++) {
      if (await _backendManager.checkHealth()) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  /// 앱 상태 저장
  Future<void> _saveState(SavedAppState state) async {
    try {
      final json = jsonEncode(state.toJson());
      await _storage.setString(_savedStateKey, json);
      print('[SystemRestart] 상태 저장 완료');
    } catch (e) {
      print('[SystemRestart] 상태 저장 실패: $e');
    }
  }

  /// 저장된 상태 불러오기
  Future<SavedAppState?> loadSavedState() async {
    try {
      final json = _storage.getString(_savedStateKey);
      if (json == null) return null;

      final data = jsonDecode(json) as Map<String, dynamic>;
      return SavedAppState.fromJson(data);
    } catch (e) {
      print('[SystemRestart] 상태 불러오기 실패: $e');
      return null;
    }
  }

  /// 저장된 상태 삭제
  Future<void> clearSavedState() async {
    try {
      await _storage.remove(_savedStateKey);
    } catch (e) {
      print('[SystemRestart] 상태 삭제 실패: $e');
    }
  }

  /// 진행 상황 전파
  void _emitProgress(
    RestartPhase phase,
    double progress,
    String message, {
    String? errorMessage,
  }) {
    if (!_progressController.isClosed) {
      _progressController.add(RestartProgress(
        phase: phase,
        progress: progress,
        message: message,
        errorMessage: errorMessage,
      ));
    }
  }

  /// 강제 종료 (비상용)
  Future<void> forceStop() async {
    print('[SystemRestart] 강제 종료');
    _currentPhase = RestartPhase.idle;
  }

  /// 리소스 정리
  void dispose() {
    _progressController.close();
  }
}

/// 빠른 백엔드만 재시작 (상태 유지)
extension QuickRestart on SystemRestartService {
  /// 백엔드만 빠르게 재시작
  Future<bool> quickRestartBackend() async {
    print('[SystemRestart] 빠른 백엔드 재시작');

    try {
      _emitProgress(RestartPhase.shutdown, 0.3, '백엔드 재시작 중...');
      await _backendManager.restartBackend();

      _emitProgress(RestartPhase.restart, 0.7, '헬스체크 중...');
      final isHealthy = await _waitForHealthy();

      if (isHealthy) {
        _emitProgress(RestartPhase.completed, 1.0, '재시작 완료');
        return true;
      }
      return false;
    } catch (e) {
      print('[SystemRestart] 빠른 재시작 실패: $e');
      return false;
    }
  }
}
