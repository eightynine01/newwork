import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/plugin.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../data/providers/dashboard_providers.dart';
import '../widgets/add_plugin_dialog.dart';

class PluginsTab extends ConsumerWidget {
  const PluginsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginsState = ref.watch(pluginsProvider);
    final plugins = pluginsState.filteredPlugins;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugins'),
        actions: [
          // Scope filter
          PopupMenuButton<bool>(
            icon: Icon(
              pluginsState.showProjectOnly
                  ? Icons.workspaces_outline
                  : Icons.public,
            ),
            tooltip: 'Filter by scope',
            onSelected: (projectOnly) {
              ref.read(pluginsProvider.notifier).setScopeFilter(projectOnly);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: false,
                child: Row(
                  children: [
                    Icon(Icons.public, size: 18),
                    SizedBox(width: 12),
                    Text('All Plugins'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: true,
                child: Row(
                  children: [
                    Icon(Icons.workspaces_outline, size: 18),
                    SizedBox(width: 12),
                    Text('Project Only'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(pluginsProvider.notifier).loadPlugins();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(pluginsProvider.notifier).loadPlugins();
        },
        child: pluginsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : pluginsState.error != null
                ? _buildErrorState(context, pluginsState.error!, ref)
                : plugins.isEmpty
                    ? _buildEmptyState(context, ref)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: plugins.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child:
                                _buildPluginCard(context, plugins[index], ref),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPluginDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Plugin'),
      ),
    );
  }

  Widget _buildPluginCard(BuildContext context, Plugin plugin, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: plugin.isEnabled
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.apps,
                  color: plugin.isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plugin.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: plugin.scope == PluginScope.project
                                ? Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.1)
                                : Theme.of(
                                    context,
                                  ).colorScheme.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                plugin.scope == PluginScope.project
                                    ? Icons.workspaces_outline
                                    : Icons.public,
                                size: 12,
                                color: plugin.scope == PluginScope.project
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                plugin.scope.name.capitalize(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: plugin.scope == PluginScope.project
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: plugin.isEnabled,
                onChanged: (value) async {
                  await ref
                      .read(pluginsProvider.notifier)
                      .togglePlugin(plugin.id, value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${plugin.name} ${value ? "enabled" : "disabled"}',
                        ),
                      ),
                    );
                  }
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    _showRemoveDialog(context, ref, plugin);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Remove', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (plugin.description != null)
            Text(
              plugin.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (plugin.config != null && plugin.config!.isNotEmpty)
            ExpansionTile(
              title: Text(
                'Configuration',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              tilePadding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: plugin.config!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
              Icons.apps_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No plugins configured',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add plugins to extend OpenCode functionality',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Add Plugin',
              icon: const Icon(Icons.add),
              onPressed: () => _showAddPluginDialog(context),
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
              'Failed to load plugins',
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
                await ref.read(pluginsProvider.notifier).loadPlugins();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPluginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddPluginDialog(),
    );
  }

  void _showRemoveDialog(BuildContext context, WidgetRef ref, Plugin plugin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Plugin'),
        content: Text(
          'Are you sure you want to remove "${plugin.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(pluginsProvider.notifier).removePlugin(plugin.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Plugin removed')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}
