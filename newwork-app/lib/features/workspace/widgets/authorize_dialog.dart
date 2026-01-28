import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/dashboard_providers.dart';
import '../../../shared/widgets/app_button.dart';

class AuthorizeDialog extends ConsumerStatefulWidget {
  final String path;

  const AuthorizeDialog({
    super.key,
    required this.path,
  });

  @override
  ConsumerState<AuthorizeDialog> createState() => _AuthorizeDialogState();
}

class _AuthorizeDialogState extends ConsumerState<AuthorizeDialog> {
  bool _isAuthorizing = false;
  bool _isAuthorized = false;
  String? _message;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthorizationStatus();
  }

  Future<void> _checkAuthorizationStatus() async {
    final workspaceState = ref.read(workspaceProvider);
    final isAuthorized =
        workspaceState.workspaces.any((w) => w.path == widget.path);
    if (mounted) {
      setState(() {
        _isAuthorized = isAuthorized;
        if (isAuthorized) {
          _message = 'This directory is already authorized as a workspace.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isAuthorized ? Icons.check_circle : Icons.security,
            color: _isAuthorized
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Authorize Directory'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Directory Path',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.path,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What does authorization do?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ..._buildPermissionItems(context),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton(
          text: 'Cancel',
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        if (!_isAuthorized) ...[
          const SizedBox(width: 8),
          AppButton(
            text: 'Authorize',
            icon: const Icon(Icons.lock_open),
            variant: AppButtonVariant.primary,
            isLoading: _isAuthorizing,
            onPressed: _isAuthorizing ? null : _authorize,
          ),
        ],
      ],
    );
  }

  List<Widget> _buildPermissionItems(BuildContext context) {
    return [
      _buildPermissionItem(
        context,
        Icons.folder_open,
        'Read Access',
        'OpenCode can read files in this directory',
      ),
      _buildPermissionItem(
        context,
        Icons.edit_note,
        'Write Access',
        'OpenCode can create and modify files',
      ),
      _buildPermissionItem(
        context,
        Icons.code,
        'Execute Operations',
        'Run commands and tools within this workspace',
      ),
    ];
  }

  Widget _buildPermissionItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _authorize() async {
    setState(() {
      _isAuthorizing = true;
      _errorMessage = null;
    });

    try {
      final result =
          await ref.read(workspaceProvider.notifier).authorizeDirectory(
                widget.path,
              );

      if (mounted) {
        setState(() {
          _isAuthorized = true;
          _isAuthorizing = false;
          _message = result['message'] ?? 'Directory authorized successfully';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message!),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isAuthorizing = false;
        _errorMessage = e.toString();
      });
    }
  }
}
