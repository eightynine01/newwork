import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/template.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../data/providers/dashboard_providers.dart';
import '../widgets/template_dialog.dart';
import '../widgets/run_template_dialog.dart';

class TemplatesTab extends ConsumerWidget {
  const TemplatesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesState = ref.watch(templatesProvider);
    final templates = templatesState.filteredTemplates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
        actions: [
          // Scope filter
          PopupMenuButton<bool>(
            icon: Icon(
              templatesState.showWorkspaceOnly
                  ? Icons.workspaces_outline
                  : Icons.public,
            ),
            tooltip: 'Filter by scope',
            onSelected: (workspaceOnly) {
              ref
                  .read(templatesProvider.notifier)
                  .setScopeFilter(workspaceOnly);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(Icons.public, size: 18),
                    SizedBox(width: 12),
                    Text('All Templates'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(Icons.workspaces_outline, size: 18),
                    SizedBox(width: 12),
                    Text('Workspace Only'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(templatesProvider.notifier).loadTemplates();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Templates refreshed')),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(templatesProvider.notifier).loadTemplates();
        },
        child: templatesState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : templatesState.error != null
                ? _buildErrorState(context, templatesState.error!, ref)
                : templates.isEmpty
                    ? _buildEmptyState(context, ref)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildTemplateCard(
                                context, templates[index], ref),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTemplateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    Template template,
    WidgetRef ref,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final createdAt = template.createdAt;

    return AppCard(
      onTap: () {
        _showRunTemplateDialog(context, ref, template);
      },
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
                        Text(
                          template.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        if (template.isPublic)
                          Icon(
                            Icons.public,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        else
                          Icon(
                            Icons.workspaces_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                      ],
                    ),
                    if (template.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        template.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditTemplateDialog(context, ref, template);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, ref, template);
                  } else if (value == 'run') {
                    _showRunTemplateDialog(context, ref, template);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'run',
                    child: Row(
                      children: [
                        Icon(Icons.play_arrow, size: 18),
                        SizedBox(width: 12),
                        Text('Run Template'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Skills
              if (template.skills.isNotEmpty)
                ...template.skills.take(3).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              // Usage count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${template.usageCount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Date
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dateFormat.format(createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No templates yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create templates to save and reuse common prompts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Create Template',
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateTemplateDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load templates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Retry',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await ref.read(templatesProvider.notifier).loadTemplates();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) =>
          const TemplateDialog(mode: TemplateDialogMode.create),
    );
  }

  void _showEditTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    Template template,
  ) {
    showDialog(
      context: context,
      builder: (context) => TemplateDialog(
        mode: TemplateDialogMode.edit,
        template: template,
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Template template,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete "${template.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(templatesProvider.notifier)
                  .deleteTemplate(template.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Template deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRunTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    Template template,
  ) {
    showDialog(
      context: context,
      builder: (context) => RunTemplateDialog(template: template),
    );
  }
}
