enum PermissionStatus { pending, approved, denied }

enum PermissionResponse { allowOnce, alwaysAllow, deny }

class Permission {
  final String id;
  final String sessionId;
  final String toolName;
  final String? description;
  final PermissionStatus status;
  final PermissionResponse? response;
  final DateTime createdAt;
  final DateTime updatedAt;

  Permission({
    required this.id,
    required this.sessionId,
    required this.toolName,
    this.description,
    this.status = PermissionStatus.pending,
    this.response,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      toolName: json['tool_name'] as String,
      description: json['description'] as String?,
      status: PermissionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PermissionStatus.pending,
      ),
      response: json['response'] != null
          ? PermissionResponse.values.firstWhere(
              (e) => e.name == json['response'],
              orElse: () => PermissionResponse.deny,
            )
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'tool_name': toolName,
      'description': description,
      'status': status.name,
      'response': response?.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Permission copyWith({
    String? id,
    String? sessionId,
    String? toolName,
    String? description,
    PermissionStatus? status,
    PermissionResponse? response,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Permission(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      toolName: toolName ?? this.toolName,
      description: description ?? this.description,
      status: status ?? this.status,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Permission(id: $id, toolName: $toolName, status: $status)';
  }
}
