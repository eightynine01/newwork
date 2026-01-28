import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/system_restart_service.dart';
import '../../core/theme/colors.dart';

/// 재시작 확인 다이얼로그
class RestartConfirmDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const RestartConfirmDialog({
    super.key,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RestartConfirmDialog(
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.restart_alt,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text('시스템 재시작'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '전체 시스템을 재시작하시겠습니까?',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.check_circle_outline,
                  text: '현재 작업 상태가 저장됩니다',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.check_circle_outline,
                  text: '백엔드 서비스가 재시작됩니다',
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.check_circle_outline,
                  text: '재시작 후 상태가 복원됩니다',
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('재시작'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}

/// 재시작 진행 다이얼로그
class RestartProgressDialog extends StatefulWidget {
  final SystemRestartService restartService;
  final VoidCallback? onComplete;
  final VoidCallback? onFailed;

  const RestartProgressDialog({
    super.key,
    required this.restartService,
    this.onComplete,
    this.onFailed,
  });

  static Future<void> show({
    required BuildContext context,
    required SystemRestartService restartService,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RestartProgressDialog(
        restartService: restartService,
        onComplete: () => Navigator.of(context).pop(),
        onFailed: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<RestartProgressDialog> createState() => _RestartProgressDialogState();
}

class _RestartProgressDialogState extends State<RestartProgressDialog> {
  StreamSubscription<RestartProgress>? _subscription;
  RestartProgress? _currentProgress;

  @override
  void initState() {
    super.initState();
    _subscription = widget.restartService.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentProgress = progress;
        });

        if (progress.isComplete) {
          widget.onComplete?.call();
        } else if (progress.isFailed) {
          widget.onFailed?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _currentProgress;

    return AlertDialog(
      title: Row(
        children: [
          if (progress?.isFailed ?? false)
            Icon(Icons.error_outline, color: AppColors.errorLight)
          else if (progress?.isComplete ?? false)
            Icon(Icons.check_circle_outline, color: AppColors.successLight)
          else
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            progress?.isFailed ?? false
                ? '재시작 실패'
                : progress?.isComplete ?? false
                    ? '재시작 완료'
                    : '재시작 중...',
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 진행률 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress?.progress ?? 0,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation(
                progress?.isFailed ?? false
                    ? AppColors.errorLight
                    : progress?.isComplete ?? false
                        ? AppColors.successLight
                        : theme.colorScheme.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // 현재 단계
          Text(
            progress?.message ?? '준비 중...',
            style: theme.textTheme.bodyMedium,
          ),

          // 에러 메시지
          if (progress?.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.errorLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      progress!.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.errorLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 단계 표시
          _PhaseIndicator(
            currentPhase: progress?.phase ?? RestartPhase.idle,
          ),
        ],
      ),
      actions: [
        if (progress?.isFailed ?? false)
          ElevatedButton(
            onPressed: widget.onFailed,
            child: const Text('닫기'),
          ),
      ],
    );
  }
}

/// 재시작 단계 표시기
class _PhaseIndicator extends StatelessWidget {
  final RestartPhase currentPhase;

  const _PhaseIndicator({required this.currentPhase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final phases = [
      (RestartPhase.prepare, '준비', Icons.settings),
      (RestartPhase.shutdown, '종료', Icons.power_settings_new),
      (RestartPhase.restart, '재시작', Icons.refresh),
      (RestartPhase.recover, '복구', Icons.restore),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: phases.map((phase) {
        final isComplete = _isPhaseComplete(phase.$1, currentPhase);
        final isCurrent = phase.$1 == currentPhase;
        final isFailed = currentPhase == RestartPhase.failed;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isComplete
                    ? AppColors.successLight.withOpacity(0.1)
                    : isCurrent
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isComplete
                      ? AppColors.successLight
                      : isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                phase.$3,
                size: 16,
                color: isComplete
                    ? AppColors.successLight
                    : isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phase.$2,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isComplete || isCurrent
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  bool _isPhaseComplete(RestartPhase phase, RestartPhase current) {
    const order = [
      RestartPhase.prepare,
      RestartPhase.shutdown,
      RestartPhase.restart,
      RestartPhase.recover,
      RestartPhase.completed,
    ];

    final phaseIndex = order.indexOf(phase);
    final currentIndex = order.indexOf(current);

    return phaseIndex < currentIndex || current == RestartPhase.completed;
  }
}

/// 간단한 재시작 버튼
class RestartButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool compact;

  const RestartButton({
    super.key,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.restart_alt),
        tooltip: '시스템 재시작',
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.restart_alt, size: 18),
      label: const Text('재시작'),
    );
  }
}
