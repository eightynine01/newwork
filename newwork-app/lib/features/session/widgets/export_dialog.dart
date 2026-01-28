import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/export_service.dart';

/// Dialog for exporting and sharing sessions.
class ExportDialog extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;

  const ExportDialog({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  /// Show the export dialog and return true if export was successful.
  static Future<bool?> show({
    required BuildContext context,
    required String sessionId,
    required String sessionTitle,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => ExportDialog(
        sessionId: sessionId,
        sessionTitle: sessionTitle,
      ),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.markdown;
  bool _includeTodos = true;
  bool _includeArtifacts = true;
  bool _isExporting = false;
  String? _error;

  final _exportService = ExportService();

  @override
  void dispose() {
    _exportService.dispose();
    super.dispose();
  }

  Future<void> _exportToFile() async {
    setState(() {
      _isExporting = true;
      _error = null;
    });

    try {
      final filePath = await _exportService.exportToFile(
        sessionId: widget.sessionId,
        format: _selectedFormat,
        includeTodos: _includeTodos,
        includeArtifacts: _includeArtifacts,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $filePath'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isExporting = false;
      });
    }
  }

  Future<void> _shareSession() async {
    setState(() {
      _isExporting = true;
      _error = null;
    });

    try {
      await _exportService.shareSession(
        sessionId: widget.sessionId,
        format: _selectedFormat,
        title: widget.sessionTitle,
        includeTodos: _includeTodos,
        includeArtifacts: _includeArtifacts,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isExporting = false;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    setState(() {
      _isExporting = true;
      _error = null;
    });

    try {
      final content = await _exportService.getExportContent(
        sessionId: widget.sessionId,
        format: _selectedFormat,
        includeTodos: _includeTodos,
        includeArtifacts: _includeArtifacts,
      );

      await Clipboard.setData(ClipboardData(text: content));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.ios_share, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Export Session'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format selection
            Text(
              'Format',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FormatOption(
                    format: ExportFormat.markdown,
                    isSelected: _selectedFormat == ExportFormat.markdown,
                    onTap: () => setState(() => _selectedFormat = ExportFormat.markdown),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormatOption(
                    format: ExportFormat.json,
                    isSelected: _selectedFormat == ExportFormat.json,
                    onTap: () => setState(() => _selectedFormat = ExportFormat.json),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Options
            Text(
              'Options',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _includeTodos,
              onChanged: (value) => setState(() => _includeTodos = value ?? true),
              title: const Text('Include Tasks'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: _includeArtifacts,
              onChanged: (value) => setState(() => _includeArtifacts = value ?? true),
              title: const Text('Include Artifacts'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            // Error display
            if (_error != null) ...[
              const SizedBox(height: 12),
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
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton.icon(
          onPressed: _isExporting ? null : _copyToClipboard,
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy'),
        ),
        TextButton.icon(
          onPressed: _isExporting ? null : _exportToFile,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Save'),
        ),
        FilledButton.icon(
          onPressed: _isExporting ? null : _shareSession,
          icon: _isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share, size: 18),
          label: const Text('Share'),
        ),
      ],
    );
  }
}


class _FormatOption extends StatelessWidget {
  final ExportFormat format;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.format,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              format == ExportFormat.markdown
                  ? Icons.description
                  : Icons.data_object,
              size: 32,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              format.displayName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              format == ExportFormat.markdown
                  ? 'Human readable'
                  : 'Data backup',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
