import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mcp_server.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../widgets/add_mcp_server_dialog.dart';
import '../widgets/mcp_oauth_dialog.dart';
import '../../../data/providers/dashboard_providers.dart';

class MCPTab extends ConsumerWidget {
  const MCPTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mcpState = ref.watch(mcpProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(mcpProvider.notifier).loadServers();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Servers refreshed')),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(mcpProvider.notifier).loadServers();
        },
        child: mcpState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : mcpState.error != null
                ? _buildErrorState(context, mcpState.error!, ref)
                : mcpState.servers.isEmpty
                    ? _buildEmptyState(context, ref)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: mcpState.servers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildServerCard(
                              context,
                              mcpState.servers[index],
                              ref,
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddServerDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Server'),
      ),
    );
  }

  Widget _buildServerCard(
    BuildContext context,
    MCPServer server,
    WidgetRef ref,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(server.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(server.status),
                  color: _getStatusColor(server.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      server.endpoint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (server.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        server.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'connect') {
                    _handleConnect(context, ref, server);
                  } else if (value == 'disconnect') {
                    _handleDisconnect(context, ref, server);
                  } else if (value == 'edit') {
                    _showEditServerDialog(context, ref, server);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, ref, server);
                  }
                },
                itemBuilder: (context) {
                  if (server.status == MCPServerStatus.connected) {
                    return [
                      const PopupMenuItem(
                        value: 'disconnect',
                        child: Row(
                          children: [
                            Icon(Icons.link_off, size: 18),
                            SizedBox(width: 12),
                            Text('Disconnect'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ];
                  } else {
                    return [
                      const PopupMenuItem(
                        value: 'connect',
                        child: Row(
                          children: [
                            Icon(Icons.link, size: 18),
                            SizedBox(width: 12),
                            Text('Connect'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ];
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(server.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(server.status),
                      size: 14,
                      color: _getStatusColor(server.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(server.status),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(server.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (server.availableTools.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.build_circle,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${server.availableTools.length} tools',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (server.capabilities != null)
            ExpansionTile(
              title: Text(
                'Capabilities',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              tilePadding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: server.capabilities!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key}: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No MCP servers configured',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add MCP servers to extend functionality',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Add Server',
              icon: const Icon(Icons.add),
              onPressed: () => _showAddServerDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to load MCP servers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Retry',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await ref.read(mcpProvider.notifier).loadServers();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddServerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddMcpServerDialog(),
    );
  }

  void _showEditServerDialog(
    BuildContext context,
    WidgetRef ref,
    MCPServer server,
  ) {
    // For editing, we remove and re-add the server
    // This is handled in the dialog itself
    showDialog(
      context: context,
      builder: (context) => AddMcpServerDialog(),
    );
  }

  void _handleConnect(
    BuildContext context,
    WidgetRef ref,
    MCPServer server,
  ) async {
    try {
      await ref.read(mcpProvider.notifier).connectServer(server.id);
      if (context.mounted) {
        // Check if OAuth is required
        final capabilities = server.capabilities;
        if (capabilities != null && capabilities['oauth_enabled'] == true) {
          showDialog(
            context: context,
            builder: (context) => McpOAuthDialog(
              serverName: server.name,
              oauthUrl: capabilities['oauth_url'] ?? '',
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connecting to server...')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }

  void _handleDisconnect(
    BuildContext context,
    WidgetRef ref,
    MCPServer server,
  ) async {
    try {
      await ref.read(mcpProvider.notifier).disconnectServer(server.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnected from server')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    MCPServer server,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Server'),
        content: Text(
          'Are you sure you want to delete "${server.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(mcpProvider.notifier).removeServer(server.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Server deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(MCPServerStatus status) {
    switch (status) {
      case MCPServerStatus.connected:
        return Icons.link;
      case MCPServerStatus.connecting:
        return Icons.sync;
      case MCPServerStatus.error:
        return Icons.error;
      case MCPServerStatus.disconnected:
      default:
        return Icons.link_off;
    }
  }

  Color _getStatusColor(MCPServerStatus status) {
    switch (status) {
      case MCPServerStatus.connected:
        return Colors.green;
      case MCPServerStatus.connecting:
        return Colors.orange;
      case MCPServerStatus.error:
        return Colors.red;
      case MCPServerStatus.disconnected:
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(MCPServerStatus status) {
    switch (status) {
      case MCPServerStatus.connected:
        return 'Connected';
      case MCPServerStatus.connecting:
        return 'Connecting...';
      case MCPServerStatus.error:
        return 'Error';
      case MCPServerStatus.disconnected:
      default:
        return 'Disconnected';
    }
  }
}
