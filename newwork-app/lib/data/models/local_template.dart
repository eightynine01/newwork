import 'dart:convert';

/// Local Template model for SQLite storage
///
/// This model mirrors the API Template model but is designed for
/// local SQLite storage with JSON serialization for nested objects.
class LocalTemplate {
  final String id;
  final String title;
  final String? description;
  final String prompt;
  final String scope; // 'workspace' or 'global'
  final List<String>? skills;
  final DateTime createdAt;
  final String? workspaceId;

  LocalTemplate({
    required this.id,
    required this.title,
    this.description,
    required this.prompt,
    required this.scope,
    this.skills,
    required this.createdAt,
    this.workspaceId,
  });

  /// Create LocalTemplate from API Template model
  factory LocalTemplate.fromApiTemplate(dynamic apiTemplate) {
    return LocalTemplate(
      id: apiTemplate.id as String,
      title: apiTemplate.title as String? ??
          apiTemplate.name as String? ??
          'Untitled Template',
      description: apiTemplate.description as String?,
      prompt:
          apiTemplate.prompt as String? ?? apiTemplate.content as String? ?? '',
      scope: apiTemplate.scope as String? ?? 'workspace',
      skills: apiTemplate.skills != null
          ? (apiTemplate.skills as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : null,
      createdAt: apiTemplate.createdAt is DateTime
          ? apiTemplate.createdAt as DateTime
          : DateTime.parse(apiTemplate.createdAt as String),
      workspaceId: apiTemplate.workspaceId as String?,
    );
  }

  /// Create LocalTemplate from SQLite map
  factory LocalTemplate.fromMap(Map<String, dynamic> map) {
    return LocalTemplate(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      prompt: map['prompt'] as String,
      scope: map['scope'] as String,
      skills: map['skills'] != null
          ? (jsonDecode(map['skills'] as String) as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      workspaceId: map['workspace_id'] as String?,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'prompt': prompt,
      'scope': scope,
      'skills': skills != null ? jsonEncode(skills) : null,
      'created_at': createdAt.millisecondsSinceEpoch,
      'workspace_id': workspaceId,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'prompt': prompt,
      'scope': scope,
      'skills': skills,
      'created_at': createdAt.toIso8601String(),
      'workspace_id': workspaceId,
    };
  }

  /// Create a copy with updated fields
  LocalTemplate copyWith({
    String? id,
    String? title,
    String? description,
    String? prompt,
    String? scope,
    List<String>? skills,
    DateTime? createdAt,
    String? workspaceId,
  }) {
    return LocalTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      prompt: prompt ?? this.prompt,
      scope: scope ?? this.scope,
      skills: skills ?? this.skills,
      createdAt: createdAt ?? this.createdAt,
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }

  /// Check if this is a workspace template
  bool get isWorkspaceTemplate => scope == 'workspace';

  /// Check if this is a global template
  bool get isGlobalTemplate => scope == 'global';

  @override
  String toString() {
    return 'LocalTemplate(id: $id, title: $title, scope: $scope)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
