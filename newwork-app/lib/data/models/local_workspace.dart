import 'dart:convert';

/// Local Workspace model for SQLite storage
///
/// This model mirrors the API Workspace model but is designed for
/// local SQLite storage.
class LocalWorkspace {
  final String id;
  final String name;
  final String path;
  final String? description;
  final DateTime createdAt;
  final bool isActive;

  LocalWorkspace({
    required this.id,
    required this.name,
    required this.path,
    this.description,
    required this.createdAt,
    this.isActive = false,
  });

  /// Create LocalWorkspace from API Workspace model
  factory LocalWorkspace.fromApiWorkspace(dynamic apiWorkspace) {
    return LocalWorkspace(
      id: apiWorkspace.id as String,
      name: apiWorkspace.name as String,
      path: apiWorkspace.path as String,
      description: apiWorkspace.description as String?,
      createdAt: apiWorkspace.createdAt is DateTime
          ? apiWorkspace.createdAt as DateTime
          : DateTime.parse(apiWorkspace.createdAt as String),
      isActive: apiWorkspace.isActive as bool? ?? false,
    );
  }

  /// Create LocalWorkspace from SQLite map
  factory LocalWorkspace.fromMap(Map<String, dynamic> map) {
    return LocalWorkspace(
      id: map['id'] as String,
      name: map['name'] as String,
      path: map['path'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Create a copy with updated fields
  LocalWorkspace copyWith({
    String? id,
    String? name,
    String? path,
    String? description,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return LocalWorkspace(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get workspace folder name from path
  String get folderName {
    return path.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).last;
  }

  @override
  String toString() {
    return 'LocalWorkspace(id: $id, name: $name, path: $path, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalWorkspace && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
