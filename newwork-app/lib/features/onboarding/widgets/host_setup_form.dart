import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_card.dart';

enum WorkspacePreset { starter, automation, minimal }

class HostSetupForm extends ConsumerStatefulWidget {
  final String? initialWorkspacePath;
  final String? initialWorkspaceName;
  final WorkspacePreset initialPreset;
  final VoidCallback onBack;
  final Future<bool> Function({
    required String workspaceName,
    required String workspacePath,
    required WorkspacePreset preset,
  }) onComplete;

  const HostSetupForm({
    super.key,
    this.initialWorkspacePath,
    this.initialWorkspaceName,
    this.initialPreset = WorkspacePreset.starter,
    required this.onBack,
    required this.onComplete,
  });

  @override
  ConsumerState<HostSetupForm> createState() => _HostSetupFormState();
}

class _HostSetupFormState extends ConsumerState<HostSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pathController = TextEditingController();

  WorkspacePreset _selectedPreset = WorkspacePreset.starter;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialWorkspaceName ?? '';
    _pathController.text = widget.initialWorkspacePath ?? '';
    _selectedPreset = widget.initialPreset;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null && mounted) {
        _pathController.text = result;
        // Auto-generate workspace name from path if name is empty
        if (_nameController.text.isEmpty) {
          final dirName = result.split('/').last;
          _nameController.text = dirName.isEmpty ? 'My Workspace' : dirName;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to pick directory: $e';
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onComplete(
        workspaceName: _nameController.text.trim(),
        workspacePath: _pathController.text.trim(),
        preset: _selectedPreset,
      );

      if (mounted && !success) {
        setState(() {
          _errorMessage = 'Failed to create workspace. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            title: const Text('Workspace Setup'),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a directory for your workspace where OpenCode will store projects and configurations.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Workspace Name',
                  hint: 'e.g., My Projects',
                  controller: _nameController,
                  isRequired: true,
                  inputType: AppInputType.text,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppInput(
                        label: 'Workspace Directory',
                        hint: 'Select a directory',
                        controller: _pathController,
                        isRequired: true,
                        isReadOnly: true,
                        suffixIcon: const Icon(Icons.folder_open),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: AppButton(
                        text: 'Browse',
                        variant: AppButtonVariant.secondary,
                        onPressed: _pickDirectory,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            title: const Text('Select Preset'),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a preset to configure your workspace with recommended settings.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPresetOption(
                  context,
                  WorkspacePreset.starter,
                  'Starter',
                  'Perfect for getting started with all essential features enabled',
                  Icons.rocket_launch,
                ),
                const SizedBox(height: 12),
                _buildPresetOption(
                  context,
                  WorkspacePreset.automation,
                  'Automation',
                  'Optimized for automated workflows and CI/CD pipelines',
                  Icons.auto_mode,
                ),
                const SizedBox(height: 12),
                _buildPresetOption(
                  context,
                  WorkspacePreset.minimal,
                  'Minimal',
                  'Lightweight setup with only core functionality',
                  Icons.compress,
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style:
                          TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Back',
                  variant: AppButtonVariant.secondary,
                  onPressed: widget.onBack,
                  isDisabled: _isLoading,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  text: 'Create Workspace',
                  variant: AppButtonVariant.primary,
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                  isDisabled: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetOption(
    BuildContext context,
    WorkspacePreset preset,
    String title,
    String description,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedPreset == preset;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPreset = preset;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
