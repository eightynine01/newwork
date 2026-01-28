import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../data/providers/dashboard_providers.dart';

class ImportSkillDialog extends ConsumerStatefulWidget {
  const ImportSkillDialog({super.key});

  @override
  ConsumerState<ImportSkillDialog> createState() => _ImportSkillDialogState();
}

class _ImportSkillDialogState extends ConsumerState<ImportSkillDialog> {
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _skillNameController = TextEditingController();
  bool _isImporting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pathController.dispose();
    _skillNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      setState(() {
        _pathController.text = selectedDirectory!;
        _errorMessage = null;
      });
    }
  }

  Future<void> _copyPath() async {
    await Clipboard.setData(ClipboardData(text: _pathController.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Path copied to clipboard')),
      );
    }
  }

  Future<void> _importSkill() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a skill folder';
      });
      return;
    }

    final skillName = _skillNameController.text.trim();
    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(skillsProvider.notifier).importSkill(
            sourcePath: path,
            skillName: skillName.isEmpty ? null : skillName,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Skill imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.upload_file, color: Colors.blue),
          SizedBox(width: 12),
          Text('Import Local Skill'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a local skill folder to import:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    controller: _pathController,
                    label: 'Skill Folder Path',
                    hint: 'Path to skill folder',
                    isReadOnly: true,
                    prefixIcon: const Icon(Icons.folder_open),
                    errorText: _errorMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy path',
                  onPressed: _pathController.text.isNotEmpty ? _copyPath : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: AppButton(
                text: 'Browse Folders',
                icon: const Icon(Icons.folder),
                variant: AppButtonVariant.secondary,
                onPressed: _pickFolder,
              ),
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _skillNameController,
              label: 'Skill Name (Optional)',
              hint: 'Leave empty to use folder name',
              prefixIcon: const Icon(Icons.edit),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The selected folder must contain a SKILL.md file. '
                      'The skill will be copied to ~/.opencode/skills/.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          text: _isImporting ? 'Importing...' : 'Import',
          isLoading: _isImporting,
          icon: const Icon(Icons.upload),
          onPressed: _isImporting ? null : _importSkill,
        ),
      ],
    );
  }
}
