class Workspace {
  final String id;
  final String name;
  final String? description;
  final String path;
  final DateTime createdAt;
  final DateTime? lastAccessedAt;
  final int sessionCount;
  final int templateCount;
  final bool isActive;

  Workspace({
    required this.id,
    required this.name,
    this.description,
    required this.path,
    required this.createdAt,
    this.lastAccessedAt,
    this.sessionCount = 0,
    this.templateCount = 0,
    this.isActive = false,
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      path: json['path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(json['last_accessed_at'] as String)
          : null,
      sessionCount: json['session_count'] as int? ?? 0,
      templateCount: json['template_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'path': path,
      'created_at': createdAt.toIso8601String(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'session_count': sessionCount,
      'template_count': templateCount,
      'is_active': isActive,
    };
  }

  Workspace copyWith({
    String? id,
    String? name,
    String? description,
    String? path,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    int? sessionCount,
    int? templateCount,
    bool? isActive,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      sessionCount: sessionCount ?? this.sessionCount,
      templateCount: templateCount ?? this.templateCount,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Workspace(id: $id, name: $name, path: $path, isActive: $isActive)';
  }
}
