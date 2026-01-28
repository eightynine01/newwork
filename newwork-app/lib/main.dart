import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/backend_manager.dart';
import 'services/error_recovery_service.dart';
import 'services/system_restart_service.dart';
import 'data/providers/dashboard_providers.dart';
import 'data/providers/storage_provider.dart';
import 'core/error/app_error.dart';
import 'app.dart';

void main() async {
  // Zone을 사용한 전역 오류 처리
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Flutter 프레임워크 오류 핸들러
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _handleFlutterError(details);
      };

      // 위젯 빌드 오류 시 폴백 UI
      ErrorWidget.builder = (details) {
        return _ErrorFallbackWidget(error: details);
      };

      // 백엔드 매니저 생성
      final backendManager = BackendManager();

      // 스토리지 초기화
      final storage = StorageProvider();
      await storage.init();

      // 오류 복구 서비스 생성
      final errorRecoveryService = ErrorRecoveryService(
        backendManager: backendManager,
      );

      // 시스템 재시작 서비스 생성
      final systemRestartService = SystemRestartService(
        backendManager: backendManager,
        storage: storage,
      );

      // 순환 참조 설정
      errorRecoveryService.setSystemRestartService(systemRestartService);

      // 백엔드 오류 콜백 설정
      backendManager.onError = (error) {
        print('[Main] Backend error: ${error.message}');
        errorRecoveryService.reportError(error);
      };

      // 오류 복구 콜백 설정
      errorRecoveryService.onError = (error) {
        print('[Main] Error reported: ${error.category} - ${error.message}');
      };

      errorRecoveryService.onRecoveryAttempt = (error, action) {
        print('[Main] Recovery attempt: $action');
      };

      errorRecoveryService.onRecoverySuccess = (error) {
        print('[Main] Recovery successful for: ${error.category}');
      };

      errorRecoveryService.onRecoveryFailed = (error, reason) {
        print('[Main] Recovery failed: $reason');
      };

      // 백엔드 시작
      try {
        print('Starting NewWork backend...');
        await backendManager.startBackend();
        print('✓ Backend started successfully');
      } catch (e) {
        print('✗ Failed to start backend: $e');
        // 에러 발생 시에도 앱은 실행 (사용자에게 에러 표시)
      }

      // Provider 오버라이드로 서비스 주입
      runApp(
        ProviderScope(
          overrides: [
            backendManagerProvider.overrideWithValue(backendManager),
            storageProvider.overrideWithValue(storage),
            errorRecoveryServiceProvider.overrideWithValue(errorRecoveryService),
            systemRestartServiceProvider.overrideWithValue(systemRestartService),
          ],
          child: const App(),
        ),
      );
    },
    (error, stackTrace) {
      // Zone 외부에서 발생한 비동기 오류 처리
      print('[Main] Unhandled error: $error');
      print('[Main] Stack trace: $stackTrace');

      // 심각한 오류 로깅 (추후 크래시 리포팅 서비스 연동 가능)
      _logCriticalError(error, stackTrace);
    },
  );
}

/// Flutter 프레임워크 오류 처리
void _handleFlutterError(FlutterErrorDetails details) {
  print('[Flutter] Error: ${details.exceptionAsString()}');

  // 렌더링 오류인 경우
  if (details.library == 'rendering library') {
    print('[Flutter] Rendering error detected');
  }
}

/// 심각한 오류 로깅
void _logCriticalError(Object error, StackTrace stackTrace) {
  // TODO: 크래시 리포팅 서비스 연동 (Firebase Crashlytics, Sentry 등)
  print('[Critical] $error');
  print('[Critical] $stackTrace');
}

/// 위젯 빌드 오류 시 표시되는 폴백 위젯
class _ErrorFallbackWidget extends StatelessWidget {
  final FlutterErrorDetails error;

  const _ErrorFallbackWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.withOpacity(0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '화면 표시 오류',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error.exceptionAsString(),
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 12,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
