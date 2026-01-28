/// Application-wide constants
class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String wsBaseUrl = 'ws://localhost:8000';

  // API Endpoints (백엔드 실제 경로에 맞춤)
  static const String healthEndpoint = '/health';
  static const String sessionsEndpoint = '/sessions';
  static const String templatesEndpoint = '/templates';
  static const String skillsEndpoint = '/skills';
  static const String workspacesEndpoint = '/workspaces';
  static const String pluginsEndpoint = '/plugins';
  static const String mcpEndpoint = '/mcp';
  static const String permissionsEndpoint = '/permissions';
  static const String providersEndpoint = '/providers';
  static const String filesEndpoint = '/api/v1/files';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String workspaceIdKey = 'workspace_id';
  static const String userIdKey = 'user_id';
  static const String firstLaunchKey = 'first_launch';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration wsTimeout = Duration(seconds: 60);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration defaultAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
}
