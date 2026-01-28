import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/permission.dart';
import '../../session/providers/session_provider.dart';
import '../../../shared/widgets/app_card.dart';

class PermissionHistoryList extends ConsumerStatefulWidget {
  final String sessionId;

  const PermissionHistoryList({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<PermissionHistoryList> createState() =>
      _PermissionHistoryListState();
}

class _PermissionHistoryListState extends ConsumerState<PermissionHistoryList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PermissionStatus? _filterStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(permissionHistoryProvider(widget.sessionId));
    final filteredHistory = _filterPermissions(history);

    return Column(
      children: [
        _buildSearchBar(),
        _buildFilterChips(),
        const SizedBox(height: 16),
        Expanded(
          child: filteredHistory.isEmpty
              ? _buildEmptyState()
              : _buildPermissionList(filteredHistory),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search permissions...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _filterStatus == null,
            onSelected: (selected) {
              setState(() => _filterStatus = null);
            },
          ),
          FilterChip(
            label: const Text('Pending'),
            selected: _filterStatus == PermissionStatus.pending,
            onSelected: (selected) {
              setState(() => _filterStatus = PermissionStatus.pending);
            },
          ),
          FilterChip(
            label: const Text('Approved'),
            selected: _filterStatus == PermissionStatus.approved,
            onSelected: (selected) {
              setState(() => _filterStatus = PermissionStatus.approved);
            },
          ),
          FilterChip(
            label: const Text('Denied'),
            selected: _filterStatus == PermissionStatus.denied,
            onSelected: (selected) {
              setState(() => _filterStatus = PermissionStatus.denied);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionList(List<Permission> permissions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: permissions.length,
      itemBuilder: (context, index) {
        final permission = permissions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPermissionCard(permission),
        );
      },
    );
  }

  Widget _buildPermissionCard(Permission permission) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(permission.status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(permission.status),
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(permission.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(permission.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.build,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  permission.toolName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (permission.description != null &&
              permission.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              permission.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (permission.response != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  _getResponseText(permission.response!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No permission history',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Permissions you respond to will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  List<Permission> _filterPermissions(List<Permission> permissions) {
    var filtered = permissions;

    // Apply status filter
    if (_filterStatus != null) {
      filtered = filtered.where((p) => p.status == _filterStatus).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.toolName.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.pending:
        return Colors.orange;
      case PermissionStatus.approved:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.pending:
        return Icons.pending;
      case PermissionStatus.approved:
        return Icons.check_circle;
      case PermissionStatus.denied:
        return Icons.cancel;
    }
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.pending:
        return 'Pending';
      case PermissionStatus.approved:
        return 'Approved';
      case PermissionStatus.denied:
        return 'Denied';
    }
  }

  String _getResponseText(PermissionResponse response) {
    switch (response) {
      case PermissionResponse.allowOnce:
        return 'Allowed once';
      case PermissionResponse.alwaysAllow:
        return 'Always allowed';
      case PermissionResponse.deny:
        return 'Denied';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
