enum ModelCapability { reasoning, vision, tools, multimodal }

class AIProvider {
  final String id;
  final String name;
  final String? description;
  final bool isAvailable;
  final DateTime? createdAt;

  AIProvider({
    required this.id,
    required this.name,
    this.description,
    this.isAvailable = true,
    this.createdAt,
  });

  factory AIProvider.fromJson(Map<String, dynamic> json) {
    return AIProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_available': isAvailable,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  AIProvider copyWith({
    String? id,
    String? name,
    String? description,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return AIProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AIProvider(id: $id, name: $name, isAvailable: $isAvailable)';
  }
}

class AIModel {
  final String id;
  final String name;
  final String providerId;
  final String providerName;
  final String? description;
  final List<ModelCapability> capabilities;
  final bool isDefault;
  final Map<String, dynamic>? cost;
  final DateTime? createdAt;

  AIModel({
    required this.id,
    required this.name,
    required this.providerId,
    required this.providerName,
    this.description,
    this.capabilities = const [],
    this.isDefault = false,
    this.cost,
    this.createdAt,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'] as String,
      name: json['name'] as String,
      providerId: json['provider_id'] as String,
      providerName: json['provider_name'] as String,
      description: json['description'] as String?,
      capabilities:
          (json['capabilities'] as List<dynamic>?)
              ?.map(
                (e) => ModelCapability.values.firstWhere(
                  (m) => m.name == e,
                  orElse: () => ModelCapability.tools,
                ),
              )
              .toList() ??
          [],
      isDefault: json['is_default'] as bool? ?? false,
      cost: json['cost'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider_id': providerId,
      'provider_name': providerName,
      'description': description,
      'capabilities': capabilities.map((e) => e.name).toList(),
      'is_default': isDefault,
      'cost': cost,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  AIModel copyWith({
    String? id,
    String? name,
    String? providerId,
    String? providerName,
    String? description,
    List<ModelCapability>? capabilities,
    bool? isDefault,
    Map<String, dynamic>? cost,
    DateTime? createdAt,
  }) {
    return AIModel(
      id: id ?? this.id,
      name: name ?? this.name,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      description: description ?? this.description,
      capabilities: capabilities ?? this.capabilities,
      isDefault: isDefault ?? this.isDefault,
      cost: cost ?? this.cost,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AIModel(id: $id, name: $name, provider: $providerName, isDefault: $isDefault)';
  }
}
