import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../data/models/ai_provider.dart';
import '../../../data/repositories/api_client.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../data/providers/dashboard_providers.dart';
import '../../../services/auto_update_service.dart';
import '../../settings/widgets/permission_history_list.dart';
import '../../settings/widgets/model_picker_dialog.dart';
import '../../session/providers/session_provider.dart';
import '../../settings/providers/theme_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final providersState = ref.watch(providersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
          _buildSection(
            context,
            'Appearance',
            Icons.palette_outlined,
            children: [
              _buildThemeOption(context, ref, settings),
            ],
          ),
          const SizedBox(height: 24),

          // Model section
          _buildSection(
            context,
            'AI Model',
            Icons.psychology_outlined,
            children: [
              _buildModelOption(context, ref, settings, providersState),
            ],
          ),
          const SizedBox(height: 24),

          // Permissions section
          _buildSection(
            context,
            'Permissions',
            Icons.security_outlined,
            children: [
              _buildPermissionHistoryOption(context, ref),
              _buildClearPermissionHistoryOption(context, ref),
              _buildDefaultPermissionPolicyOption(context, ref, settings),
            ],
          ),
          const SizedBox(height: 24),

          // Data section
          _buildSection(
            context,
            'Data',
            Icons.storage_outlined,
            children: [
              _buildClearCacheOption(context, ref),
              _buildResetAppOption(context, ref),
            ],
          ),
          const SizedBox(height: 24),

          // Updates section
          _buildSection(
            context,
            'Updates',
            Icons.system_update_outlined,
            children: [
              _buildAutoUpdateOption(context, ref, settings),
            ],
          ),
          const SizedBox(height: 24),

          // About section
          _buildSection(
            context,
            'About',
            Icons.info_outline,
            children: [
              _buildAppInfo(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon,
      {required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Divider(color: Theme.of(context).dividerColor),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildThemeOption(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    final currentThemeMode = ref.watch(themeProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Theme Mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeModeOption>(
            segments: const [
              ButtonSegment(
                value: ThemeModeOption.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeModeOption.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode),
              ),
              ButtonSegment(
                value: ThemeModeOption.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (value) {
              final selectedMode = value.first;
              ref.read(settingsProvider.notifier).setThemeMode(selectedMode);
              // Also update theme provider
              final notifier = ref.read(themeProvider.notifier);
              notifier.setTheme(notifier.convertToThemeMode(selectedMode));
            },
          ),
          const SizedBox(height: 16),
          // Theme Preview Cards
          Row(
            children: [
              Expanded(
                child: _buildThemePreviewCard(
                  context,
                  'Light',
                  Colors.white,
                  Colors.black87,
                  ThemeMode.light == currentThemeMode,
                  () => ref
                      .read(themeProvider.notifier)
                      .setTheme(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemePreviewCard(
                  context,
                  'Dark',
                  const Color(0xFF1F2937),
                  Colors.white,
                  ThemeMode.dark == currentThemeMode,
                  () =>
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemePreviewCard(
                  context,
                  'System',
                  Colors.grey,
                  Colors.black87,
                  ThemeMode.system == currentThemeMode,
                  () => ref
                      .read(themeProvider.notifier)
                      .setTheme(ThemeMode.system),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'App theme will follow the selected mode',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreviewCard(
    BuildContext context,
    String label,
    Color bgColor,
    Color textColor,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : textColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelOption(BuildContext context, WidgetRef ref,
      AppSettings settings, ProvidersState providersState) {
    final selectedModel = settings.defaultModelId != null
        ? providersState.models.firstWhere(
            (m) => m.id == settings.defaultModelId,
            orElse: () => AIModel(
              id: '',
              name: 'Not set',
              providerId: '',
              providerName: '',
            ),
          )
        : null;

    return AppCard(
      onTap: () => _showModelPicker(context, ref, settings, providersState),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Model',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedModel != null &&
                        selectedModel.id.isNotEmpty) ...[
                      Text(
                        selectedModel.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            selectedModel.providerName,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(width: 8),
                          ..._buildCapabilityBadges(context, selectedModel),
                        ],
                      ),
                    ] else
                      Text(
                        'Not set',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCapabilitiesLegend(context),
        ],
      ),
    );
  }

  List<Widget> _buildCapabilityBadges(BuildContext context, AIModel model) {
    List<Widget> badges = [];

    if (model.capabilities.any((c) => c == ModelCapability.reasoning)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'R',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ),
      );
    }

    if (model.capabilities.any((c) => c == ModelCapability.vision)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'V',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ),
      );
    }

    return badges;
  }

  Widget _buildCapabilitiesLegend(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              _buildLegendItem(context, 'R', 'Reasoning', Colors.purple),
              _buildLegendItem(context, 'V', 'Vision', Colors.blue),
              _buildLegendItem(context, 'Free', 'Free Model', Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    String description,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildClearCacheOption(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: ListTile(
        leading: Icon(
          Icons.delete_sweep_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Clear Cache'),
        subtitle: Text(
          'Clear all cached data and reload',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Clear Cache'),
              content: const Text(
                'Are you sure you want to clear the cache? This will remove all cached data but will not delete your sessions or templates.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await ref.read(settingsProvider.notifier).clearCache();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to clear cache: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResetAppOption(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: ListTile(
        leading: Icon(
          Icons.restore_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Reset App'),
        subtitle: Text(
          'Reset all settings to defaults',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Reset App'),
              content: const Text(
                'Are you sure you want to reset the app? This will delete all settings and cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await ref.read(settingsProvider.notifier).clearCache();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('App reset')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to reset app: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final info = snapshot.data!;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(context, 'App Name', info.appName),
              const SizedBox(height: 8),
              _buildInfoRow(context, 'Version', info.version),
              const SizedBox(height: 8),
              _buildInfoRow(context, 'Build Number', info.buildNumber),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Check for updates
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Checking for updates...')),
                        );
                      },
                      icon: const Icon(Icons.system_update_alt_outlined),
                      label: const Text('Check for Updates'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Open GitHub/issues
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening GitHub...')),
                        );
                      },
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text('Report Issue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showModelPicker(BuildContext context, WidgetRef ref,
      AppSettings settings, ProvidersState providersState) {
    showDialog(
      context: context,
      builder: (context) => ModelPickerDialog(
        currentModelId: settings.defaultModelId,
      ),
    ).then((selectedModelId) {
      if (selectedModelId != null) {
        final selectedModel = providersState.models.firstWhere(
          (m) => m.id == selectedModelId,
          orElse: () => providersState.models.first,
        );

        ref.read(settingsProvider.notifier).setDefaultModel(
              selectedModelId,
              selectedModel.name,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Default model updated')),
          );
        }
      }
    });
  }

  Widget _buildPermissionHistoryOption(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: ListTile(
        leading: Icon(
          Icons.history,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Permission History'),
        subtitle: Text(
          'View past permission requests',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PermissionHistoryScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClearPermissionHistoryOption(
      BuildContext context, WidgetRef ref) {
    final apiClient = ApiClient();

    return AppCard(
      child: ListTile(
        leading: Icon(
          Icons.delete_sweep_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Clear Permission History'),
        subtitle: Text(
          'Delete all permission history',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Clear Permission History'),
              content: const Text(
                'Are you sure you want to clear all permission history? This cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await apiClient.clearPermissionHistory();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Permission history cleared')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to clear history: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultPermissionPolicyOption(
      BuildContext context, WidgetRef ref, dynamic settings) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Default Permission Policy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<DefaultPermissionPolicy>(
            segments: const [
              ButtonSegment(
                value: DefaultPermissionPolicy.ask,
                label: Text('Ask'),
              ),
              ButtonSegment(
                value: DefaultPermissionPolicy.allow,
                label: Text('Allow'),
              ),
              ButtonSegment(
                value: DefaultPermissionPolicy.deny,
                label: Text('Deny'),
              ),
            ],
            selected: {DefaultPermissionPolicy.ask},
            onSelectionChanged: (value) {
              // TODO: Implement default permission policy setting
              final selectedPolicy = value.first;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Permission policy updated to ${selectedPolicy.name}')),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Default behavior when OpenCode requests permissions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoUpdateOption(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    final autoUpdateService = ref.watch(autoUpdateServiceProvider);
    final updateInfo = ref.watch(updateInfoProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Auto Update',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Switch(
                value: settings.autoUpdateEnabled,
                onChanged: (value) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setAutoUpdateEnabled(value);
                  if (value) {
                    autoUpdateService.startAutoCheck();
                  } else {
                    autoUpdateService.stopAutoCheck();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Automatically check for updates when app starts',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          // 업데이트 알림 설정
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notify on Update',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Switch(
                value: settings.autoUpdateNotify,
                onChanged: settings.autoUpdateEnabled
                    ? (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .setAutoUpdateNotify(value);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 업데이트 상태 표시
          updateInfo.when(
            data: (info) {
              if (info == null) {
                return const SizedBox.shrink();
              }
              if (info.updateAvailable) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.update,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New version available: ${info.latestVersion}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              'Current: ${info.currentVersion}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => autoUpdateService.openDownloadPage(),
                        child: const Text('Download'),
                      ),
                    ],
                  ),
                );
              }
              return Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You are on the latest version (${info.currentVersion})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          // 수동 업데이트 확인 버튼
          OutlinedButton.icon(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checking for updates...')),
              );
              final info = await autoUpdateService.checkForUpdates(force: true);
              if (context.mounted) {
                if (info?.updateAvailable ?? false) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('New version available: ${info!.latestVersion}'),
                      action: SnackBarAction(
                        label: 'Download',
                        onPressed: () => autoUpdateService.openDownloadPage(),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are on the latest version')),
                  );
                }
              }
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Check for Updates'),
          ),
        ],
      ),
    );
  }
}

enum DefaultPermissionPolicy { ask, allow, deny }

class PermissionHistoryScreen extends StatelessWidget {
  const PermissionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permission History'),
      ),
      body: const Center(
        child: Text('Permission history will be displayed here'),
      ),
    );
  }
}
