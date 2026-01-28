enum TodoStatus { pending, inProgress, completed, cancelled }

enum TodoPriority { high, medium, low }

class Todo {
  final String id;
  final String sessionId;
  final String title;
  final String? description;
  final TodoStatus status;
  final TodoPriority priority;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? assignee;
  final List<String> tags;

  Todo({
    required this.id,
    required this.sessionId,
    required this.title,
    this.description,
    this.status = TodoStatus.pending,
    this.priority = TodoPriority.medium,
    required this.createdAt,
    this.completedAt,
    this.assignee,
    this.tags = const [],
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TodoStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TodoStatus.pending,
      ),
      priority: TodoPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TodoPriority.medium,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      assignee: json['assignee'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'assignee': assignee,
      'tags': tags,
    };
  }

  Todo copyWith({
    String? id,
    String? sessionId,
    String? title,
    String? description,
    TodoStatus? status,
    TodoPriority? priority,
    DateTime? createdAt,
    DateTime? completedAt,
    String? assignee,
    List<String>? tags,
  }) {
    return Todo(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      assignee: assignee ?? this.assignee,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, status: $status, priority: $priority)';
  }
}
