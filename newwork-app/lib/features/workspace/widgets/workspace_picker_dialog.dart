import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/providers/dashboard_providers.dart';
import '../../../shared/widgets/app_button.dart';

enum WorkspacePreset {
  starter('Starter', 'Full-featured workspace with all configurations'),
  automation('Automation', 'Optimized for AI automation workflows'),
  minimal('Minimal', 'Basic workspace with essential configs only');

  final String displayName;
  final String description;

  const WorkspacePreset(this.displayName, this.description);
}

class WorkspacePickerDialog extends ConsumerStatefulWidget {
  const WorkspacePickerDialog({super.key});

  @override
  ConsumerState<WorkspacePickerDialog> createState() =>
      _WorkspacePickerDialogState();
}

class _WorkspacePickerDialogState extends ConsumerState<WorkspacePickerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  WorkspacePreset _selectedPreset = WorkspacePreset.starter;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Workspace'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Workspace Name',
                  hintText: 'e.g., My Project',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a workspace name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pathController,
                decoration: InputDecoration(
                  labelText: 'Workspace Path',
                  hintText: 'e.g., /Users/name/projects/my-project',
                  prefixIcon: const Icon(Icons.folder_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _pickDirectory,
                    tooltip: 'Browse',
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select a workspace directory';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Workspace Preset',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...WorkspacePreset.values.map((preset) {
                return RadioListTile<WorkspacePreset>(
                  title: Text(preset.displayName),
                  subtitle: Text(
                    preset.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  value: preset,
                  groupValue: _selectedPreset,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPreset = value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
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
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontSize: 12,
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
      ),
      actions: [
        AppButton(
          text: 'Cancel',
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        AppButton(
          text: 'Create',
          variant: AppButtonVariant.primary,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _createWorkspace,
        ),
      ],
    );
  }

  Future<void> _pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          _pathController.text = result;
          _errorMessage = null;
        });
        if (_nameController.text.isEmpty) {
          final dirName = result.split('/').last;
          _nameController.text = dirName.isNotEmpty ? dirName : 'My Workspace';
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick directory: $e');
    }
  }

  Future<void> _createWorkspace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(workspaceProvider.notifier).createWorkspace(
            name: _nameController.text.trim(),
            path: _pathController.text.trim(),
            description:
                'Workspace with ${_selectedPreset.displayName.toLowerCase()} preset',
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Workspace "${_nameController.text}" created successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}
