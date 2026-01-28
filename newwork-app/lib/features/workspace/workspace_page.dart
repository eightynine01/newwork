import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/workspace.dart';
import '../../data/providers/dashboard_providers.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import 'widgets/workspace_card.dart';
import 'widgets/workspace_picker_dialog.dart';
import 'widgets/authorize_dialog.dart';

class WorkspacePage extends ConsumerStatefulWidget {
  const WorkspacePage({super.key});

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(workspaceProvider.notifier).loadWorkspaces(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(workspaceProvider.notifier).loadWorkspaces(),
        child: workspaceState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : workspaceState.error != null
                ? _buildErrorView(context, workspaceState.error!)
                : workspaceState.workspaces.isEmpty
                    ? _buildEmptyView(context)
                    : _buildWorkspaceList(context, workspaceState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWorkspaceDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Workspace'),
      ),
    );
  }

  Widget _buildWorkspaceList(
    BuildContext context,
    WorkspaceState state,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.workspaces.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildActiveWorkspaceSection(context, state),
          );
        }
        final workspace = state.workspaces[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WorkspaceCard(
            workspace: workspace,
            isActive: state.activeWorkspace?.id == workspace.id,
            onSelect: () => _selectWorkspace(context, workspace.id),
            onDelete: () => _showDeleteConfirmDialog(context, workspace),
            onAuthorize: () => _showAuthorizeDialog(context, workspace.path),
          ),
        );
      },
    );
  }

  Widget _buildActiveWorkspaceSection(
    BuildContext context,
    WorkspaceState state,
  ) {
    if (state.activeWorkspace == null) {
      return AppCard(
        variant: AppCardVariant.outlined,
        child: Column(
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No active workspace',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a workspace to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      variant: AppCardVariant.filled,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Active Workspace',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.activeWorkspace!.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.activeWorkspace!.path,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withOpacity(0.8),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AppButton(
                text: 'Switch',
                variant: AppButtonVariant.text,
                onPressed: () => _showWorkspacePickerDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.create_new_folder_outlined,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No workspaces yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first workspace to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Create Workspace',
            icon: const Icon(Icons.add),
            variant: AppButtonVariant.primary,
            onPressed: () => _showCreateWorkspaceDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading workspaces',
              style: Theme.of(context).textTheme.titleLarge,
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
              onPressed: () =>
                  ref.read(workspaceProvider.notifier).loadWorkspaces(),
            ),
          ],
        ),
      ),
    );
  }

  void _selectWorkspace(BuildContext context, String workspaceId) {
    ref.read(workspaceProvider.notifier).setActiveWorkspace(workspaceId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Workspace activated')),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Workspace workspace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workspace?'),
        content: Text(
          'Are you sure you want to delete "${workspace.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(workspaceProvider.notifier)
                  .deleteWorkspace(workspace.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Workspace deleted')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateWorkspaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WorkspacePickerDialog(),
    );
  }

  void _showWorkspacePickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Workspace'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(
            builder: (context, ref, child) {
              final workspaceState = ref.watch(workspaceProvider);
              return ListView.builder(
                shrinkWrap: true,
                itemCount: workspaceState.workspaces.length,
                itemBuilder: (context, index) {
                  final workspace = workspaceState.workspaces[index];
                  final isActive =
                      workspaceState.activeWorkspace?.id == workspace.id;
                  return ListTile(
                    title: Text(workspace.name),
                    subtitle: Text(
                      workspace.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isActive
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      ref
                          .read(workspaceProvider.notifier)
                          .setActiveWorkspace(workspace.id);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAuthorizeDialog(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => AuthorizeDialog(path: path),
    );
  }
}
