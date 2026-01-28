import 'package:flutter/material.dart';
import '../../../data/models/permission.dart';
import '../../../shared/widgets/app_button.dart';

class PermissionDialog extends StatelessWidget {
  final Permission permission;
  final VoidCallback onAllowOnce;
  final VoidCallback onAlwaysAllow;
  final VoidCallback onDeny;

  const PermissionDialog({
    super.key,
    required this.permission,
    required this.onAllowOnce,
    required this.onAlwaysAllow,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: 16),
              _buildSecurityWarning(context, theme),
              const SizedBox(height: 20),
              _buildPermissionDetails(context, theme),
              const SizedBox(height: 24),
              _buildActions(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.security,
            color: theme.colorScheme.onTertiaryContainer,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permission Request',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'OpenCode needs your approval',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityWarning(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Review this request carefully. Only approve if you trust the operation being performed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDetails(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            context,
            theme,
            Icons.build,
            'Tool/Operation',
            permission.toolName,
          ),
          if (permission.description != null &&
              permission.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              theme,
              Icons.description,
              'Description',
              permission.description!,
            ),
          ],
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            theme,
            Icons.link,
            'Session ID',
            permission.sessionId,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            theme,
            Icons.schedule,
            'Requested At',
            _formatTime(permission.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Deny',
            variant: AppButtonVariant.danger,
            onPressed: onDeny,
            isFullWidth: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            text: 'Allow Once',
            variant: AppButtonVariant.primary,
            onPressed: onAllowOnce,
            isFullWidth: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            text: 'Always Allow',
            variant: AppButtonVariant.secondary,
            onPressed: onAlwaysAllow,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Show permission dialog
Future<PermissionResponse?> showPermissionDialog({
  required BuildContext context,
  required Permission permission,
}) {
  return showDialog<PermissionResponse>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PermissionDialog(
      permission: permission,
      onAllowOnce: () => Navigator.pop(context, PermissionResponse.allowOnce),
      onAlwaysAllow: () =>
          Navigator.pop(context, PermissionResponse.alwaysAllow),
      onDeny: () => Navigator.pop(context, PermissionResponse.deny),
    ),
  );
}

enum PermissionResponse { allowOnce, alwaysAllow, deny }
