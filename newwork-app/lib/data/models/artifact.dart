enum ArtifactType { file, text, image, code }

class Artifact {
  final String id;
  final String sessionId;
  final String name;
  final String path;
  final ArtifactType type;
  final int size;
  final String? content;
  final String? language;
  final DateTime createdAt;
  final String? checksum;

  Artifact({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    this.content,
    this.language,
    required this.createdAt,
    this.checksum,
  });

  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      type: ArtifactType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ArtifactType.file,
      ),
      size: json['size'] as int? ?? 0,
      content: json['content'] as String?,
      language: json['language'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      checksum: json['checksum'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'name': name,
      'path': path,
      'type': type.name,
      'size': size,
      'content': content,
      'language': language,
      'created_at': createdAt.toIso8601String(),
      'checksum': checksum,
    };
  }

  Artifact copyWith({
    String? id,
    String? sessionId,
    String? name,
    String? path,
    ArtifactType? type,
    int? size,
    String? content,
    String? language,
    DateTime? createdAt,
    String? checksum,
  }) {
    return Artifact(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      content: content ?? this.content,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      checksum: checksum ?? this.checksum,
    );
  }

  @override
  String toString() {
    return 'Artifact(id: $id, name: $name, type: $type, size: $size)';
  }
}
