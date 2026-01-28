import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../data/providers/dashboard_providers.dart';

class AddMcpServerDialog extends ConsumerStatefulWidget {
  const AddMcpServerDialog({super.key});

  @override
  ConsumerState<AddMcpServerDialog> createState() =>
      _AddMcpServerDialogState();
}

class _AddMcpServerDialogState extends ConsumerState<AddMcpServerDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _endpointController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _serverType = 'remote';
  bool _requiresOAuth = false;
  bool _isLoading = false;

  // Environment variables for local servers
  final Map<String, TextEditingController> _envControllers = {};

  @override
  void initState() {
    super.initState();
    // Add a default environment variable field
    _addEnvField();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _descriptionController.dispose();
    for (var controller in _envControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addEnvField() {
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    _envControllers[key] = TextEditingController();
    setState(() {});
  }

  void _removeEnvField(String key) {
    _envControllers[key]?.dispose();
    _envControllers.remove(key);
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Build environment variables map
      final envVars = <String, String>{};
      for (final entry in _envControllers.entries) {
        final parts = entry.value.text.split('=');
        if (parts.length == 2) {
          envVars[parts[0].trim()] = parts[1].trim();
        }
      }

      // Build config
      final config = <String, dynamic>{
        'oauth_enabled': _requiresOAuth,
      };

      if (_serverType == 'remote') {
        // For remote servers, add headers and environment if provided
        if (envVars.isNotEmpty) {
          config['environment'] = envVars;
        }
      } else {
        // For local servers, add environment variables
        config['environment'] = envVars;
      }

      await ref.read(mcpProvider.notifier).addServer(
        name: _nameController.text.trim(),
        endpoint: _endpointController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        config: config,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add server: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add MCP Server'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Server name
                AppInput(
                  label: 'Server Name',
                  hint: 'e.g., GitHub Copilot',
                  controller: _nameController,
                  isRequired: true,
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Server type selection
                Text(
                  'Server Type',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'remote',
                      label: Text('Remote'),
                      icon: Icon(Icons.cloud_outlined),
                    ),
                    ButtonSegment(
                      value: 'local',
                      label: Text('Local'),
                      icon: Icon(Icons.folder_outlined),
                    ),
                  ],
                  selected: {_serverType},
                  onSelectionChanged: (Set<String> value) {
                    setState(() => _serverType = value.first);
                  },
                ),
                const SizedBox(height: 16),

                // Endpoint/Path input
                AppInput(
                  label: _serverType == 'remote' ? 'Endpoint URL' : 'Command/Path',
                  hint: _serverType == 'remote'
                      ? 'e.g., https://api.example.com/mcp'
                      : 'e.g., /usr/local/bin/my-mcp-server',
                  controller: _endpointController,
                  isRequired: true,
                  helperText: _serverType == 'remote'
                      ? 'The HTTP endpoint for the remote MCP server'
                      : 'The command to execute or path to the local server',
                ),
                const SizedBox(height: 16),

                // Description
                AppInput(
                  label: 'Description',
                  hint: 'Optional description of this server',
                  controller: _descriptionController,
                  inputType: AppInputType.multiline,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // OAuth checkbox
                if (_serverType == 'remote')
                  AppCard(
                    variant: AppCardVariant.outlined,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _requiresOAuth,
                          onChanged: (value) {
                            setState(() => _requiresOAuth = value ?? false);
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Requires OAuth',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'If enabled, you will be prompted to authorize via OAuth when connecting to this server.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Environment variables
                if (_serverType == 'local')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Environment Variables',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addEnvField,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Variable'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._envControllers.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppInput(
                                  label: 'Environment Variable',
                                  hint: 'KEY=VALUE',
                                  controller: entry.value,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _removeEnvField(entry.key),
                                color: theme.colorScheme.error,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          text: 'Add Server',
          onPressed: _isLoading ? null : _submit,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
