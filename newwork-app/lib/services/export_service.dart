import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../core/constants.dart';

/// Supported export formats.
enum ExportFormat {
  json,
  markdown,
}

extension ExportFormatExtension on ExportFormat {
  String get extension {
    switch (this) {
      case ExportFormat.json:
        return 'json';
      case ExportFormat.markdown:
        return 'md';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.json:
        return 'application/json';
      case ExportFormat.markdown:
        return 'text/markdown';
    }
  }

  String get displayName {
    switch (this) {
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.markdown:
        return 'Markdown';
    }
  }
}

/// Service for exporting and sharing sessions.
class ExportService {
  final String baseUrl;
  final http.Client _client;

  ExportService({
    this.baseUrl = AppConstants.apiBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Export a session to the specified format.
  ///
  /// Returns the exported content as a string.
  Future<String> exportSession({
    required String sessionId,
    required ExportFormat format,
    bool includeTodos = true,
    bool includeArtifacts = true,
  }) async {
    final String endpoint;
    final Map<String, String> queryParams;

    switch (format) {
      case ExportFormat.json:
        endpoint = '${AppConstants.sessionsEndpoint}/$sessionId/export/json';
        queryParams = {'pretty': 'true'};
        break;
      case ExportFormat.markdown:
        endpoint = '${AppConstants.sessionsEndpoint}/$sessionId/export/markdown';
        queryParams = {
          'include_todos': includeTodos.toString(),
          'include_artifacts': includeArtifacts.toString(),
        };
        break;
    }

    final uri = Uri.parse('$baseUrl$endpoint')
        .replace(queryParameters: queryParams);

    final response = await _client
        .get(uri, headers: {'Accept': format.mimeType})
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200) {
      return response.body;
    }

    throw Exception('Failed to export session: ${response.statusCode}');
  }

  /// Export and save a session to a file.
  ///
  /// Returns the path to the saved file.
  Future<String> exportToFile({
    required String sessionId,
    required ExportFormat format,
    String? fileName,
    bool includeTodos = true,
    bool includeArtifacts = true,
  }) async {
    final content = await exportSession(
      sessionId: sessionId,
      format: format,
      includeTodos: includeTodos,
      includeArtifacts: includeArtifacts,
    );

    // Get save directory
    final directory = await getDownloadsDirectory() ?? await getTemporaryDirectory();

    // Generate filename
    final String finalFileName;
    if (fileName != null) {
      finalFileName = fileName;
    } else {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      finalFileName = 'session_$timestamp.${format.extension}';
    }

    final filePath = p.join(directory.path, finalFileName);
    final file = File(filePath);
    await file.writeAsString(content);

    return filePath;
  }

  /// Export and share a session using the system share dialog.
  Future<void> shareSession({
    required String sessionId,
    required ExportFormat format,
    String? title,
    bool includeTodos = true,
    bool includeArtifacts = true,
  }) async {
    final filePath = await exportToFile(
      sessionId: sessionId,
      format: format,
      includeTodos: includeTodos,
      includeArtifacts: includeArtifacts,
    );

    final file = XFile(filePath, mimeType: format.mimeType);
    await Share.shareXFiles(
      [file],
      subject: title ?? 'Session Export',
    );
  }

  /// Share session content as text (for markdown).
  Future<void> shareAsText({
    required String sessionId,
    String? title,
    bool includeTodos = true,
    bool includeArtifacts = true,
  }) async {
    final content = await exportSession(
      sessionId: sessionId,
      format: ExportFormat.markdown,
      includeTodos: includeTodos,
      includeArtifacts: includeArtifacts,
    );

    await Share.share(
      content,
      subject: title ?? 'Session Export',
    );
  }

  /// Copy export content to clipboard.
  Future<String> getExportContent({
    required String sessionId,
    required ExportFormat format,
    bool includeTodos = true,
    bool includeArtifacts = true,
  }) async {
    return exportSession(
      sessionId: sessionId,
      format: format,
      includeTodos: includeTodos,
      includeArtifacts: includeArtifacts,
    );
  }

  void dispose() {
    _client.close();
  }
}
