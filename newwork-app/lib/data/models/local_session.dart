import 'dart:convert';

/// Local Session model for SQLite storage
///
/// This model mirrors the API Session model but is designed for
/// local SQLite storage with JSON serialization for nested objects.
class LocalSession {
  final String id;
  final String title;
  final List<Map<String, dynamic>> messages;
  final List<Map<String, dynamic>> todos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? workspaceId;

  LocalSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.todos,
    required this.createdAt,
    required this.updatedAt,
    this.workspaceId,
  });

  /// Create LocalSession from API Session model
  factory LocalSession.fromApiSession(dynamic apiSession) {
    return LocalSession(
      id: apiSession.id as String,
      title: apiSession.title as String? ?? 'Untitled Session',
      messages: (apiSession.messages as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      todos: (apiSession.todos as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      createdAt: apiSession.createdAt is DateTime
          ? apiSession.createdAt as DateTime
          : DateTime.parse(apiSession.createdAt as String),
      updatedAt: apiSession.updatedAt is DateTime
          ? apiSession.updatedAt as DateTime
          : DateTime.parse(apiSession.updatedAt as String),
      workspaceId: apiSession.workspaceId as String?,
    );
  }

  /// Create LocalSession from SQLite map
  factory LocalSession.fromMap(Map<String, dynamic> map) {
    return LocalSession(
      id: map['id'] as String,
      title: map['title'] as String,
      messages: (jsonDecode(map['messages'] as String) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      todos: (jsonDecode(map['todos'] as String) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      workspaceId: map['workspace_id'] as String?,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'messages': jsonEncode(messages),
      'todos': jsonEncode(todos),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'workspace_id': workspaceId,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages,
      'todos': todos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'workspace_id': workspaceId,
    };
  }

  /// Create a copy with updated fields
  LocalSession copyWith({
    String? id,
    String? title,
    List<Map<String, dynamic>>? messages,
    List<Map<String, dynamic>>? todos,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? workspaceId,
  }) {
    return LocalSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      todos: todos ?? this.todos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }

  @override
  String toString() {
    return 'LocalSession(id: $id, title: $title, messageCount: ${messages.length}, todoCount: ${todos.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
