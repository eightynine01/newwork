enum MessageRole { user, assistant, system }

enum MessageType { text, code, error, thinking, toolCall, toolResult }

class Message {
  final String id;
  final String sessionId;
  final MessageRole role;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final String? toolName;
  final Map<String, dynamic>? toolData;
  final String? metadata;

  Message({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.type = MessageType.text,
    required this.createdAt,
    this.toolName,
    this.toolData,
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      toolName: json['tool_name'] as String?,
      toolData: json['tool_data'] as Map<String, dynamic>?,
      metadata: json['metadata'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'role': role.name,
      'content': content,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'tool_name': toolName,
      'tool_data': toolData,
      'metadata': metadata,
    };
  }

  Message copyWith({
    String? id,
    String? sessionId,
    MessageRole? role,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    String? toolName,
    Map<String, dynamic>? toolData,
    String? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      toolName: toolName ?? this.toolName,
      toolData: toolData ?? this.toolData,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, role: $role, type: $type, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }
}
