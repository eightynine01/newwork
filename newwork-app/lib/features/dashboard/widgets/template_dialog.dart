import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/template.dart';
import '../../../data/providers/dashboard_providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';

enum TemplateDialogMode { create, edit }

class TemplateDialog extends ConsumerStatefulWidget {
  final TemplateDialogMode mode;
  final Template? template;

  const TemplateDialog({
    super.key,
    required this.mode,
    this.template,
  }) : assert(mode == TemplateDialogMode.create || template != null,
            'Template must be provided for edit mode');

  @override
  ConsumerState<TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends ConsumerState<TemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promptController = TextEditingController();
  final _skillsController = TextEditingController();
  String _selectedScope = 'workspace';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == TemplateDialogMode.edit && widget.template != null) {
      _nameController.text = widget.template!.name;
      _descriptionController.text = widget.template!.description ?? '';
      _promptController.text = widget.template!.systemPrompt;
      _skillsController.text = widget.template!.skills.join(', ');
      _selectedScope = widget.template!.isPublic ? 'global' : 'workspace';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _promptController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  List<String> _parseSkills() {
    return _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final skills = _parseSkills();

      if (widget.mode == TemplateDialogMode.create) {
        await ref.read(templatesProvider.notifier).createTemplate(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              systemPrompt: _promptController.text.trim(),
              skills: skills.isEmpty ? null : skills,
              scope: _selectedScope,
            );
      } else {
        await ref.read(templatesProvider.notifier).updateTemplate(
              widget.template!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              systemPrompt: _promptController.text.trim(),
              skills: skills.isEmpty ? null : skills,
              scope: _selectedScope,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.mode == TemplateDialogMode.create
                ? 'Template created'
                : 'Template updated'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to ${widget.mode == TemplateDialogMode.create ? 'create' : 'update'} template: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.mode == TemplateDialogMode.edit;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Template' : 'Create Template'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppInput(
                  label: 'Template Name',
                  controller: _nameController,
                  isRequired: true,
                  helperText: 'A descriptive name for your template',
                  autofocus: !isEdit,
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Description',
                  controller: _descriptionController,
                  inputType: AppInputType.multiline,
                  maxLines: 3,
                  helperText: 'Optional description of what this template does',
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'System Prompt',
                  controller: _promptController,
                  inputType: AppInputType.multiline,
                  maxLines: 8,
                  isRequired: true,
                  helperText:
                      'Use {{variable_name}} for variables that will be substituted when running',
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Skills',
                  controller: _skillsController,
                  helperText:
                      'Comma-separated list of skills (e.g., git-master, playwright)',
                ),
                const SizedBox(height: 16),
                Text(
                  'Scope',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Workspace'),
                        subtitle:
                            const Text('Only visible in current workspace'),
                        value: 'workspace',
                        groupValue: _selectedScope,
                        onChanged: (value) {
                          setState(() {
                            _selectedScope = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Global'),
                        subtitle: const Text('Available across all workspaces'),
                        value: 'global',
                        groupValue: _selectedScope,
                        onChanged: (value) {
                          setState(() {
                            _selectedScope = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppButton(
          text: 'Cancel',
          variant: AppButtonVariant.text,
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        AppButton(
          text: isEdit ? 'Update' : 'Create',
          onPressed: _isSubmitting ? null : _submit,
          isLoading: _isSubmitting,
        ),
      ],
    );
  }
}
