import 'package:flutter/material.dart';
import '../../../data/models/todo.dart';

class TodoTimeline extends StatelessWidget {
  final List<Todo> todos;
  final Set<String> expandedTodos;
  final Function(String) onToggleExpand;

  const TodoTimeline({
    super.key,
    required this.todos,
    required this.expandedTodos,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (todos.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    final sortedTodos = List<Todo>.from(todos);
    sortedTodos.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildProgressIndicator(context, theme),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeline(context, theme, sortedTodos),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No tasks yet',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ThemeData theme) {
    final completedCount = todos
        .where((t) => t.status == TodoStatus.completed)
        .length;
    final totalCount = todos.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$completedCount/$totalCount',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 50,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.secondaryContainer
                    .withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    ThemeData theme,
    List<Todo> sortedTodos,
  ) {
    return Column(
      children: [
        for (int i = 0; i < sortedTodos.length; i++)
          _buildTodoItem(
            context,
            theme,
            sortedTodos[i],
            i < sortedTodos.length - 1,
          ),
      ],
    );
  }

  Widget _buildTodoItem(
    BuildContext context,
    ThemeData theme,
    Todo todo,
    bool hasLine,
  ) {
    final isExpanded = expandedTodos.contains(todo.id);
    final statusColor = _getStatusColor(theme, todo.status);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineLine(context, theme, hasLine, statusColor, todo.status),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTodoCard(
              context,
              theme,
              todo,
              isExpanded,
              statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(
    BuildContext context,
    ThemeData theme,
    bool hasLine,
    Color statusColor,
    TodoStatus status,
  ) {
    return SizedBox(
      width: 24,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.surface, width: 2),
            ),
            child: Icon(
              _getStatusIcon(status),
              size: 14,
              color: theme.colorScheme.surface,
            ),
          ),
          if (hasLine)
            Expanded(
              child: Container(
                width: 2,
                color: theme.colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodoCard(
    BuildContext context,
    ThemeData theme,
    Todo todo,
    bool isExpanded,
    Color statusColor,
  ) {
    final hasDescription =
        todo.description != null && todo.description!.isNotEmpty;

    return GestureDetector(
      onTap: hasDescription ? () => onToggleExpand(todo.id) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPriorityBadge(context, theme, todo.priority),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    todo.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasDescription)
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (isExpanded && hasDescription) ...[
              const SizedBox(height: 8),
              Text(
                todo.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(context, theme, todo.status),
                const Spacer(),
                Text(
                  _formatTime(todo.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(
    BuildContext context,
    ThemeData theme,
    TodoPriority priority,
  ) {
    String label;
    Color color;

    switch (priority) {
      case TodoPriority.high:
        label = 'HIGH';
        color = theme.colorScheme.error;
        break;
      case TodoPriority.medium:
        label = 'MED';
        color = theme.colorScheme.tertiary;
        break;
      case TodoPriority.low:
        label = 'LOW';
        color = theme.colorScheme.outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context,
    ThemeData theme,
    TodoStatus status,
  ) {
    String label;
    Color color;
    IconData icon;

    switch (status) {
      case TodoStatus.pending:
        label = 'Pending';
        color = theme.colorScheme.outline;
        icon = Icons.pending_outlined;
        break;
      case TodoStatus.inProgress:
        label = 'In Progress';
        color = theme.colorScheme.primary;
        icon = Icons.play_circle_outline;
        break;
      case TodoStatus.completed:
        label = 'Completed';
        color = theme.colorScheme.primary;
        icon = Icons.check_circle_outline;
        break;
      case TodoStatus.cancelled:
        label = 'Cancelled';
        color = theme.colorScheme.error;
        icon = Icons.cancel_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, TodoStatus status) {
    switch (status) {
      case TodoStatus.pending:
        return theme.colorScheme.outline;
      case TodoStatus.inProgress:
        return theme.colorScheme.primary;
      case TodoStatus.completed:
        return theme.colorScheme.primary;
      case TodoStatus.cancelled:
        return theme.colorScheme.error;
    }
  }

  IconData _getStatusIcon(TodoStatus status) {
    switch (status) {
      case TodoStatus.pending:
        return Icons.radio_button_unchecked;
      case TodoStatus.inProgress:
        return Icons.play_arrow;
      case TodoStatus.completed:
        return Icons.check;
      case TodoStatus.cancelled:
        return Icons.close;
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
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
