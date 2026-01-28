enum PluginScope { project, global }

class Plugin {
  final String id;
  final String name;
  final String? description;
  final PluginScope scope;
  final bool isEnabled;
  final Map<String, dynamic>? config;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Plugin({
    required this.id,
    required this.name,
    this.description,
    required this.scope,
    this.isEnabled = true,
    this.config,
    this.createdAt,
    this.updatedAt,
  });

  factory Plugin.fromJson(Map<String, dynamic> json) {
    return Plugin(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      scope: PluginScope.values.firstWhere(
        (e) => e.name == json['scope'],
        orElse: () => PluginScope.global,
      ),
      isEnabled: json['is_enabled'] as bool? ?? true,
      config: json['config'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
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
      'scope': scope.name,
      'is_enabled': isEnabled,
      'config': config,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Plugin copyWith({
    String? id,
    String? name,
    String? description,
    PluginScope? scope,
    bool? isEnabled,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plugin(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      scope: scope ?? this.scope,
      isEnabled: isEnabled ?? this.isEnabled,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Plugin(id: $id, name: $name, scope: $scope, isEnabled: $isEnabled)';
  }
}
