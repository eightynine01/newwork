import 'package:flutter/material.dart';
import '../../../data/models/workspace.dart';

class WorkspaceCard extends StatelessWidget {
  final Workspace workspace;
  final bool isActive;
  final VoidCallback? onSelect;
  final VoidCallback? onDelete;
  final VoidCallback? onAuthorize;

  const WorkspaceCard({
    super.key,
    required this.workspace,
    required this.isActive,
    this.onSelect,
    this.onDelete,
    this.onAuthorize,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isActive ? 2 : 1,
      color: isActive
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 20,
                              color: isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                workspace.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer
                                          : null,
                                    ),
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Active',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          workspace.path,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isActive
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withOpacity(0.8)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (workspace.description != null &&
                      workspace.description!.isNotEmpty)
                    Expanded(
                      child: Text(
                        workspace.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isActive
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withOpacity(0.7)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  _buildActionButton(
                    context,
                    'Switch',
                    Icons.swap_horiz,
                    onSelect,
                    isActive: false,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    'Authorize',
                    Icons.lock_open,
                    onAuthorize,
                    isActive: false,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    'Delete',
                    Icons.delete_outline,
                    onDelete,
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback? onPressed, {
    bool isActive = false,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDestructive
                    ? Theme.of(context).colorScheme.error.withOpacity(0.3)
                    : isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isDestructive
                      ? Theme.of(context).colorScheme.error
                      : isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDestructive
                            ? Theme.of(context).colorScheme.error
                            : isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
