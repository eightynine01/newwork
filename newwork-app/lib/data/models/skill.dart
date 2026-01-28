class Skill {
  final String id;
  final String name;
  final String description;
  final String? version;
  final String category;
  final List<String> tags;
  final Map<String, dynamic>? config;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    this.version,
    required this.category,
    this.tags = const [],
    this.config,
    this.isEnabled = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String?,
      category: json['category'] as String? ?? 'general',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      config: json['config'] as Map<String, dynamic>?,
      isEnabled: json['is_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'category': category,
      'tags': tags,
      'config': config,
      'is_enabled': isEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Skill copyWith({
    String? id,
    String? name,
    String? description,
    String? version,
    String? category,
    List<String>? tags,
    Map<String, dynamic>? config,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      config: config ?? this.config,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Skill(id: $id, name: $name, category: $category, version: $version)';
  }
}
