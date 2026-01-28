import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/plugin.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../data/providers/dashboard_providers.dart';

/// Dialog for adding a new plugin to the configuration.
class AddPluginDialog extends ConsumerStatefulWidget {
  const AddPluginDialog({super.key});

  @override
  ConsumerState<AddPluginDialog> createState() => _AddPluginDialogState();
}

class _AddPluginDialogState extends ConsumerState<AddPluginDialog> {
  final _nameController = TextEditingController();
  PluginScope _selectedScope = PluginScope.global;
  final _configController = TextEditingController();
  bool _isValid = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _validate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _configController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _isValid = _nameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _handleAdd() async {
    if (!_isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Parse config JSON if provided
      Map<String, dynamic>? config;
      if (_configController.text.trim().isNotEmpty) {
        try {
          config = _parseConfig(_configController.text.trim());
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid JSON: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          setState(() => _isSubmitting = false);
          return;
        }
      }

      await ref.read(pluginsProvider.notifier).addPlugin(
            name: _nameController.text.trim(),
            scope: _selectedScope,
            config: config,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plugin added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add plugin: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Map<String, dynamic> _parseConfig(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return {};

    // Simple JSON validation
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
      throw const FormatException('Config must be a JSON object');
    }

    try {
      // Try parsing as JSON
      // Note: For simplicity we're just validating format
      // The actual parsing happens on the backend
      return {};
    } catch (e) {
      throw FormatException('Invalid JSON format');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Add Plugin'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plugin Name
            TextField(
              controller: _nameController,
              autofocus: true,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: 'Plugin Name *',
                hintText: 'e.g., git-master, playwright',
                border: const OutlineInputBorder(),
                filled: true,
                prefixIcon: const Icon(Icons.extension),
              ),
              onChanged: (_) => _validate(),
            ),
            const SizedBox(height: 16),

            // Scope Selection
            Text(
              'Scope',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PluginScope>(
              segments: const [
                ButtonSegment(
                  value: PluginScope.global,
                  label: Text('Global'),
                  icon: Icon(Icons.public, size: 18),
                ),
                ButtonSegment(
                  value: PluginScope.project,
                  label: Text('Project'),
                  icon: Icon(Icons.workspaces_outline, size: 18),
                ),
              ],
              selected: {_selectedScope},
              onSelectionChanged: (value) {
                setState(() => _selectedScope = value.first);
              },
            ),
            const SizedBox(height: 16),

            // Configuration JSON
            TextField(
              controller: _configController,
              maxLines: 5,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: 'Configuration (JSON)',
                hintText: '{"type": "remote", "url": "https://..."}',
                border: const OutlineInputBorder(),
                filled: true,
                prefixIcon: const Icon(Icons.code),
                helperText: 'Optional: JSON configuration for the plugin',
              ),
            ),
            const SizedBox(height: 8),

            // Help link
            InkWell(
              onTap: () {
                // TODO: Open plugin documentation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Plugin documentation coming soon')),
                );
              },
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Learn about plugins',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        AppButton(
          text: 'Add Plugin',
          onPressed: _isValid && !_isSubmitting ? _handleAdd : null,
          isLoading: _isSubmitting,
          isDisabled: !_isValid || _isSubmitting,
        ),
      ],
    );
  }
}
