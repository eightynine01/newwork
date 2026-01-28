import 'package:flutter/material.dart';

/// Dialog showing download progress with cancel option.
class DownloadProgressDialog extends StatefulWidget {
  final String fileName;
  final Future<String> Function(void Function(double) onProgress) downloadTask;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const DownloadProgressDialog({
    super.key,
    required this.fileName,
    required this.downloadTask,
    this.onComplete,
    this.onCancel,
  });

  /// Show the download dialog and return the downloaded file path, or null if cancelled.
  static Future<String?> show({
    required BuildContext context,
    required String fileName,
    required Future<String> Function(void Function(double) onProgress) downloadTask,
    VoidCallback? onComplete,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DownloadProgressDialog(
        fileName: fileName,
        downloadTask: downloadTask,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0.0;
  bool _isDownloading = true;
  bool _isCancelled = false;
  String? _error;
  String? _downloadedPath;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      _downloadedPath = await widget.downloadTask((progress) {
        if (!_isCancelled && mounted) {
          setState(() {
            _progress = progress;
          });
        }
      });

      if (!_isCancelled && mounted) {
        setState(() {
          _isDownloading = false;
        });
        widget.onComplete?.call();

        // Auto-close after brief delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(_downloadedPath);
        }
      }
    } catch (e) {
      if (!_isCancelled && mounted) {
        setState(() {
          _isDownloading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _cancel() {
    _isCancelled = true;
    widget.onCancel?.call();
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _error != null
                ? Icons.error_outline
                : _isDownloading
                    ? Icons.download_rounded
                    : Icons.check_circle_outline,
            color: _error != null
                ? colorScheme.error
                : _isDownloading
                    ? colorScheme.primary
                    : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error != null
                  ? 'Download Failed'
                  : _isDownloading
                      ? 'Downloading...'
                      : 'Download Complete',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.fileName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _isDownloading ? _progress : 1.0,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isDownloading
                  ? '${(_progress * 100).toStringAsFixed(0)}%'
                  : 'File saved successfully',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_isDownloading)
          TextButton(
            onPressed: _cancel,
            child: const Text('Cancel'),
          )
        else if (_error != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Close'),
          ),
      ],
    );
  }
}


/// Shows a simple snackbar for quick download feedback.
void showDownloadSnackbar({
  required BuildContext context,
  required String fileName,
  required bool success,
  String? filePath,
  VoidCallback? onOpen,
  VoidCallback? onReveal,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              success
                  ? 'Downloaded: $fileName'
                  : 'Failed to download: $fileName',
            ),
          ),
        ],
      ),
      action: success && (onOpen != null || onReveal != null)
          ? SnackBarAction(
              label: 'Open',
              onPressed: onOpen ?? onReveal ?? () {},
            )
          : null,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
