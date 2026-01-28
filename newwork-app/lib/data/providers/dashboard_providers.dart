import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../models/message.dart';
import '../models/todo.dart';
import '../models/template.dart';
import '../models/skill.dart';
import '../models/workspace.dart';
import '../models/plugin.dart';
import '../models/mcp_server.dart';
import '../models/ai_provider.dart';
import '../models/local_session.dart';
import '../models/local_template.dart';
import '../models/local_workspace.dart';
import '../models/file_item.dart';
import '../repositories/api_client.dart';
import '../providers/storage_provider.dart';
import '../providers/local_db_provider.dart';
import '../../services/backend_manager.dart';
import '../../services/error_recovery_service.dart';
import '../../services/system_restart_service.dart';
import '../../services/auto_update_service.dart';
import '../../core/constants.dart';
import '../../core/error/app_error.dart';

enum ThemeModeOption { light, dark, system }

// ==================== 서비스 Provider ====================

/// 백엔드 매니저 Provider
///
/// 싱글톤으로 관리되며, 앱 시작 시 main.dart에서 초기화됩니다.
final backendManagerProvider = Provider<BackendManager>((ref) {
  throw UnimplementedError('BackendManager must be overridden in main.dart');
});

/// 오류 복구 서비스 Provider
///
/// 앱 전역의 오류를 수집, 분류하고 적절한 복구 전략을 실행합니다.
final errorRecoveryServiceProvider = Provider<ErrorRecoveryService>((ref) {
  throw UnimplementedError('ErrorRecoveryService must be overridden in main.dart');
});

/// 시스템 재시작 서비스 Provider
///
/// 전체 시스템(백엔드 + 프론트엔드 상태)을 안전하게 재시작합니다.
final systemRestartServiceProvider = Provider<SystemRestartService>((ref) {
  throw UnimplementedError('SystemRestartService must be overridden in main.dart');
});

/// 백엔드 헬스 상태 Provider
final backendHealthProvider = StreamProvider<BackendHealth>((ref) {
  final backendManager = ref.watch(backendManagerProvider);
  return backendManager.healthStream;
});

/// 복구 시도 상태 Provider
final recoveryAttemptProvider = StreamProvider<RecoveryAttempt>((ref) {
  final errorRecoveryService = ref.watch(errorRecoveryServiceProvider);
  return errorRecoveryService.recoveryStream;
});

/// 재시작 진행 상황 Provider
final restartProgressProvider = StreamProvider<RestartProgress>((ref) {
  final systemRestartService = ref.watch(systemRestartServiceProvider);
  return systemRestartService.progressStream;
});

/// 자동 업데이트 서비스 Provider
final autoUpdateServiceProvider = Provider<AutoUpdateService>((ref) {
  final service = AutoUpdateService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 업데이트 정보 Provider
final updateInfoProvider = StreamProvider<UpdateInfo?>((ref) {
  final autoUpdateService = ref.watch(autoUpdateServiceProvider);
  return autoUpdateService.updateStream;
});

// API Client Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// Local Database Provider
final localDbProvider = Provider<LocalDbProvider>((ref) {
  return LocalDbProvider();
});

// Storage Provider
final storageProvider = Provider<StorageProvider>((ref) {
  return StorageProvider();
});

// Dashboard Tab State
class DashboardState {
  final int activeTabIndex;
  final bool isConnected;

  DashboardState({this.activeTabIndex = 0, this.isConnected = true});

  DashboardState copyWith({int? activeTabIndex, bool? isConnected}) {
    return DashboardState(
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class DashboardStateNotifier extends StateNotifier<DashboardState> {
  DashboardStateNotifier() : super(DashboardState());

  void setTab(int index) {
    state = state.copyWith(activeTabIndex: index);
  }

  void setConnectionStatus(bool connected) {
    state = state.copyWith(isConnected: connected);
  }
}

final dashboardStateProvider =
    StateNotifierProvider<DashboardStateNotifier, DashboardState>((ref) {
  return DashboardStateNotifier();
});

// Sessions State
class SessionsState {
  final List<Session> sessions;
  final bool isLoading;
  final String? error;

  SessionsState({this.sessions = const [], this.isLoading = false, this.error});

  SessionsState copyWith({
    List<Session>? sessions,
    bool? isLoading,
    String? error,
  }) {
    return SessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SessionsNotifier extends StateNotifier<SessionsState> {
  final ApiClient _apiClient;
  final LocalDbProvider _localDb;

  SessionsNotifier(this._apiClient, this._localDb) : super(SessionsState()) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Try to load from API first
      final sessions = await _apiClient.getSessions();

      // Save to local database
      for (final session in sessions) {
        final localSession = LocalSession.fromApiSession(session);
        await _localDb.insertSession(localSession);
      }

      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      // If API fails, load from local database
      try {
        final localSessions = await _localDb.getSessions();
        final sessions = localSessions
            .map((ls) => Session(
                  id: ls.id,
                  title: ls.title,
                  createdAt: ls.createdAt,
                  updatedAt: ls.updatedAt,
                  messages:
                      (ls.messages).map((m) => Message.fromJson(m)).toList(),
                  todos: (ls.todos).map((t) => Todo.fromJson(t)).toList(),
                ))
            .toList();

        state = state.copyWith(sessions: sessions, isLoading: false);
      } catch (localError) {
        state = state.copyWith(
          isLoading: false,
          error: 'API failed: $e, Local DB failed: $localError',
        );
      }
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      // Delete from API
      await _apiClient.deleteSession(id);

      // Delete from local database
      await _localDb.deleteSession(id);

      // Update state
      final updatedSessions = state.sessions.where((s) => s.id != id).toList();
      state = state.copyWith(sessions: updatedSessions);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Session> createSession({
    required String title,
    String? templateId,
  }) async {
    try {
      // Create via API
      final session = await _apiClient.createSession(
        title: title,
        templateId: templateId,
      );

      // Save to local database
      final localSession = LocalSession.fromApiSession(session);
      await _localDb.insertSession(localSession);

      // Update state
      state = state.copyWith(sessions: [session, ...state.sessions]);
      return session;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final sessionsProvider = StateNotifierProvider<SessionsNotifier, SessionsState>(
  (ref) {
    final apiClient = ref.watch(apiClientProvider);
    final localDb = ref.watch(localDbProvider);
    return SessionsNotifier(apiClient, localDb);
  },
);

// Templates State
class TemplatesState {
  final List<Template> templates;
  final bool isLoading;
  final String? error;
  final bool showWorkspaceOnly;

  TemplatesState({
    this.templates = const [],
    this.isLoading = false,
    this.error,
    this.showWorkspaceOnly = false,
  });

  TemplatesState copyWith({
    List<Template>? templates,
    bool? isLoading,
    String? error,
    bool? showWorkspaceOnly,
  }) {
    return TemplatesState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      showWorkspaceOnly: showWorkspaceOnly ?? this.showWorkspaceOnly,
    );
  }

  List<Template> get filteredTemplates => showWorkspaceOnly
      ? templates.where((t) => !t.isPublic).toList()
      : templates;
}

class TemplatesNotifier extends StateNotifier<TemplatesState> {
  final ApiClient _apiClient;
  final LocalDbProvider _localDb;

  TemplatesNotifier(this._apiClient, this._localDb) : super(TemplatesState()) {
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Try to load from API first
      final templates = await _apiClient.getTemplates();

      // Save to local database
      for (final template in templates) {
        final localTemplate = LocalTemplate.fromApiTemplate(template);
        await _localDb.insertTemplate(localTemplate);
      }

      state = state.copyWith(templates: templates, isLoading: false);
    } catch (e) {
      // If API fails, load from local database
      try {
        final localTemplates = await _localDb.getTemplates();
        final templates = localTemplates
            .map((lt) => Template(
                  id: lt.id,
                  name: lt.title,
                  description: lt.description,
                  systemPrompt: lt.prompt,
                  skills: lt.skills ?? [],
                  createdAt: lt.createdAt,
                  updatedAt: lt.createdAt,
                  usageCount: 0,
                  isPublic: lt.scope == 'global',
                ))
            .toList();

        state = state.copyWith(templates: templates, isLoading: false);
      } catch (localError) {
        state = state.copyWith(
          isLoading: false,
          error: 'API failed: $e, Local DB failed: $localError',
        );
      }
    }
  }

  void setScopeFilter(bool workspaceOnly) {
    state = state.copyWith(showWorkspaceOnly: workspaceOnly);
  }

  Future<void> deleteTemplate(String id) async {
    try {
      // Delete from API
      await _apiClient.deleteTemplate(id);

      // Delete from local database
      await _localDb.deleteTemplate(id);

      // Update state
      final updatedTemplates =
          state.templates.where((t) => t.id != id).toList();
      state = state.copyWith(templates: updatedTemplates);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Template> createTemplate({
    required String name,
    required String systemPrompt,
    String? description,
    List<String>? skills,
    String? scope,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Create via API
      final template = await _apiClient.createTemplate(
        name: name,
        systemPrompt: systemPrompt,
        description: description,
        skills: skills,
        scope: scope,
        parameters: parameters,
      );

      // Save to local database
      final localTemplate = LocalTemplate.fromApiTemplate(template);
      await _localDb.insertTemplate(localTemplate);

      // Update state
      state = state.copyWith(templates: [template, ...state.templates]);
      return template;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<Template> updateTemplate(
    String id, {
    String? name,
    String? systemPrompt,
    String? description,
    List<String>? skills,
    String? scope,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Update via API
      final updatedTemplate = await _apiClient.updateTemplate(
        id,
        name: name,
        systemPrompt: systemPrompt,
        description: description,
        skills: skills,
        scope: scope,
        parameters: parameters,
      );

      // Update in local database
      final localTemplate = LocalTemplate.fromApiTemplate(updatedTemplate);
      await _localDb.updateTemplate(localTemplate);

      // Update state
      final updatedTemplates =
          state.templates.map((t) => t.id == id ? updatedTemplate : t).toList();
      state = state.copyWith(templates: updatedTemplates);
      return updatedTemplate;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> runTemplate(
    String id, {
    Map<String, dynamic>? variables,
  }) async {
    try {
      return await _apiClient.runTemplate(id, variables: variables);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final templatesProvider =
    StateNotifierProvider<TemplatesNotifier, TemplatesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localDb = ref.watch(localDbProvider);
  return TemplatesNotifier(apiClient, localDb);
});

// Skills State
class SkillsState {
  final List<Skill> skills;
  final bool isLoading;
  final String? error;
  final bool isInstalling;
  final bool isImporting;

  SkillsState({
    this.skills = const [],
    this.isLoading = false,
    this.error,
    this.isInstalling = false,
    this.isImporting = false,
  });

  SkillsState copyWith({
    List<Skill>? skills,
    bool? isLoading,
    String? error,
    bool? isInstalling,
    bool? isImporting,
  }) {
    return SkillsState(
      skills: skills ?? this.skills,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInstalling: isInstalling ?? this.isInstalling,
      isImporting: isImporting ?? this.isImporting,
    );
  }
}

class SkillsNotifier extends StateNotifier<SkillsState> {
  final ApiClient _apiClient;

  SkillsNotifier(this._apiClient) : super(SkillsState()) {
    loadSkills();
  }

  Future<void> loadSkills() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final skills = await _apiClient.getSkills();
      state = state.copyWith(skills: skills, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> installSkill(String skillName) async {
    state = state.copyWith(isInstalling: true, error: null);
    try {
      await _apiClient.installSkill(skillName);
      await loadSkills();
    } catch (e) {
      state = state.copyWith(isInstalling: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> importSkill({
    required String sourcePath,
    String? skillName,
  }) async {
    state = state.copyWith(isImporting: true, error: null);
    try {
      await _apiClient.importSkill(
        sourcePath: sourcePath,
        skillName: skillName,
      );
      await loadSkills();
    } catch (e) {
      state = state.copyWith(isImporting: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> uninstallSkill(String skillName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.uninstallSkill(skillName);
      final updatedSkills =
          state.skills.where((s) => s.name != skillName).toList();
      state = state.copyWith(skills: updatedSkills, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> revealSkillsFolder() async {
    try {
      await _apiClient.revealSkillsFolder();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final skillsProvider = StateNotifierProvider<SkillsNotifier, SkillsState>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return SkillsNotifier(apiClient);
});

// Plugins State
class PluginsState {
  final List<Plugin> plugins;
  final bool isLoading;
  final String? error;
  final bool showProjectOnly;

  PluginsState({
    this.plugins = const [],
    this.isLoading = false,
    this.error,
    this.showProjectOnly = false,
  });

  PluginsState copyWith({
    List<Plugin>? plugins,
    bool? isLoading,
    String? error,
    bool? showProjectOnly,
  }) {
    return PluginsState(
      plugins: plugins ?? this.plugins,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      showProjectOnly: showProjectOnly ?? this.showProjectOnly,
    );
  }

  List<Plugin> get filteredPlugins => showProjectOnly
      ? plugins.where((p) => p.scope == PluginScope.project).toList()
      : plugins;
}

class PluginsNotifier extends StateNotifier<PluginsState> {
  final ApiClient _apiClient;

  PluginsNotifier(this._apiClient) : super(PluginsState()) {
    loadPlugins();
  }

  Future<void> loadPlugins({PluginScope? scope}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plugins = await _apiClient.getPlugins(scope: scope);
      state = state.copyWith(plugins: plugins, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setScopeFilter(bool projectOnly) {
    state = state.copyWith(showProjectOnly: projectOnly);
  }

  Future<void> removePlugin(String id) async {
    try {
      await _apiClient.removePlugin(id);
      final updatedPlugins = state.plugins.where((p) => p.id != id).toList();
      state = state.copyWith(plugins: updatedPlugins);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Plugin> addPlugin({
    required String name,
    PluginScope? scope,
    Map<String, dynamic>? config,
  }) async {
    try {
      final plugin = await _apiClient.addPlugin(
        name: name,
        scope: scope,
        config: config,
      );
      state = state.copyWith(plugins: [plugin, ...state.plugins]);
      return plugin;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> togglePlugin(String id, bool enabled) async {
    try {
      await _apiClient.updatePlugin(id, {'is_enabled': enabled});
      final updatedPlugins = state.plugins.map((p) {
        if (p.id == id) {
          return p.copyWith(isEnabled: enabled);
        }
        return p;
      }).toList();
      state = state.copyWith(plugins: updatedPlugins);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final pluginsProvider = StateNotifierProvider<PluginsNotifier, PluginsState>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return PluginsNotifier(apiClient);
});

// MCP Servers State
class McpState {
  final List<MCPServer> servers;
  final bool isLoading;
  final String? error;
  final Map<String, List<MCPTool>> serverTools;
  final Map<String, MCPHealthStatus> serverHealth;

  McpState({
    this.servers = const [],
    this.isLoading = false,
    this.error,
    this.serverTools = const {},
    this.serverHealth = const {},
  });

  McpState copyWith({
    List<MCPServer>? servers,
    bool? isLoading,
    String? error,
    Map<String, List<MCPTool>>? serverTools,
    Map<String, MCPHealthStatus>? serverHealth,
  }) {
    return McpState(
      servers: servers ?? this.servers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      serverTools: serverTools ?? this.serverTools,
      serverHealth: serverHealth ?? this.serverHealth,
    );
  }

  List<MCPTool> getToolsForServer(String serverId) {
    return serverTools[serverId] ?? [];
  }

  MCPHealthStatus? getHealthForServer(String serverId) {
    return serverHealth[serverId];
  }
}

class McpNotifier extends StateNotifier<McpState> {
  final ApiClient _apiClient;

  McpNotifier(this._apiClient) : super(McpState()) {
    loadServers();
  }

  Future<void> loadServers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final servers = await _apiClient.getMcpServers();
      state = state.copyWith(servers: servers, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeServer(String id) async {
    try {
      await _apiClient.removeMcpServer(id);
      final updatedServers = state.servers.where((s) => s.id != id).toList();
      state = state.copyWith(servers: updatedServers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<MCPServer> addServer({
    required String name,
    required String endpoint,
    String? description,
    Map<String, dynamic>? config,
  }) async {
    try {
      final server = await _apiClient.addMcpServer(
        name: name,
        endpoint: endpoint,
        description: description,
        config: config,
      );
      state = state.copyWith(servers: [server, ...state.servers]);
      return server;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> connectServer(String id) async {
    try {
      await _apiClient.connectMcpServer(id);
      final updatedServers = state.servers.map((s) {
        if (s.id == id) {
          return s.copyWith(status: MCPServerStatus.connected);
        }
        return s;
      }).toList();
      state = state.copyWith(servers: updatedServers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> disconnectServer(String id) async {
    try {
      await _apiClient.disconnectMcpServer(id);
      final updatedServers = state.servers.map((s) {
        if (s.id == id) {
          return s.copyWith(status: MCPServerStatus.disconnected);
        }
        return s;
      }).toList();
      state = state.copyWith(servers: updatedServers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshStatus(String id) async {
    try {
      final server = await _apiClient.getMcpServerStatus(id);
      final updatedServers = state.servers.map((s) {
        if (s.id == id) {
          return server;
        }
        return s;
      }).toList();
      state = state.copyWith(servers: updatedServers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<MCPTool>> loadServerTools(String id, {bool refresh = false}) async {
    try {
      final tools = await _apiClient.getMcpServerTools(id, refresh: refresh);
      final updatedTools = Map<String, List<MCPTool>>.from(state.serverTools);
      updatedTools[id] = tools;
      state = state.copyWith(serverTools: updatedTools);
      return tools;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<MCPHealthStatus?> loadServerHealth(String id) async {
    try {
      final health = await _apiClient.getMcpServerHealth(id);
      final updatedHealth = Map<String, MCPHealthStatus>.from(state.serverHealth);
      updatedHealth[id] = health;
      state = state.copyWith(serverHealth: updatedHealth);
      return health;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> refreshAllHealth() async {
    for (final server in state.servers) {
      if (server.status == MCPServerStatus.connected) {
        await loadServerHealth(server.id);
      }
    }
  }
}

final mcpProvider = StateNotifierProvider<McpNotifier, McpState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return McpNotifier(apiClient);
});

// Settings State
class AppSettings {
  final ThemeModeOption themeMode;
  final String? defaultModelId;
  final String? defaultModelName;
  final bool autoUpdateEnabled;
  final bool autoUpdateNotify;

  /// 기본 모델 (API 키가 없는 경우 사용)
  /// Claude Sonnet 4를 기본으로 사용
  static const String fallbackModelId = 'claude-sonnet-4-20250514';
  static const String fallbackModelName = 'Claude Sonnet 4';
  static const String fallbackProviderId = 'anthropic';

  AppSettings({
    this.themeMode = ThemeModeOption.system,
    this.defaultModelId,
    this.defaultModelName,
    this.autoUpdateEnabled = true,
    this.autoUpdateNotify = true,
  });

  /// 사용할 모델 ID (설정된 모델이 없으면 fallback 사용)
  String get effectiveModelId => defaultModelId ?? fallbackModelId;

  /// 사용할 모델 이름 (설정된 모델이 없으면 fallback 사용)
  String get effectiveModelName => defaultModelName ?? fallbackModelName;

  AppSettings copyWith({
    ThemeModeOption? themeMode,
    String? defaultModelId,
    String? defaultModelName,
    bool? autoUpdateEnabled,
    bool? autoUpdateNotify,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultModelId: defaultModelId ?? this.defaultModelId,
      defaultModelName: defaultModelName ?? this.defaultModelName,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      autoUpdateNotify: autoUpdateNotify ?? this.autoUpdateNotify,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageProvider _storage;

  SettingsNotifier(this._storage) : super(AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      await _storage.init();
      final themeModeStr = _storage.getString('theme_mode');
      final modelId = _storage.getString('default_model_id');
      final modelName = _storage.getString('default_model_name');
      final autoUpdateEnabled = _storage.getBool('auto_update_enabled');
      final autoUpdateNotify = _storage.getBool('auto_update_notify');

      state = AppSettings(
        themeMode: themeModeStr != null
            ? ThemeModeOption.values.firstWhere(
                (e) => e.name == themeModeStr,
                orElse: () => ThemeModeOption.system,
              )
            : ThemeModeOption.system,
        defaultModelId: modelId,
        defaultModelName: modelName,
        autoUpdateEnabled: autoUpdateEnabled ?? true,
        autoUpdateNotify: autoUpdateNotify ?? true,
      );
    } catch (e) {
      // Keep defaults on error
    }
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.setString('theme_mode', mode.name);
  }

  Future<void> setDefaultModel(String modelId, String modelName) async {
    state = state.copyWith(
      defaultModelId: modelId,
      defaultModelName: modelName,
    );
    await _storage.setString('default_model_id', modelId);
    await _storage.setString('default_model_name', modelName);
  }

  /// 기본 모델 초기화 (fallback으로 리셋)
  Future<void> resetDefaultModel() async {
    state = state.copyWith(
      defaultModelId: null,
      defaultModelName: null,
    );
    await _storage.remove('default_model_id');
    await _storage.remove('default_model_name');
  }

  /// 자동 업데이트 설정
  Future<void> setAutoUpdateEnabled(bool enabled) async {
    state = state.copyWith(autoUpdateEnabled: enabled);
    await _storage.setBool('auto_update_enabled', enabled);
  }

  /// 자동 업데이트 알림 설정
  Future<void> setAutoUpdateNotify(bool notify) async {
    state = state.copyWith(autoUpdateNotify: notify);
    await _storage.setBool('auto_update_notify', notify);
  }

  Future<void> clearCache() async {
    await _storage.clear();
    await _loadSettings();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  final storage = ref.watch(storageProvider);
  return SettingsNotifier(storage);
});

// Providers and Models State
class ProvidersState {
  final List<AIProvider> providers;
  final List<AIModel> models;
  final bool isLoading;
  final String? error;

  ProvidersState({
    this.providers = const [],
    this.models = const [],
    this.isLoading = false,
    this.error,
  });

  ProvidersState copyWith({
    List<AIProvider>? providers,
    List<AIModel>? models,
    bool? isLoading,
    String? error,
  }) {
    return ProvidersState(
      providers: providers ?? this.providers,
      models: models ?? this.models,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<AIModel> getModelsForProvider(String providerId) {
    return models.where((m) => m.providerId == providerId).toList();
  }
}

class ProvidersNotifier extends StateNotifier<ProvidersState> {
  final ApiClient _apiClient;

  ProvidersNotifier(this._apiClient) : super(ProvidersState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _apiClient.getProviders(),
        _apiClient.getModels(),
      ]);
      state = state.copyWith(
        providers: results[0] as List<AIProvider>,
        models: results[1] as List<AIModel>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setDefaultModel(String modelId) async {
    try {
      await _apiClient.setDefaultModel(modelId);
      final updatedModels = state.models.map((m) {
        return m.copyWith(isDefault: m.id == modelId);
      }).toList();
      state = state.copyWith(models: updatedModels);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final providersProvider =
    StateNotifierProvider<ProvidersNotifier, ProvidersState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProvidersNotifier(apiClient);
});

// Workspace State
class WorkspaceState {
  final List<Workspace> workspaces;
  final Workspace? activeWorkspace;
  final bool isLoading;
  final String? error;

  WorkspaceState({
    this.workspaces = const [],
    this.activeWorkspace,
    this.isLoading = false,
    this.error,
  });

  WorkspaceState copyWith({
    List<Workspace>? workspaces,
    Workspace? activeWorkspace,
    bool? isLoading,
    String? error,
  }) {
    return WorkspaceState(
      workspaces: workspaces ?? this.workspaces,
      activeWorkspace: activeWorkspace ?? this.activeWorkspace,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  final ApiClient _apiClient;
  final StorageProvider _storage;
  final LocalDbProvider _localDb;

  WorkspaceNotifier(this._apiClient, this._storage, this._localDb)
      : super(WorkspaceState()) {
    loadWorkspaces();
  }

  Future<void> loadWorkspaces() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Try to load from API first
      final workspaces = await _apiClient.getWorkspaces();

      // Save to local database
      for (final workspace in workspaces) {
        final localWorkspace = LocalWorkspace.fromApiWorkspace(workspace);
        await _localDb.insertWorkspace(localWorkspace);
      }

      final activeWorkspaceId = _storage.getString(AppConstants.workspaceIdKey);
      Workspace? activeWorkspace;
      if (activeWorkspaceId != null) {
        activeWorkspace = workspaces.firstWhere(
          (w) => w.id == activeWorkspaceId,
          orElse: () => workspaces.isNotEmpty
              ? workspaces.first
              : Workspace(
                  id: '',
                  name: '',
                  path: '',
                  createdAt: DateTime.now(),
                ),
        );
      } else if (workspaces.isNotEmpty) {
        activeWorkspace = workspaces.first;
      }
      state = state.copyWith(
        workspaces: workspaces,
        activeWorkspace:
            activeWorkspace != null && activeWorkspace.id.isNotEmpty
                ? activeWorkspace
                : null,
        isLoading: false,
      );
    } catch (e) {
      // If API fails, load from local database
      try {
        final localWorkspaces = await _localDb.getWorkspaces();
        final workspaces = localWorkspaces
            .map((lw) => Workspace(
                  id: lw.id,
                  name: lw.name,
                  path: lw.path,
                  description: lw.description,
                  createdAt: lw.createdAt,
                  isActive: lw.isActive,
                ))
            .toList();

        final localActiveWorkspace = await _localDb.getActiveWorkspace();
        final activeWorkspace = localActiveWorkspace != null
            ? Workspace(
                id: localActiveWorkspace.id,
                name: localActiveWorkspace.name,
                path: localActiveWorkspace.path,
                description: localActiveWorkspace.description,
                createdAt: localActiveWorkspace.createdAt,
                isActive: localActiveWorkspace.isActive,
              )
            : null;

        state = state.copyWith(
          workspaces: workspaces,
          activeWorkspace: activeWorkspace,
          isLoading: false,
        );
      } catch (localError) {
        state = state.copyWith(
          isLoading: false,
          error: 'API failed: $e, Local DB failed: $localError',
        );
      }
    }
  }

  Future<void> setActiveWorkspace(String id) async {
    try {
      final workspace = state.workspaces.firstWhere((w) => w.id == id);
      state = state.copyWith(activeWorkspace: workspace);
      await _storage.setString(AppConstants.workspaceIdKey, id);
      await _localDb.setActiveWorkspace(id);
      await _apiClient.setActiveWorkspace(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Workspace> createWorkspace({
    required String name,
    required String path,
    String? description,
  }) async {
    try {
      // Create via API
      final workspace = await _apiClient.createWorkspace(
        name: name,
        path: path,
        description: description,
      );

      // Save to local database
      final localWorkspace = LocalWorkspace.fromApiWorkspace(workspace);
      await _localDb.insertWorkspace(localWorkspace);

      // Update state
      state = state.copyWith(workspaces: [...state.workspaces, workspace]);
      return workspace;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateWorkspace(
    String id, {
    String? name,
    String? path,
    String? description,
    bool? isActive,
  }) async {
    try {
      // Update via API
      final updated = await _apiClient.updateWorkspace(
        id,
        name: name,
        path: path,
        description: description,
        isActive: isActive,
      );

      // Update in local database
      final localWorkspace = LocalWorkspace.fromApiWorkspace(updated);
      await _localDb.updateWorkspace(localWorkspace);

      // Update state
      final updatedWorkspaces = state.workspaces.map((w) {
        if (w.id == id) return updated;
        return w;
      }).toList();
      state = state.copyWith(
        workspaces: updatedWorkspaces,
        activeWorkspace:
            state.activeWorkspace?.id == id ? updated : state.activeWorkspace,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteWorkspace(String id) async {
    try {
      // Delete from API
      await _apiClient.deleteWorkspace(id);

      // Delete from local database
      await _localDb.deleteWorkspace(id);

      // Update state
      final updatedWorkspaces =
          state.workspaces.where((w) => w.id != id).toList();
      final newActiveWorkspace = state.activeWorkspace?.id == id
          ? (updatedWorkspaces.isNotEmpty ? updatedWorkspaces.first : null)
          : state.activeWorkspace;
      state = state.copyWith(
        workspaces: updatedWorkspaces,
        activeWorkspace: newActiveWorkspace,
      );
      if (newActiveWorkspace != null) {
        await _storage.setString(
            AppConstants.workspaceIdKey, newActiveWorkspace.id);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<Map<String, dynamic>> authorizeDirectory(String path) async {
    try {
      final result = await _apiClient.authorizeWorkspace(path);
      await loadWorkspaces();
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final workspaceProvider =
    StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(storageProvider);
  final localDb = ref.watch(localDbProvider);
  return WorkspaceNotifier(apiClient, storage, localDb);
});


// Files Provider
class FilesState {
  final List<FileItem> files;
  final FileContent? selectedFileContent;
  final String currentPath;
  final bool isLoading;
  final String? error;

  FilesState({
    this.files = const [],
    this.selectedFileContent,
    this.currentPath = '.',
    this.isLoading = false,
    this.error,
  });

  FilesState copyWith({
    List<FileItem>? files,
    FileContent? selectedFileContent,
    String? currentPath,
    bool? isLoading,
    String? error,
  }) {
    return FilesState(
      files: files ?? this.files,
      selectedFileContent: selectedFileContent,
      currentPath: currentPath ?? this.currentPath,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FilesNotifier extends StateNotifier<FilesState> {
  final ApiClient _apiClient;

  FilesNotifier(this._apiClient) : super(FilesState());

  Future<void> loadFiles({
    required String workspaceId,
    String path = '.',
    bool recursive = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null, currentPath: path);

    try {
      final files = await _apiClient.listFiles(
        workspaceId: workspaceId,
        path: path,
        recursive: recursive,
      );

      state = state.copyWith(
        files: files,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> loadFileContent({
    required String workspaceId,
    required String path,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final content = await _apiClient.getFileContent(
        workspaceId: workspaceId,
        path: path,
      );

      state = state.copyWith(
        selectedFileContent: content,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> createFile({
    required String workspaceId,
    required String path,
    String content = '',
  }) async {
    try {
      await _apiClient.createFile(
        workspaceId: workspaceId,
        path: path,
        content: content,
      );

      // Reload files in current directory
      await loadFiles(
        workspaceId: workspaceId,
        path: state.currentPath,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateFile({
    required String workspaceId,
    required String path,
    required String content,
  }) async {
    try {
      await _apiClient.updateFile(
        workspaceId: workspaceId,
        path: path,
        content: content,
      );

      // Update selected file content if it's the current file
      if (state.selectedFileContent?.path == path) {
        state = state.copyWith(
          selectedFileContent: FileContent(
            path: path,
            name: state.selectedFileContent!.name,
            content: content,
            size: content.length,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteFile({
    required String workspaceId,
    required String path,
  }) async {
    try {
      await _apiClient.deleteFile(
        workspaceId: workspaceId,
        path: path,
      );

      // Clear selected content if deleted file was selected
      if (state.selectedFileContent?.path == path) {
        state = state.copyWith(selectedFileContent: null);
      }

      // Reload files in current directory
      await loadFiles(
        workspaceId: workspaceId,
        path: state.currentPath,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setCurrentPath(String path) {
    state = state.copyWith(currentPath: path);
  }
}

final filesProvider = StateNotifierProvider<FilesNotifier, FilesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FilesNotifier(apiClient);
});
