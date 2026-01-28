import 'package:flutter/material.dart';
import '../../../data/models/artifact.dart';
import '../../../shared/widgets/app_button.dart';

class ArtifactCard extends StatelessWidget {
  final Map<String, dynamic> artifact;
  final VoidCallback? onOpen;
  final VoidCallback? onDownload;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;

  const ArtifactCard({
    super.key,
    required this.artifact,
    this.onOpen,
    this.onDownload,
    this.onCopy,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = artifact['name'] as String? ?? 'Unknown';
    final path = artifact['path'] as String? ?? '';
    final size = artifact['size'] as int? ?? 0;
    final typeStr = artifact['type'] as String? ?? 'file';
    final type = _parseArtifactType(typeStr);
    final createdAt = artifact['created_at'] != null
        ? DateTime.parse(artifact['created_at'] as String)
        : DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme, type, name),
          const SizedBox(height: 12),
          _buildDetails(context, theme, path, size, createdAt),
          const SizedBox(height: 12),
          _buildActions(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ArtifactType type,
    String name,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getTypeColor(theme, type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTypeIcon(type),
            color: _getTypeColor(theme, type),
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getTypeLabel(type),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(
    BuildContext context,
    ThemeData theme,
    String path,
    int size,
    DateTime createdAt,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(context, theme, Icons.folder_open, 'Path', path),
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            theme,
            Icons.storage,
            'Size',
            _formatSize(size),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            context,
            theme,
            Icons.schedule,
            'Created',
            _formatTime(createdAt),
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
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
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
              const SizedBox(height: 1),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
            text: 'Open',
            variant: AppButtonVariant.primary,
            icon: const Icon(Icons.open_in_new, size: 18),
            onPressed: onOpen,
            isFullWidth: true,
          ),
        ),
        const SizedBox(width: 8),
        AppButton(
          text: 'Copy',
          variant: AppButtonVariant.text,
          icon: const Icon(Icons.copy, size: 18),
          onPressed: onCopy,
        ),
        const SizedBox(width: 8),
        AppButton(
          text: 'Download',
          variant: AppButtonVariant.text,
          icon: const Icon(Icons.download, size: 18),
          onPressed: onDownload,
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          AppButton(
            text: 'Delete',
            variant: AppButtonVariant.text,
            icon: const Icon(Icons.delete, size: 18),
            onPressed: onDelete,
          ),
        ],
      ],
    );
  }

  ArtifactType _parseArtifactType(String typeStr) {
    try {
      return ArtifactType.values.firstWhere(
        (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
        orElse: () => ArtifactType.file,
      );
    } catch (e) {
      return ArtifactType.file;
    }
  }

  IconData _getTypeIcon(ArtifactType type) {
    switch (type) {
      case ArtifactType.file:
        return Icons.insert_drive_file;
      case ArtifactType.text:
        return Icons.description;
      case ArtifactType.image:
        return Icons.image;
      case ArtifactType.code:
        return Icons.code;
    }
  }

  Color _getTypeColor(ThemeData theme, ArtifactType type) {
    switch (type) {
      case ArtifactType.file:
        return theme.colorScheme.outline;
      case ArtifactType.text:
        return theme.colorScheme.tertiary;
      case ArtifactType.image:
        return theme.colorScheme.primary;
      case ArtifactType.code:
        return theme.colorScheme.secondary;
    }
  }

  String _getTypeLabel(ArtifactType type) {
    switch (type) {
      case ArtifactType.file:
        return 'File';
      case ArtifactType.text:
        return 'Text Document';
      case ArtifactType.image:
        return 'Image';
      case ArtifactType.code:
        return 'Code File';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
