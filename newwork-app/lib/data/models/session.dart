import 'message.dart';
import 'todo.dart';

class Session {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Message> messages;
  final List<Todo> todos;
  final String? summary;
  final List<String> tags;
  final bool isPinned;
  final String? projectId;
  final String? workspaceId;
  final int messageCount;
  final int todoCount;

  Session({
    required this.id,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
    this.todos = const [],
    this.summary,
    this.tags = const [],
    this.isPinned = false,
    this.projectId,
    this.workspaceId,
    this.messageCount = 0,
    this.todoCount = 0,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled Session',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      todos:
          (json['todos'] as List<dynamic>?)
              ?.map((e) => Todo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      isPinned: json['is_pinned'] as bool? ?? false,
      projectId: json['project_id'] as String?,
      workspaceId: json['workspace_id'] as String?,
      messageCount: json['message_count'] as int? ?? 0,
      todoCount: json['todo_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'messages': messages.map((e) => e.toJson()).toList(),
      'todos': todos.map((e) => e.toJson()).toList(),
      'summary': summary,
      'tags': tags,
      'is_pinned': isPinned,
      'project_id': projectId,
      'workspace_id': workspaceId,
      'message_count': messageCount,
      'todo_count': todoCount,
    };
  }

  Session copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Message>? messages,
    List<Todo>? todos,
    String? summary,
    List<String>? tags,
    bool? isPinned,
    String? projectId,
    String? workspaceId,
    int? messageCount,
    int? todoCount,
  }) {
    return Session(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      todos: todos ?? this.todos,
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      projectId: projectId ?? this.projectId,
      workspaceId: workspaceId ?? this.workspaceId,
      messageCount: messageCount ?? this.messageCount,
      todoCount: todoCount ?? this.todoCount,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, title: $title, createdAt: $createdAt, messageCount: $messageCount)';
  }
}
