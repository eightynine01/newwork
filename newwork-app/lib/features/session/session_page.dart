import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/message.dart';
import '../../../data/models/ai_provider.dart';
import '../session/providers/session_provider.dart';
import '../session/widgets/message_bubble.dart';
import '../session/widgets/todo_timeline.dart';
import '../session/widgets/permission_dialog.dart';
import '../session/widgets/artifact_card.dart';
import '../session/widgets/prompt_input.dart';
import '../session/widgets/export_dialog.dart';
import '../session/widgets/download_progress_dialog.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/app_card.dart';
import '../../features/settings/widgets/model_picker_dialog.dart';
import '../../data/providers/dashboard_providers.dart' hide apiClientProvider;
import '../../services/file_download_service.dart';
import '../../services/export_service.dart';

class SessionPage extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionPage({super.key, required this.sessionId});

  @override
  ConsumerState<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends ConsumerState<SessionPage> {
  late final ScrollController _scrollController;
  late final PromptInputController _promptController;
  final List<Tab> _tabs = [
    Tab(text: 'Chat', icon: Icon(Icons.chat_bubble_outline)),
    Tab(text: 'Progress', icon: Icon(Icons.timeline)),
    Tab(text: 'Files', icon: Icon(Icons.folder_open)),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _promptController = PromptInputController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionProvider(widget.sessionId));
    final isLoading = sessionState.isLoading;
    final error = sessionState.error;

    // Auto-scroll to bottom when new messages arrive
    ref.listen<List<Message>>(
      sessionMessagesProvider(widget.sessionId),
      (previous, next) {
        if (previous != null && next.length > previous.length) {
          // Only scroll if user hasn't manually scrolled up
          final position = _scrollController.position;
          final isAtBottom = position.maxScrollExtent - position.pixels < 100;

          if (isAtBottom) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      },
    );

    return Scaffold(
      appBar: _buildAppBar(context, sessionState),
      body: Column(
        children: [
          Expanded(child: _buildBody(context, sessionState)),
          _buildBottomInput(context, sessionState),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, dynamic sessionState) {
    final theme = Theme.of(context);
    final session = sessionState is SessionState
        ? (sessionState as SessionState).session
        : null;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session?.title ?? 'Loading...',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (session != null) ...[
            const SizedBox(height: 2),
            Text(
              'Created ${_formatDate(session!.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref
              .read(sessionProvider(widget.sessionId).notifier)
              .loadSession(widget.sessionId),
          tooltip: 'Refresh',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'export':
                _showExportDialog(context, session?.title ?? 'Session');
                break;
              case 'share':
                _shareSession(context, session?.title ?? 'Session');
                break;
              case 'delete':
                _confirmDeleteSession(context);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 12),
                  Text('Export'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: TabBar(tabs: _tabs),
    );
  }

  Widget _buildBody(BuildContext context, dynamic sessionState) {
    final actualState = sessionState as SessionState?;

    if (actualState?.isLoading == true) {
      return const Center(child: LoadingIndicator());
    }

    if (actualState?.error != null) {
      return _buildError(context, actualState!.error!);
    }

    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          Expanded(
            child: TabBarView(
              children: [
                _buildChatTab(context, actualState),
                _buildProgressTab(context, actualState),
                _buildFilesTab(context, actualState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading session',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(sessionProvider(widget.sessionId).notifier).clearError();
                ref
                    .read(sessionProvider(widget.sessionId).notifier)
                    .loadSession(widget.sessionId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab(BuildContext context, SessionState? sessionState) {
    final messages = sessionState?.messages ?? [];

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by typing a prompt below',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(message: message);
      },
    );
  }

  Widget _buildProgressTab(BuildContext context, SessionState? sessionState) {
    final todos = sessionState?.todos ?? [];
    final expandedTodos = sessionState?.expandedTodos ?? {};

    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TodoTimeline(
          todos: todos,
          expandedTodos: expandedTodos,
          onToggleExpand: (todoId) {
            final notifier = ref.read(sessionProvider(widget.sessionId).notifier);
            if (expandedTodos.contains(todoId)) {
              notifier.collapseTodo(todoId);
            } else {
              notifier.expandTodo(todoId);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFilesTab(BuildContext context, SessionState? sessionState) {
    final artifacts = sessionState?.artifacts ?? [];

    if (artifacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No files created yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: artifacts.length,
      itemBuilder: (context, index) {
        final artifact = artifacts[index];
        final path = artifact['path'] as String? ?? '';
        final name = artifact['name'] as String? ?? 'file';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ArtifactCard(
            artifact: artifact,
            onOpen: () => _openArtifact(context, path, name),
            onDownload: () => _downloadArtifact(context, path, name),
            onCopy: () => _copyArtifactContent(context, path),
          ),
        );
      },
    );
  }

  Future<void> _openArtifact(BuildContext context, String path, String name) async {
    final workspaceState = ref.read(workspaceProvider);
    final workspaceId = workspaceState.activeWorkspace?.id;

    if (workspaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active workspace')),
      );
      return;
    }

    final downloadService = FileDownloadService();
    try {
      final success = await downloadService.downloadAndOpenFile(
        workspaceId: workspaceId,
        path: path,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    } finally {
      downloadService.dispose();
    }
  }

  Future<void> _downloadArtifact(BuildContext context, String path, String name) async {
    final workspaceState = ref.read(workspaceProvider);
    final workspaceId = workspaceState.activeWorkspace?.id;

    if (workspaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active workspace')),
      );
      return;
    }

    final downloadService = FileDownloadService();

    final result = await DownloadProgressDialog.show(
      context: context,
      fileName: name,
      downloadTask: (onProgress) => downloadService.downloadFile(
        workspaceId: workspaceId,
        path: path,
        onProgress: onProgress,
      ),
    );

    downloadService.dispose();

    if (result != null && mounted) {
      showDownloadSnackbar(
        context: context,
        fileName: name,
        success: true,
        filePath: result,
        onOpen: () => FileDownloadService().openFile(result),
        onReveal: () => FileDownloadService().revealInFinder(result),
      );
    }
  }

  Future<void> _copyArtifactContent(BuildContext context, String path) async {
    final workspaceState = ref.read(workspaceProvider);
    final workspaceId = workspaceState.activeWorkspace?.id;

    if (workspaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active workspace')),
      );
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final content = await apiClient.getFileContent(
        workspaceId: workspaceId,
        path: path,
      );

      await Clipboard.setData(ClipboardData(text: content.content));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error copying content: $e')),
        );
      }
    }
  }

  Widget _buildBottomInput(BuildContext context, SessionState sessionState) {
    final isSending = sessionState.isSending;
    final pendingPermission = sessionState.pendingPermission;
    final settings = ref.watch(settingsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pendingPermission != null)
          _buildPermissionBanner(context, sessionState),
        Row(
          children: [
            Expanded(
              child: PromptInput(
                model: settings.defaultModelName ?? 'gpt-4',
                availableModels: ref
                    .read(providersProvider)
                    .models
                    .map((m) => m.id)
                    .toList(),
                onTextChanged: (text) {
                  // Handle text changes if needed
                },
                onSend: _sendMessage,
                isSending: isSending,
                maxLength: 4000,
                hintText: 'Ask OpenCode to help with your project',
              ),
            ),
            const SizedBox(width: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  _showModelSelectorDialog(context);
                },
                tooltip: 'Change model for this session',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionBanner(
    BuildContext context,
    SessionState sessionState,
  ) {
    final permission = sessionState.pendingPermission;
    if (permission == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              Icons.security,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permission Request',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                  ),
                  Text(
                    permission!.toolName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                showPermissionDialog(
                  context: context,
                  permission: permission!,
                ).then((response) {
                  if (response != null) {
                    ref
                        .read(sessionProvider(widget.sessionId).notifier)
                        .respondPermission(permission!.id, response.name);
                  }
                });
              },
              child: const Text('Review'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    final settings = ref.read(settingsProvider);
    final modelId = settings.defaultModelId ?? 'gpt-4';

    ref
        .read(sessionProvider(widget.sessionId).notifier)
        .sendPrompt(widget.sessionId, modelId, prompt);

    _promptController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showModelSelectorDialog(BuildContext context) {
    final settings = ref.read(settingsProvider);

    showDialog(
      context: context,
      builder: (context) => ModelPickerDialog(
        currentModelId: settings.defaultModelId,
        showSetAsDefaultButton: false,
      ),
    ).then((selectedModelId) {
      if (selectedModelId != null) {
        // For session-level override, you would call an API to set the model
        // For now, just update the default model
        final selectedModel = ref.read(providersProvider).models.firstWhere(
              (m) => m.id == selectedModelId,
              orElse: () => AIModel(
                id: '',
                name: '',
                providerId: '',
                providerName: '',
              ),
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Model changed to ${selectedModel.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
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

  void _showExportDialog(BuildContext context, String sessionTitle) {
    ExportDialog.show(
      context: context,
      sessionId: widget.sessionId,
      sessionTitle: sessionTitle,
    );
  }

  Future<void> _shareSession(BuildContext context, String sessionTitle) async {
    final exportService = ExportService();

    try {
      await exportService.shareSession(
        sessionId: widget.sessionId,
        format: ExportFormat.markdown,
        title: sessionTitle,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      exportService.dispose();
    }
  }

  void _confirmDeleteSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: const Text(
          'Are you sure you want to delete this session? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSession();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession() async {
    try {
      await ref.read(sessionsProvider.notifier).deleteSession(widget.sessionId);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete session: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// Controller for PromptInput
class PromptInputController {
  String text = '';

  void clear() {
    text = '';
  }

  void dispose() {
    // Cleanup resources if needed
  }
}
