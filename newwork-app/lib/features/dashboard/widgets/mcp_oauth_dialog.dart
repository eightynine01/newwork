import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/providers/dashboard_providers.dart';
import '../../../data/models/mcp_server.dart';

class McpOAuthDialog extends ConsumerStatefulWidget {
  final String serverName;
  final String oauthUrl;
  final String? state;
  final int? expiresInMinutes;

  const McpOAuthDialog({
    super.key,
    required this.serverName,
    required this.oauthUrl,
    this.state,
    this.expiresInMinutes,
  });

  @override
  ConsumerState<McpOAuthDialog> createState() => _McpOAuthDialogState();
}

class _McpOAuthDialogState extends ConsumerState<McpOAuthDialog> {
  bool _isPolling = false;
  bool _isAuthorized = false;
  bool _isBrowserOpened = false;
  String? _error;
  int _pollCount = 0;
  static const int _maxPollCount = 120; // 6 minutes at 3-second intervals

  @override
  void initState() {
    super.initState();
    _openBrowser();
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  Future<void> _openBrowser() async {
    try {
      final uri = Uri.parse(widget.oauthUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        setState(() {
          _isBrowserOpened = true;
        });
        _startPolling();
      } else {
        setState(() {
          _error = 'Could not open browser. Please copy the URL manually.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error opening browser: $e';
      });
    }
  }

  Future<void> _startPolling() async {
    if (_isPolling) return;
    _isPolling = true;
    _pollCount = 0;

    while (_isPolling && _pollCount < _maxPollCount) {
      await Future.delayed(const Duration(seconds: 3));
      _pollCount++;

      if (!mounted) break;

      try {
        // Refresh server status from API
        await ref.read(mcpProvider.notifier).refreshStatus(widget.serverName);

        // Check if server is now authorized
        final mcpState = ref.read(mcpProvider);
        final server = mcpState.servers
            .where((s) => s.id == widget.serverName)
            .firstOrNull;

        if (server != null && server.status == MCPServerStatus.connected) {
          _isAuthorized = true;
          _isPolling = false;
          if (mounted) {
            Navigator.of(context).pop(true);
          }
          break;
        }

        // Check for error state
        if (server != null && server.status == MCPServerStatus.error) {
          setState(() {
            _error = 'Authorization failed. Please try again.';
            _isPolling = false;
          });
          break;
        }
      } catch (e) {
        // Continue polling on transient errors
        continue;
      }
    }

    // Timeout handling
    if (_pollCount >= _maxPollCount && mounted && !_isAuthorized) {
      setState(() {
        _error = 'Authorization timed out. Please try again.';
        _isPolling = false;
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
          Icon(
            _error != null ? Icons.error_outline : Icons.lock_outline,
            color: _error != null ? colorScheme.error : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(_error != null ? 'Authorization Failed' : 'OAuth Authorization'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Text(
                'Connecting to "${widget.serverName}" requires OAuth authorization.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Status indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (_isPolling) ...[
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isBrowserOpened
                                  ? 'Waiting for authorization...'
                                  : 'Opening browser...',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete the login in your browser',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_isAuthorized) ...[
                      Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Authorization successful!',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (widget.expiresInMinutes != null) ...[
                const SizedBox(height: 12),
                Text(
                  'This authorization link expires in ${widget.expiresInMinutes} minutes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),

            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyOAuthUrl(context),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy URL'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _error != null ? _openBrowser : null,
                    icon: const Icon(Icons.open_in_browser, size: 18),
                    label: const Text('Open Browser'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        if (_error != null)
          FilledButton(
            onPressed: () {
              setState(() {
                _error = null;
                _pollCount = 0;
              });
              _openBrowser();
            },
            child: const Text('Try Again'),
          ),
      ],
    );
  }

  void _copyOAuthUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.oauthUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OAuth URL copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
