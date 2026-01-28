import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tabs/home_tab.dart';
import 'tabs/sessions_tab.dart';
import 'tabs/templates_tab.dart';
import 'tabs/skills_tab.dart';
import 'tabs/plugins_tab.dart';
import 'tabs/mcp_tab.dart';
import 'tabs/settings_tab.dart';
import '../files/file_browser_page.dart';
import '../../data/providers/dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardStateProvider);
    final selectedIndex = dashboardState.activeTabIndex;

    final List<Widget> _tabs = const [
      HomeTab(),
      SessionsTab(),
      TemplatesTab(),
      SkillsTab(),
      PluginsTab(),
      MCPTab(),
      FileBrowserPage(),
      SettingsTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(dashboardStateProvider.notifier).setTab(index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Sessions'),
          NavigationDestination(
            icon: Icon(Icons.description),
            label: 'Templates',
          ),
          NavigationDestination(icon: Icon(Icons.extension), label: 'Skills'),
          NavigationDestination(icon: Icon(Icons.apps), label: 'Plugins'),
          NavigationDestination(icon: Icon(Icons.hub), label: 'MCP'),
          NavigationDestination(icon: Icon(Icons.folder_open), label: 'Files'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
