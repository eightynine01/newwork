class Template {
  final String id;
  final String name;
  final String? description;
  final String systemPrompt;
  final List<String> skills;
  final Map<String, dynamic>? parameters;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int usageCount;
  final bool isPublic;

  Template({
    required this.id,
    required this.name,
    this.description,
    required this.systemPrompt,
    this.skills = const [],
    this.parameters,
    required this.createdAt,
    this.updatedAt,
    this.usageCount = 0,
    this.isPublic = false,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      systemPrompt: json['system_prompt'] as String,
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      parameters: json['parameters'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      usageCount: json['usage_count'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'system_prompt': systemPrompt,
      'skills': skills,
      'parameters': parameters,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'usage_count': usageCount,
      'is_public': isPublic,
    };
  }

  Template copyWith({
    String? id,
    String? name,
    String? description,
    String? systemPrompt,
    List<String>? skills,
    Map<String, dynamic>? parameters,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? usageCount,
    bool? isPublic,
  }) {
    return Template(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      skills: skills ?? this.skills,
      parameters: parameters ?? this.parameters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      usageCount: usageCount ?? this.usageCount,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  String toString() {
    return 'Template(id: $id, name: $name, usageCount: $usageCount)';
  }
}
