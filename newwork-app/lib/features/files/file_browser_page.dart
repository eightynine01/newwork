import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/file_item.dart';
import '../../data/providers/dashboard_providers.dart';
import '../../shared/widgets/app_card.dart';

class FileBrowserPage extends ConsumerStatefulWidget {
  const FileBrowserPage({super.key});

  @override
  ConsumerState<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends ConsumerState<FileBrowserPage> {
  String _currentPath = '.';
  FileItem? _selectedFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workspaceState = ref.watch(workspaceProvider);
    final activeWorkspace = workspaceState.activeWorkspace;

    if (activeWorkspace == null) {
      return _buildNoWorkspace(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Refresh files
            },
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            tooltip: 'New Folder',
            onPressed: () {
              // TODO: Create folder dialog
            },
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            tooltip: 'New File',
            onPressed: () {
              // TODO: Create file dialog
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // File tree (left sidebar)
          SizedBox(
            width: 300,
            child: _buildFileTree(context, activeWorkspace.id),
          ),
          const VerticalDivider(width: 1),
          // File content (main area)
          Expanded(
            child: _selectedFile != null
                ? _buildFileContent(context, activeWorkspace.id)
                : _buildEmptyState(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWorkspace(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No workspace active',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a workspace to browse files',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTree(BuildContext context, String workspaceId) {
    // TODO: Implement file tree with FutureProvider
    // For now, show a placeholder
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBreadcrumb(context),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('src'),
                onTap: () {
                  setState(() {
                    _currentPath = 'src';
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('lib'),
                onTap: () {
                  setState(() {
                    _currentPath = 'lib';
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('README.md'),
                onTap: () {
                  setState(() {
                    _selectedFile = FileItem(
                      path: 'README.md',
                      name: 'README.md',
                      type: 'file',
                      isFile: true,
                      isDir: false,
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    final parts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();

    return Wrap(
      spacing: 4,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.home, size: 16),
          label: const Text('Root'),
          onPressed: () {
            setState(() {
              _currentPath = '.';
            });
          },
        ),
        for (int i = 0; i < parts.length; i++) ...[
          const Icon(Icons.chevron_right, size: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _currentPath = parts.sublist(0, i + 1).join('/');
              });
            },
            child: Text(parts[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildFileContent(BuildContext context, String workspaceId) {
    if (_selectedFile == null || _selectedFile!.isDirectory) {
      return _buildEmptyState(context);
    }

    // TODO: Load file content from API
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.description,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          _selectedFile!.path,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // TODO: Edit file
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      // TODO: Save file
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // File content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'TODO: Load file content from API\nFile: ${_selectedFile!.path}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Select a file to view',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
