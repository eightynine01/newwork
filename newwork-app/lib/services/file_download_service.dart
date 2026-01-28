import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../core/constants.dart';

/// Service for downloading files and opening them with system applications.
class FileDownloadService {
  final String baseUrl;
  final http.Client _client;

  FileDownloadService({
    this.baseUrl = AppConstants.apiBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Download a file from the workspace.
  ///
  /// [workspaceId] - The workspace ID
  /// [path] - The file path relative to the workspace
  /// [onProgress] - Optional callback for download progress (0.0 to 1.0)
  ///
  /// Returns the path to the downloaded file.
  Future<String> downloadFile({
    required String workspaceId,
    required String path,
    void Function(double progress)? onProgress,
    String? destinationPath,
  }) async {
    final queryParams = {
      'workspace_id': workspaceId,
      'path': path,
    };
    final uri = Uri.parse('$baseUrl${AppConstants.filesEndpoint}/download')
        .replace(queryParameters: queryParams);

    final request = http.Request('GET', uri);
    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode != 200) {
      throw Exception('Failed to download file: ${streamedResponse.statusCode}');
    }

    // Get file name from response headers or path
    final contentDisposition = streamedResponse.headers['content-disposition'];
    String fileName = p.basename(path);
    if (contentDisposition != null) {
      // Parse filename from Content-Disposition header
      final match = RegExp(r"filename\*?=(?:UTF-8'')?([^;\s]+)").firstMatch(contentDisposition);
      if (match != null) {
        fileName = Uri.decodeComponent(match.group(1) ?? fileName);
      }
    }

    // Determine destination path
    final String savePath;
    if (destinationPath != null) {
      savePath = destinationPath;
    } else {
      final directory = await getDownloadsDirectory() ?? await getTemporaryDirectory();
      savePath = p.join(directory.path, fileName);
    }

    // Get total size for progress
    final totalBytes = streamedResponse.contentLength ?? 0;
    var receivedBytes = 0;

    // Stream file to disk
    final file = File(savePath);
    final sink = file.openWrite();

    await for (final chunk in streamedResponse.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;

      if (onProgress != null && totalBytes > 0) {
        onProgress(receivedBytes / totalBytes);
      }
    }

    await sink.close();

    return savePath;
  }

  /// Download and open a file with the system's default application.
  Future<bool> downloadAndOpenFile({
    required String workspaceId,
    required String path,
    void Function(double progress)? onProgress,
  }) async {
    final localPath = await downloadFile(
      workspaceId: workspaceId,
      path: path,
      onProgress: onProgress,
    );

    return openFile(localPath);
  }

  /// Open a local file with the system's default application.
  Future<bool> openFile(String filePath) async {
    final uri = Uri.file(filePath);

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }

    // Fallback: try opening the containing folder
    final directory = p.dirname(filePath);
    final dirUri = Uri.file(directory);

    if (await canLaunchUrl(dirUri)) {
      return launchUrl(dirUri);
    }

    return false;
  }

  /// Reveal a file in the system file manager.
  Future<bool> revealInFinder(String filePath) async {
    if (Platform.isMacOS) {
      final result = await Process.run('open', ['-R', filePath]);
      return result.exitCode == 0;
    } else if (Platform.isWindows) {
      final result = await Process.run('explorer', ['/select,', filePath]);
      return result.exitCode == 0;
    } else if (Platform.isLinux) {
      // Try xdg-open on the directory
      final directory = p.dirname(filePath);
      final result = await Process.run('xdg-open', [directory]);
      return result.exitCode == 0;
    }
    return false;
  }

  /// Get the file download URL for direct browser download.
  String getDownloadUrl({
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

  void dispose() {
    _client.close();
  }
}
