import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../data/providers/dashboard_providers.dart';

class InstallSkillDialog extends ConsumerStatefulWidget {
  const InstallSkillDialog({super.key});

  @override
  ConsumerState<InstallSkillDialog> createState() => _InstallSkillDialogState();
}

class _InstallSkillDialogState extends ConsumerState<InstallSkillDialog> {
  final TextEditingController _skillNameController = TextEditingController();
  bool _isSearching = false;
  List<String> _searchResults = [];
  String? _selectedSkill;
  bool _isInstalling = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _skillNameController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _skillNameController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _skillNameController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _selectedSkill = null;
      });
      return;
    }

    // Simulate searching for available skills
    // In a real app, this would call an API to search the opkg registry
    setState(() {
      _isSearching = true;
      _searchResults = _mockSearchSkills(query);
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    });
  }

  List<String> _mockSearchSkills(String query) {
    // Mock data for available skills
    final availableSkills = [
      'git-master',
      'playwright',
      'frontend-ui-ux',
      'librarian',
      'explore',
      'docker',
      'kubernetes',
      'aws',
      'database',
      'testing',
    ];

    return availableSkills
        .where((skill) => skill.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> _installSkill() async {
    final skillName = _selectedSkill ?? _skillNameController.text.trim();
    if (skillName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a skill name';
      });
      return;
    }

    setState(() {
      _isInstalling = true;
      _errorMessage = null;
    });

    try {
      await ref.read(skillsProvider.notifier).installSkill(skillName);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Skill "$skillName" installed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInstalling = false;
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
          Icon(Icons.add_circle_outline, color: Colors.blue),
          SizedBox(width: 12),
          Text('Install Skill'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Install a skill from OpenPackage (opkg) registry:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            AppInput(
              controller: _skillNameController,
              label: 'Skill Name',
              hint: 'e.g., git-master, playwright, docker',
              autofocus: true,
              prefixIcon: const Icon(Icons.search),
              errorText: _errorMessage,
            ),
            const SizedBox(height: 8),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final skill = _searchResults[index];
                    final isSelected = _selectedSkill == skill;
                    return ListTile(
                      title: Text(skill),
                      leading: const Icon(Icons.extension),
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedSkill = skill;
                          _skillNameController.text = skill;
                          _searchResults.clear();
                          _errorMessage = null;
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'The skill will be installed from the OpenPackage registry using opkg.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isInstalling ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          text: _isInstalling ? 'Installing...' : 'Install',
          isLoading: _isInstalling,
          icon: const Icon(Icons.download),
          onPressed: _isInstalling ? null : _installSkill,
        ),
      ],
    );
  }
}
