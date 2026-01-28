enum MCPServerStatus { connected, disconnected, connecting, error }

class MCPServer {
  final String id;
  final String name;
  final String? description;
  final String endpoint;
  final MCPServerStatus status;
  final List<String> availableTools;
  final Map<String, dynamic>? capabilities;
  final DateTime createdAt;
  final DateTime? lastConnectedAt;

  MCPServer({
    required this.id,
    required this.name,
    this.description,
    required this.endpoint,
    this.status = MCPServerStatus.disconnected,
    this.availableTools = const [],
    this.capabilities,
    required this.createdAt,
    this.lastConnectedAt,
  });

  factory MCPServer.fromJson(Map<String, dynamic> json) {
    return MCPServer(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      endpoint: json['endpoint'] as String,
      status: MCPServerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MCPServerStatus.disconnected,
      ),
      availableTools:
          (json['available_tools'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      capabilities: json['capabilities'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastConnectedAt: json['last_connected_at'] != null
          ? DateTime.parse(json['last_connected_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'endpoint': endpoint,
      'status': status.name,
      'available_tools': availableTools,
      'capabilities': capabilities,
      'created_at': createdAt.toIso8601String(),
      'last_connected_at': lastConnectedAt?.toIso8601String(),
    };
  }

  MCPServer copyWith({
    String? id,
    String? name,
    String? description,
    String? endpoint,
    MCPServerStatus? status,
    List<String>? availableTools,
    Map<String, dynamic>? capabilities,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
  }) {
    return MCPServer(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      endpoint: endpoint ?? this.endpoint,
      status: status ?? this.status,
      availableTools: availableTools ?? this.availableTools,
      capabilities: capabilities ?? this.capabilities,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }

  @override
  String toString() {
    return 'MCPServer(id: $id, name: $name, status: $status, toolCount: ${availableTools.length})';
  }
}


/// MCP Tool model representing a tool available on an MCP server.
class MCPTool {
  final String name;
  final String? description;
  final Map<String, dynamic> inputSchema;

  MCPTool({
    required this.name,
    this.description,
    this.inputSchema = const {},
  });

  factory MCPTool.fromJson(Map<String, dynamic> json) {
    return MCPTool(
      name: json['name'] as String,
      description: json['description'] as String?,
      inputSchema: json['input_schema'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'input_schema': inputSchema,
    };
  }

  @override
  String toString() {
    return 'MCPTool(name: $name, description: $description)';
  }
}


/// MCP Health Status model for health check responses.
class MCPHealthStatus {
  final String serverName;
  final bool isHealthy;
  final String state;
  final double? latencyMs;
  final String? lastPing;
  final String? error;

  MCPHealthStatus({
    required this.serverName,
    required this.isHealthy,
    required this.state,
    this.latencyMs,
    this.lastPing,
    this.error,
  });

  factory MCPHealthStatus.fromJson(Map<String, dynamic> json) {
    return MCPHealthStatus(
      serverName: json['server_name'] as String,
      isHealthy: json['is_healthy'] as bool,
      state: json['state'] as String,
      latencyMs: (json['latency_ms'] as num?)?.toDouble(),
      lastPing: json['last_ping'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_name': serverName,
      'is_healthy': isHealthy,
      'state': state,
      'latency_ms': latencyMs,
      'last_ping': lastPing,
      'error': error,
    };
  }

  @override
  String toString() {
    return 'MCPHealthStatus(serverName: $serverName, isHealthy: $isHealthy, latencyMs: $latencyMs)';
  }
}
