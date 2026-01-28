import 'package:flutter/material.dart';
import '../../../data/models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onTap;

  const MessageBubble({super.key, required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

    if (isSystem) {
      return _buildSystemMessage(context, theme);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildAvatar(context), const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildBubble(context, theme),
                const SizedBox(height: 4),
                _buildMetaInfo(context, theme),
              ],
            ),
          ),
          if (isUser) ...[const SizedBox(width: 12), _buildAvatar(context)],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return CircleAvatar(
      radius: 20,
      backgroundColor: isUser
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: isUser
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                message.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, ThemeData theme) {
    final isUser = message.role == MessageRole.user;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBubbleColor(context, theme),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.type == MessageType.error
                ? theme.colorScheme.error
                : Colors.transparent,
            width: message.type == MessageType.error ? 2 : 0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContent(context, theme),
            if (message.toolName != null) ...[
              const SizedBox(height: 8),
              _buildToolInfo(context, theme),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBubbleColor(BuildContext context, ThemeData theme) {
    final isUser = message.role == MessageRole.user;

    switch (message.type) {
      case MessageType.error:
        return theme.colorScheme.errorContainer;
      case MessageType.thinking:
        return theme.colorScheme.tertiaryContainer;
      case MessageType.toolCall:
      case MessageType.toolResult:
        return theme.colorScheme.tertiaryContainer.withOpacity(0.5);
      default:
        return isUser
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest;
    }
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    final content = message.content;

    if (message.type == MessageType.code ||
        (content.contains('```') && content.contains('```'))) {
      return _buildCodeBlock(context, theme, content);
    }

    return SelectableText(
      content,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: _getTextColor(context, theme),
      ),
    );
  }

  Widget _buildCodeBlock(
    BuildContext context,
    ThemeData theme,
    String content,
  ) {
    final language = _extractLanguage(content);
    final codeContent = _extractCode(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.contains('```'))
          _buildMarkdownText(context, theme, content),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (language != null) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        language,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              SelectableText(
                codeContent,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarkdownText(
    BuildContext context,
    ThemeData theme,
    String content,
  ) {
    final textBeforeCode = content.split('```').first.trim();
    if (textBeforeCode.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SelectableText(
        textBeforeCode,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: _getTextColor(context, theme),
        ),
      ),
    );
  }

  String? _extractLanguage(String content) {
    final regex = RegExp(r'```(\w+)?');
    final match = regex.firstMatch(content);
    return match?.group(1)?.toLowerCase();
  }

  String _extractCode(String content) {
    final parts = content.split('```');
    if (parts.length >= 2) {
      return parts[1].trim();
    }
    return content;
  }

  Widget _buildToolInfo(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getToolIcon(message.toolName),
            size: 16,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message.toolName ?? 'Tool',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getToolIcon(String? toolName) {
    if (toolName == null) return Icons.build;
    final name = toolName.toLowerCase();
    if (name.contains('read') || name.contains('get')) return Icons.article;
    if (name.contains('write') || name.contains('create')) return Icons.edit;
    if (name.contains('bash') || name.contains('run')) return Icons.terminal;
    if (name.contains('search') || name.contains('find')) return Icons.search;
    if (name.contains('web') || name.contains('fetch')) return Icons.language;
    return Icons.build;
  }

  Widget _buildMetaInfo(BuildContext context, ThemeData theme) {
    final timeString = _formatTime(message.createdAt);

    return Padding(
      padding: EdgeInsets.only(left: message.role == MessageRole.user ? 0 : 44),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.role == MessageRole.assistant) ...[
            Icon(
              Icons.access_time,
              size: 12,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            timeString,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          if (message.role == MessageRole.assistant) ...[
            const SizedBox(width: 8),
            _buildTypeBadge(context, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, ThemeData theme) {
    String label;
    Color color;

    switch (message.type) {
      case MessageType.thinking:
        label = 'Thinking';
        color = theme.colorScheme.tertiary;
        break;
      case MessageType.toolCall:
        label = 'Tool Call';
        color = theme.colorScheme.primary;
        break;
      case MessageType.toolResult:
        label = 'Tool Result';
        color = theme.colorScheme.secondary;
        break;
      case MessageType.error:
        label = 'Error';
        color = theme.colorScheme.error;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getTextColor(BuildContext context, ThemeData theme) {
    return message.type == MessageType.error
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSurface;
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
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
