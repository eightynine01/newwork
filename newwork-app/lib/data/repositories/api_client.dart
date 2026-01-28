import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/session.dart';
import '../models/message.dart';
import '../models/template.dart';
import '../models/skill.dart';
import '../models/workspace.dart';
import '../models/permission.dart';
import '../models/plugin.dart';
import '../models/mcp_server.dart';
import '../models/ai_provider.dart';
import '../models/file_item.dart';
import '../../core/constants.dart';
import '../../core/error/app_error.dart';
import '../../core/error/retry_policy.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final RetryPolicy _retryPolicy;
  final RetryExecutor _retryExecutor;

  /// API 오류 발생 시 호출되는 콜백
  void Function(AppError error)? onError;

  /// 재시도 시 호출되는 콜백
  void Function(int attempt, Object error, Duration delay)? onRetry;

  ApiClient({
    this.baseUrl = AppConstants.apiBaseUrl,
    http.Client? client,
    RetryPolicy? retryPolicy,
    this.onError,
    this.onRetry,
  })  : _client = client ?? http.Client(),
        _retryPolicy = retryPolicy ?? RetryPolicy.api,
        _retryExecutor = RetryExecutor(retryPolicy ?? RetryPolicy.api);

  /// 재시도 가능한 오류인지 확인
  bool _shouldRetry(Object error) {
    // 타임아웃 오류
    if (error is TimeoutException) return true;
    // 소켓 오류 (네트워크 문제)
    if (error is SocketException) return true;
    // HTTP 오류
    if (error is http.ClientException) return true;
    // API 예외 (5xx 오류만 재시도)
    if (error is ApiException) {
      final statusCode = error.statusCode;
      if (statusCode == null) return true;
      return statusCode >= 500 || statusCode == 408;
    }
    return false;
  }

  /// 재시도 로직이 포함된 HTTP 요청 실행
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    bool enableRetry = true,
  }) async {
    if (!enableRetry) {
      return operation();
    }

    try {
      return await _retryExecutor.execute(
        operation,
        shouldRetry: _shouldRetry,
        onRetry: (attempt, error, delay) {
          print('[ApiClient] 재시도 $attempt/${_retryPolicy.maxRetries}: $error');
          print('[ApiClient] ${delay.inMilliseconds}ms 후 재시도...');
          onRetry?.call(attempt, error, delay);
        },
      );
    } catch (e, st) {
      final appError = _createAppError(e, st);
      onError?.call(appError);
      rethrow;
    }
  }

  /// 예외를 AppError로 변환
  AppError _createAppError(Object error, StackTrace stackTrace) {
    if (error is ApiException) {
      return error.toAppError();
    }
    if (error is TimeoutException) {
      return AppError.api(
        message: '요청 시간이 초과되었습니다',
        statusCode: 408,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    if (error is SocketException) {
      return AppError.api(
        message: '네트워크 연결에 실패했습니다',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    return AppError.api(
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// HTTP 응답 검증 및 예외 처리
  void _validateResponse(http.Response response, {String? context}) {
    if (response.statusCode >= 400) {
      String message = context ?? 'API 요청 실패';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('detail')) {
          message = body['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(
        message,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  // Health Check
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl${AppConstants.healthEndpoint}'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 상세 헬스 상태 확인 (연결 정보 포함)
  Future<HealthStatus> getHealthStatus() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl${AppConstants.healthEndpoint}'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return HealthStatus(
          isHealthy: true,
          latencyMs: 0, // TODO: 실제 latency 측정
          message: data['status'] ?? 'ok',
          timestamp: DateTime.now(),
        );
      }
      return HealthStatus(
        isHealthy: false,
        message: 'HTTP ${response.statusCode}',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return HealthStatus(
        isHealthy: false,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  // Sessions
  Future<List<Session>> getSessions() async {
    return _executeWithRetry(() async {
      final response = await _client
          .get(Uri.parse('$baseUrl${AppConstants.sessionsEndpoint}'), headers: _headers)
          .timeout(AppConstants.apiTimeout);

      _validateResponse(response, context: '세션 목록 조회 실패');

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => Session.fromJson(e)).toList();
      }
      return [];
    });
  }

  Future<Session> createSession({
    required String title,
    String? templateId,
  }) async {
    return _executeWithRetry(() async {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${AppConstants.sessionsEndpoint}'),
            headers: _headers,
            body: jsonEncode({
              'title': title,
              if (templateId != null) 'template_id': templateId,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      _validateResponse(response, context: '세션 생성 실패');

      if (response.statusCode == 201) {
        return Session.fromJson(jsonDecode(response.body));
      }
      throw ApiException('세션 생성 실패', statusCode: response.statusCode);
    });
  }

  Future<Session> getSession(String id) async {
    return _executeWithRetry(() async {
      final response = await _client
          .get(Uri.parse('$baseUrl${AppConstants.sessionsEndpoint}/$id'), headers: _headers)
          .timeout(AppConstants.apiTimeout);

      _validateResponse(response, context: '세션 조회 실패');

      if (response.statusCode == 200) {
        return Session.fromJson(jsonDecode(response.body));
      }
      throw ApiException('세션 조회 실패', statusCode: response.statusCode);
    });
  }

  Future<void> updateSession(String id, Map<String, dynamic> data) async {
    final response = await _client
        .patch(
          Uri.parse('$baseUrl${AppConstants.sessionsEndpoint}/$id'),
          headers: _headers,
          body: jsonEncode(data),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to update session: ${response.statusCode}');
    }
  }

  Future<void> deleteSession(String id) async {
    final response = await _client
        .delete(
          Uri.parse('$baseUrl${AppConstants.sessionsEndpoint}/$id'),
          headers: _headers,
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete session: ${response.statusCode}');
    }
  }

  Future<Message> sendPrompt({
    required String sessionId,
    required String model,
    required String prompt,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.sessionsEndpoint}/$sessionId/messages'),
          headers: _headers,
          body: jsonEncode({'model': model, 'content': prompt}),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 201) {
      return Message.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to send prompt: ${response.statusCode}');
  }

  // Templates
  Future<List<Template>> getTemplates({String? scope}) async {
    try {
      final queryParams =
          scope != null ? <String, String>{'scope': scope} : <String, String>{};
      final uri = Uri.parse('$baseUrl${AppConstants.templatesEndpoint}')
          .replace(queryParameters: queryParams);
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => Template.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
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
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.templatesEndpoint}'),
          headers: _headers,
          body: jsonEncode({
            'name': name,
            'description': description,
            'content': systemPrompt,
            if (skills != null && skills.isNotEmpty) 'skills': skills,
            if (scope != null) 'scope': scope,
            if (parameters != null) 'parameters': parameters,
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 201) {
      return Template.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create template: ${response.statusCode}');
  }

  Future<Template> getTemplate(String id) async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.templatesEndpoint}/$id'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return Template.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get template: ${response.statusCode}');
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
    final response = await _client
        .put(
          Uri.parse('$baseUrl${AppConstants.templatesEndpoint}/$id'),
          headers: _headers,
          body: jsonEncode({
            if (name != null) 'name': name,
            if (description != null) 'description': description,
            if (systemPrompt != null) 'content': systemPrompt,
            if (skills != null) 'skills': skills,
            if (scope != null) 'scope': scope,
            if (parameters != null) 'parameters': parameters,
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return Template.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update template: ${response.statusCode}');
  }

  Future<void> deleteTemplate(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl${AppConstants.templatesEndpoint}/$id'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete template: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> runTemplate(
    String id, {
    Map<String, dynamic>? variables,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.templatesEndpoint}/$id/run'),
          headers: _headers,
          body: jsonEncode({
            'variables': variables ?? {},
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to run template: ${response.statusCode}');
  }

  // Skills
  Future<List<Skill>> getSkills() async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.skillsEndpoint}'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Skill.fromJson(e)).toList();
    }
    return [];
  }

  Future<Skill> getSkill(String id) async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.skillsEndpoint}/$id'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return Skill.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get skill: ${response.statusCode}');
  }

  Future<void> installSkill(String skillName) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.skillsEndpoint}/install'),
          headers: _headers,
          body: jsonEncode({'skill_name': skillName}),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to install skill');
    }
  }

  Future<void> importSkill({
    required String sourcePath,
    String? skillName,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.skillsEndpoint}/import'),
          headers: _headers,
          body: jsonEncode({
            'source_path': sourcePath,
            if (skillName != null) 'skill_name': skillName,
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to import skill');
    }
  }

  Future<void> uninstallSkill(String skillName) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl${AppConstants.skillsEndpoint}/$skillName'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to uninstall skill');
    }
  }

  Future<void> revealSkillsFolder() async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.skillsEndpoint}/reveal'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to reveal skills folder');
    }
  }

  // Workspaces
  Future<List<Workspace>> getWorkspaces() async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.workspacesEndpoint}'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Workspace.fromJson(e)).toList();
    }
    return [];
  }

  Future<Workspace> createWorkspace({
    required String name,
    required String path,
    String? description,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.workspacesEndpoint}'),
          headers: _headers,
          body: jsonEncode({
            'name': name,
            'path': path,
            if (description != null) 'description': description,
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 201) {
      return Workspace.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create workspace: ${response.statusCode}');
  }

  Future<Workspace> getWorkspace(String id) async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.workspacesEndpoint}/$id'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return Workspace.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get workspace: ${response.statusCode}');
  }

  Future<Workspace> updateWorkspace(
    String id, {
    String? name,
    String? path,
    String? description,
    bool? isActive,
  }) async {
    final response = await _client
        .put(
          Uri.parse('$baseUrl${AppConstants.workspacesEndpoint}/$id'),
          headers: _headers,
          body: jsonEncode({
            if (name != null) 'name': name,
            if (path != null) 'path': path,
            if (description != null) 'description': description,
            if (isActive != null) 'is_active': isActive,
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return Workspace.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update workspace: ${response.statusCode}');
  }

  Future<void> deleteWorkspace(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl${AppConstants.workspacesEndpoint}/$id'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete workspace: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> authorizeWorkspace(String path) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.workspacesEndpoint}/authorize'),
          headers: _headers,
          body: jsonEncode({'path': path}),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to authorize workspace: ${response.statusCode}');
  }

  Future<Workspace?> getActiveWorkspace() async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.workspacesEndpoint}/active'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return Workspace.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<void> setActiveWorkspace(String id) async {
    await updateWorkspace(id, isActive: true);
  }

  // Permissions
  Future<List<Permission>> getPendingPermissions() async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.permissionsEndpoint}/pending'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Permission.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Permission>> getPendingPermissionsForSession(
      String sessionId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.permissionsEndpoint}/session/$sessionId'),
            headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Permission.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> respondPermission(String id, String response) async {
    final responsePayload = jsonEncode({'reply': response});
    final httpResponse = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.permissionsEndpoint}/$id/respond'),
          headers: _headers,
          body: responsePayload,
        )
        .timeout(AppConstants.apiTimeout);

    if (httpResponse.statusCode != 200) {
      throw Exception(
          'Failed to respond to permission: ${httpResponse.statusCode}');
    }
  }

  Future<List<Permission>> getPermissionHistory() async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.permissionsEndpoint}/history'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Permission.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Permission>> getPermissionHistoryForSession(
      String sessionId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl${AppConstants.permissionsEndpoint}/session/$sessionId'),
            headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Permission.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> clearPermissionHistory() async {
    final response = await _client
        .delete(Uri.parse('$baseUrl${AppConstants.permissionsEndpoint}/history'),
            headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 204) {
      throw Exception('Failed to clear permission history');
    }
  }

  // Session Events (SSE endpoint URL)
  String getSessionEventsUrl(String sessionId) {
    return '$baseUrl${AppConstants.sessionsEndpoint}/$sessionId/events';
  }

  // Session Artifacts
  Future<List<dynamic>> getSessionArtifacts(String sessionId) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl${AppConstants.sessionsEndpoint}/$sessionId/artifacts'),
          headers: _headers,
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return [];
  }

  // Plugins
  Future<List<Plugin>> getPlugins({PluginScope? scope}) async {
    try {
      final queryParams = scope != null
          ? <String, String>{'scope': scope.name}
          : <String, String>{};
      final uri = Uri.parse(
        '$baseUrl${AppConstants.pluginsEndpoint}',
      ).replace(queryParameters: queryParams);
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => Plugin.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Plugin> addPlugin({
    required String name,
    PluginScope? scope,
    Map<String, dynamic>? config,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.pluginsEndpoint}'),
          headers: _headers,
          body: jsonEncode({
            'name': name,
            if (scope != null) 'scope': scope.name,
            if (config != null) 'config': config,
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 201) {
      return Plugin.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to add plugin');
  }

  Future<void> removePlugin(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl${AppConstants.pluginsEndpoint}/$id'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 204) {
      throw Exception('Failed to remove plugin');
    }
  }

  Future<void> updatePlugin(String id, Map<String, dynamic> data) async {
    final response = await _client
        .patch(
          Uri.parse('$baseUrl${AppConstants.pluginsEndpoint}/$id'),
          headers: _headers,
          body: jsonEncode(data),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to update plugin');
    }
  }

  // MCP Servers
  Future<List<MCPServer>> getMcpServers() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl${AppConstants.mcpEndpoint}/servers'), headers: _headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => MCPServer.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<MCPServer> addMcpServer({
    required String name,
    required String endpoint,
    String? description,
    Map<String, dynamic>? config,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.mcpEndpoint}/servers'),
          headers: _headers,
          body: jsonEncode({
            'name': name,
            'endpoint': endpoint,
            if (description != null) 'description': description,
            if (config != null) 'config': config,
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 201) {
      return MCPServer.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to add MCP server');
  }

  Future<void> removeMcpServer(String id) async {
    final response = await _client
        .delete(Uri.parse('$baseUrl${AppConstants.mcpEndpoint}/servers/$id'), headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 204) {
      throw Exception('Failed to remove MCP server');
    }
  }

  Future<void> connectMcpServer(String id) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.mcpEndpoint}/servers/$id/connect'),
          headers: _headers,
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to connect MCP server');
    }
  }

  Future<void> disconnectMcpServer(String id) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.mcpEndpoint}/servers/$id/disconnect'),
          headers: _headers,
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to disconnect MCP server');
    }
  }

  Future<MCPServer> getMcpServerStatus(String id) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl${AppConstants.mcpEndpoint}/servers/$id/status'),
          headers: _headers,
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return MCPServer.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get MCP server status');
  }

  Future<List<MCPTool>> getMcpServerTools(String id, {bool refresh = false}) async {
    final queryParams = refresh ? {'refresh': 'true'} : <String, String>{};
    final uri = Uri.parse('$baseUrl${AppConstants.mcpEndpoint}/servers/$id/tools')
        .replace(queryParameters: queryParams);

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final toolsList = json['tools'] as List<dynamic>;
      return toolsList.map((e) => MCPTool.fromJson(e)).toList();
    }
    throw Exception('Failed to get MCP server tools');
  }

  Future<MCPHealthStatus> getMcpServerHealth(String id) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl${AppConstants.mcpEndpoint}/servers/$id/health'),
          headers: _headers,
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return MCPHealthStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get MCP server health');
  }

  // AI Providers and Models
  Future<List<AIProvider>> getProviders() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl${AppConstants.providersEndpoint}'), headers: _headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => AIProvider.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<AIModel>> getModels({String? providerId}) async {
    try {
      final queryParams = providerId != null
          ? <String, String>{'provider_id': providerId}
          : <String, String>{};
      final uri = Uri.parse(
        '$baseUrl${AppConstants.providersEndpoint}/models',
      ).replace(queryParameters: queryParams);
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((e) => AIModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> setDefaultModel(String modelId) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl${AppConstants.providersEndpoint}/default-model'),
          headers: _headers,
          body: jsonEncode({'model_id': modelId}),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to set default model');
    }
  }

  Future<Map<String, dynamic>> getDefaultModel() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${AppConstants.providersEndpoint}/default'),
            headers: _headers,
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Files API
  Future<List<FileItem>> listFiles({
    required String workspaceId,
    String path = '.',
    bool recursive = false,
  }) async {
    try {
      final queryParams = {
        'workspace_id': workspaceId,
        'path': path,
        'recursive': recursive.toString(),
      };
      final uri = Uri.parse('$baseUrl${AppConstants.filesEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final filesList = json['files'] as List<dynamic>;
        return filesList.map((e) => FileItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<FileContent> getFileContent({
    required String workspaceId,
    required String path,
  }) async {
    final queryParams = {
      'workspace_id': workspaceId,
      'path': path,
    };
    final uri = Uri.parse('$baseUrl${AppConstants.filesEndpoint}/content')
        .replace(queryParameters: queryParams);

    final response = await _client
        .get(uri, headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return FileContent.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get file content: ${response.statusCode}');
  }

  Future<void> createFile({
    required String workspaceId,
    required String path,
    String content = '',
  }) async {
    final queryParams = {'workspace_id': workspaceId};
    final uri = Uri.parse('$baseUrl${AppConstants.filesEndpoint}')
        .replace(queryParameters: queryParams);

    final response = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'path': path,
            'content': content,
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 201) {
      throw Exception('Failed to create file: ${response.statusCode}');
    }
  }

  Future<void> updateFile({
    required String workspaceId,
    required String path,
    required String content,
  }) async {
    final queryParams = {
      'workspace_id': workspaceId,
      'path': path,
    };
    final uri = Uri.parse('$baseUrl${AppConstants.filesEndpoint}')
        .replace(queryParameters: queryParams);

    final response = await _client
        .put(
          uri,
          headers: _headers,
          body: jsonEncode({
            'content': content,
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to update file: ${response.statusCode}');
    }
  }

  Future<void> deleteFile({
    required String workspaceId,
    required String path,
  }) async {
    final queryParams = {
      'workspace_id': workspaceId,
      'path': path,
    };
    final uri = Uri.parse('$baseUrl${AppConstants.filesEndpoint}')
        .replace(queryParameters: queryParams);

    final response = await _client
        .delete(uri, headers: _headers)
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete file: ${response.statusCode}');
    }
  }

  /// Get the URL for downloading a file.
  String getFileDownloadUrl({
    required String workspaceId,
    required String path,
  }) {
    final queryParams = {
      'workspace_id': workspaceId,
      'path': path,
    };
    return Uri.parse('$baseUrl${AppConstants.filesEndpoint}/download')
        .replace(queryParameters: queryParams)
        .toString();
  }

  // Helper methods
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $token',
      };

  void dispose() {
    _client.close();
  }
}

/// 헬스 상태 모델
class HealthStatus {
  final bool isHealthy;
  final int? latencyMs;
  final String? message;
  final DateTime timestamp;

  HealthStatus({
    required this.isHealthy,
    this.latencyMs,
    this.message,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'HealthStatus{isHealthy: $isHealthy, latencyMs: $latencyMs, message: $message}';
  }
}
