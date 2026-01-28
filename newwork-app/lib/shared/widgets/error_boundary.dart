import 'package:flutter/material.dart';
import '../../core/error/app_error.dart';
import '../../core/theme/colors.dart';

/// 오류 경계 위젯
///
/// 자식 위젯에서 발생하는 렌더링 오류를 캡처하고
/// 폴백 UI를 표시합니다.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(AppError error, VoidCallback retry)? fallbackBuilder;
  final void Function(AppError error)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  AppError? _error;

  @override
  void initState() {
    super.initState();
  }

  void _handleError(Object error, StackTrace stackTrace) {
    final appError = AppError.render(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );

    setState(() {
      _error = appError;
    });

    widget.onError?.call(appError);
  }

  void _retry() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(_error!, _retry);
      }
      return _DefaultErrorFallback(
        error: _error!,
        onRetry: _retry,
      );
    }

    return widget.child;
  }
}

/// 기본 오류 폴백 UI
class _DefaultErrorFallback extends StatelessWidget {
  final AppError error;
  final VoidCallback onRetry;

  const _DefaultErrorFallback({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.errorDark.withOpacity(0.1)
            : AppColors.errorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.errorDark : AppColors.errorLight,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? AppColors.errorDark : AppColors.errorLight,
          ),
          const SizedBox(height: 16),
          Text(
            '화면 표시 중 오류가 발생했습니다',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 전체 화면 오류 페이지
class ErrorPage extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onRestart;

  const ErrorPage({
    super.key,
    required this.error,
    this.onRetry,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.errorDark.withOpacity(0.1)
                        : AppColors.errorLight.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getErrorIcon(error.category),
                    size: 64,
                    color: isDark ? AppColors.errorDark : AppColors.errorLight,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _getErrorTitle(error.category),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error.userMessage,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (error.technicalDetails != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error.technicalDetails!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (onRetry != null)
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('다시 시도'),
                      ),
                    if (onRetry != null && onRestart != null)
                      const SizedBox(width: 12),
                    if (onRestart != null)
                      OutlinedButton.icon(
                        onPressed: onRestart,
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('시스템 재시작'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getErrorIcon(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.api:
        return Icons.cloud_off;
      case ErrorCategory.backend:
        return Icons.dns;
      case ErrorCategory.render:
        return Icons.broken_image;
      case ErrorCategory.runtime:
        return Icons.warning_amber;
    }
  }

  String _getErrorTitle(ErrorCategory category) {
    switch (category) {
      case ErrorCategory.api:
        return '서버 연결 오류';
      case ErrorCategory.backend:
        return '백엔드 서비스 오류';
      case ErrorCategory.render:
        return '화면 표시 오류';
      case ErrorCategory.runtime:
        return '앱 오류';
    }
  }
}

/// 작은 인라인 오류 표시
class InlineError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineError({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.errorDark.withOpacity(0.1)
            : AppColors.errorLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: isDark ? AppColors.errorDark : AppColors.errorLight,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.errorDark : AppColors.errorLight,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.refresh,
                  size: 16,
                  color: isDark ? AppColors.errorDark : AppColors.errorLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
