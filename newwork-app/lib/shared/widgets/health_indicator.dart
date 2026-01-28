import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/backend_manager.dart';
import '../../data/providers/dashboard_providers.dart';
import '../../core/theme/colors.dart';

/// 백엔드 상태 표시기
///
/// 현재 백엔드 연결 상태를 시각적으로 표시합니다.
class HealthIndicator extends ConsumerStatefulWidget {
  final bool showLabel;
  final bool compact;
  final VoidCallback? onTap;

  const HealthIndicator({
    super.key,
    this.showLabel = true,
    this.compact = false,
    this.onTap,
  });

  @override
  ConsumerState<HealthIndicator> createState() => _HealthIndicatorState();
}

class _HealthIndicatorState extends ConsumerState<HealthIndicator> {
  StreamSubscription<BackendHealth>? _subscription;
  BackendHealth? _currentHealth;

  @override
  void initState() {
    super.initState();
    _subscribeToHealth();
  }

  void _subscribeToHealth() {
    final backendManager = ref.read(backendManagerProvider);
    _subscription = backendManager.healthStream.listen((health) {
      if (mounted) {
        setState(() {
          _currentHealth = health;
        });
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
    final status = _currentHealth?.status ?? BackendStatus.stopped;

    if (widget.compact) {
      return _buildCompactIndicator(context, status);
    }

    return _buildFullIndicator(context, status);
  }

  Widget _buildCompactIndicator(BuildContext context, BackendStatus status) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _StatusDot(status: status),
      ),
    );
  }

  Widget _buildFullIndicator(BuildContext context, BackendStatus status) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getBackgroundColor(status, theme),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getBorderColor(status),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusDot(status: status),
            if (widget.showLabel) ...[
              const SizedBox(width: 8),
              Text(
                _getStatusLabel(status),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getTextColor(status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (_currentHealth?.latencyMs != null) ...[
              const SizedBox(width: 8),
              Text(
                '${_currentHealth!.latencyMs}ms',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(BackendStatus status, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    switch (status) {
      case BackendStatus.running:
        return (isDark ? AppColors.successDark : AppColors.successLight)
            .withOpacity(0.1);
      case BackendStatus.starting:
      case BackendStatus.restarting:
        return (isDark ? AppColors.warningDark : AppColors.warningLight)
            .withOpacity(0.1);
      case BackendStatus.unresponsive:
      case BackendStatus.error:
        return (isDark ? AppColors.errorDark : AppColors.errorLight)
            .withOpacity(0.1);
      case BackendStatus.stopped:
        return theme.colorScheme.surface;
    }
  }

  Color _getBorderColor(BackendStatus status) {
    switch (status) {
      case BackendStatus.running:
        return AppColors.successLight;
      case BackendStatus.starting:
      case BackendStatus.restarting:
        return AppColors.warningLight;
      case BackendStatus.unresponsive:
      case BackendStatus.error:
        return AppColors.errorLight;
      case BackendStatus.stopped:
        return Colors.grey;
    }
  }

  Color _getTextColor(BackendStatus status) {
    switch (status) {
      case BackendStatus.running:
        return AppColors.successLight;
      case BackendStatus.starting:
      case BackendStatus.restarting:
        return AppColors.warningLight;
      case BackendStatus.unresponsive:
      case BackendStatus.error:
        return AppColors.errorLight;
      case BackendStatus.stopped:
        return Colors.grey;
    }
  }

  String _getStatusLabel(BackendStatus status) {
    switch (status) {
      case BackendStatus.running:
        return '연결됨';
      case BackendStatus.starting:
        return '시작 중...';
      case BackendStatus.restarting:
        return '재시작 중...';
      case BackendStatus.unresponsive:
        return '응답 없음';
      case BackendStatus.error:
        return '오류';
      case BackendStatus.stopped:
        return '중지됨';
    }
  }
}

/// 상태 점
class _StatusDot extends StatefulWidget {
  final BackendStatus status;

  const _StatusDot({required this.status});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (_shouldPulse(widget.status)) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldPulse(widget.status)) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  bool _shouldPulse(BackendStatus status) {
    return status == BackendStatus.starting ||
        status == BackendStatus.restarting ||
        status == BackendStatus.unresponsive;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getColor(widget.status).withOpacity(
              _shouldPulse(widget.status) ? 0.5 + (_controller.value * 0.5) : 1.0,
            ),
            shape: BoxShape.circle,
            boxShadow: widget.status == BackendStatus.running
                ? [
                    BoxShadow(
                      color: _getColor(widget.status).withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }

  Color _getColor(BackendStatus status) {
    switch (status) {
      case BackendStatus.running:
        return AppColors.successLight;
      case BackendStatus.starting:
      case BackendStatus.restarting:
        return AppColors.warningLight;
      case BackendStatus.unresponsive:
      case BackendStatus.error:
        return AppColors.errorLight;
      case BackendStatus.stopped:
        return Colors.grey;
    }
  }
}

/// 상태 배너 (화면 상단에 표시)
class HealthBanner extends ConsumerWidget {
  const HealthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendManager = ref.watch(backendManagerProvider);
    final status = backendManager.currentStatus;

    // 정상 상태면 표시하지 않음
    if (status == BackendStatus.running || status == BackendStatus.stopped) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<BackendHealth>(
      stream: backendManager.healthStream,
      builder: (context, snapshot) {
        final health = snapshot.data;
        if (health == null) return const SizedBox.shrink();

        return _buildBanner(context, health);
      },
    );
  }

  Widget _buildBanner(BuildContext context, BackendHealth health) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    switch (health.status) {
      case BackendStatus.starting:
        backgroundColor = AppColors.warningLight.withOpacity(0.1);
        textColor = AppColors.warningLight;
        icon = Icons.hourglass_bottom;
        message = '백엔드 시작 중...';
        break;
      case BackendStatus.restarting:
        backgroundColor = AppColors.warningLight.withOpacity(0.1);
        textColor = AppColors.warningLight;
        icon = Icons.restart_alt;
        message = '백엔드 재시작 중...';
        break;
      case BackendStatus.unresponsive:
        backgroundColor = AppColors.errorLight.withOpacity(0.1);
        textColor = AppColors.errorLight;
        icon = Icons.warning_amber;
        message = '백엔드 응답 없음 (${health.consecutiveFailures}회 실패)';
        break;
      case BackendStatus.error:
        backgroundColor = AppColors.errorLight.withOpacity(0.1);
        textColor = AppColors.errorLight;
        icon = Icons.error_outline;
        message = health.errorMessage ?? '백엔드 오류';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
