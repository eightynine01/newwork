import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/skill.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../data/providers/dashboard_providers.dart';
import '../widgets/install_skill_dialog.dart';
import '../widgets/import_skill_dialog.dart';

class SkillsTab extends ConsumerWidget {
  const SkillsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsState = ref.watch(skillsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(skillsProvider.notifier).loadSkills();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Skills refreshed')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Reveal skills folder',
            onPressed: () async {
              try {
                await ref.read(skillsProvider.notifier).revealSkillsFolder();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Skills folder opened')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to open folder: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(skillsProvider.notifier).loadSkills();
        },
        child: skillsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : skillsState.error != null
                ? _buildErrorState(context, skillsState.error!, ref)
                : skillsState.skills.isEmpty
                    ? _buildEmptyState(context, ref)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: skillsState.skills.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildSkillCard(
                                context, skillsState.skills[index], ref),
                          );
                        },
                      ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'import',
            onPressed: () => _showImportSkillDialog(context, ref),
            icon: const Icon(Icons.upload_file),
            label: const Text('Import'),
          ),
          FloatingActionButton.extended(
            heroTag: 'install',
            onPressed: () => _showInstallSkillDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Install'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(BuildContext context, Skill skill, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: skill.isEnabled
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.extension,
                  color: skill.isEnabled
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (skill.version != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'v${skill.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: skill.isEnabled,
                onChanged: (value) {
                  // Toggle skill enable/disable (stored locally for now)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${skill.name} ${value ? "enabled" : "disabled"}')),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'uninstall') {
                    _showUninstallDialog(context, ref, skill);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'uninstall',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Uninstall', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                ),
              ],
            ),
          ],
          ),
          const SizedBox(height: 12),
          if (skill.description != null)
            Text(
              skill.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  skill.category,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (skill.tags.isNotEmpty)
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    children: skill.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No skills installed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Install skills to extend OpenCode capabilities',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Install Skill',
              icon: const Icon(Icons.add),
              onPressed: () => _showInstallSkillDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load skills',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Retry',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await ref.read(skillsProvider.notifier).loadSkills();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInstallSkillDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const InstallSkillDialog(),
    );
  }

  void _showImportSkillDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ImportSkillDialog(),
    );
  }

  void _showUninstallDialog(BuildContext context, WidgetRef ref, Skill skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall Skill'),
        content: Text(
          'Are you sure you want to uninstall "${skill.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(skillsProvider.notifier).uninstallSkill(skill.name);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Skill uninstalled')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to uninstall skill: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}
