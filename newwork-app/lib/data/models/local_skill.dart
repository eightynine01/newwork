import 'dart:convert';

/// Local Skill model for SQLite storage
///
/// This model mirrors the API Skill model but is designed for
/// local SQLite storage with JSON serialization for config.
class LocalSkill {
  final String id;
  final String name;
  final String? description;
  final Map<String, dynamic>? config;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalSkill({
    required this.id,
    required this.name,
    this.description,
    this.config,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create LocalSkill from API Skill model
  factory LocalSkill.fromApiSkill(dynamic apiSkill) {
    return LocalSkill(
      id: apiSkill.id as String,
      name: apiSkill.name as String,
      description: apiSkill.description as String?,
      config: apiSkill.config != null
          ? (apiSkill.config is String
              ? jsonDecode(apiSkill.config as String)
              : apiSkill.config as Map<String, dynamic>)
          : null,
      createdAt: apiSkill.createdAt is DateTime
          ? apiSkill.createdAt as DateTime
          : DateTime.parse(apiSkill.createdAt as String),
      updatedAt: apiSkill.updatedAt is DateTime
          ? apiSkill.updatedAt as DateTime
          : DateTime.parse(apiSkill.updatedAt as String),
    );
  }

  /// Create LocalSkill from SQLite map
  factory LocalSkill.fromMap(Map<String, dynamic> map) {
    return LocalSkill(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      config: map['config'] != null
          ? jsonDecode(map['config'] as String) as Map<String, dynamic>
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'config': config != null ? jsonEncode(config) : null,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'config': config,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  LocalSkill copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'LocalSkill(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalSkill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
