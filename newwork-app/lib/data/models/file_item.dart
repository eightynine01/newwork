class FileItem {
  final String path;
  final String name;
  final String type;
  final int? size;
  final double? modified;
  final double? created;
  final bool isFile;
  final bool isDir;

  FileItem({
    required this.path,
    required this.name,
    required this.type,
    this.size,
    this.modified,
    this.created,
    required this.isFile,
    required this.isDir,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      path: json['path'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      size: json['size'] as int?,
      modified: json['modified'] != null
          ? (json['modified'] as num).toDouble()
          : null,
      created: json['created'] != null
          ? (json['created'] as num).toDouble()
          : null,
      isFile: json['is_file'] as bool? ?? (json['type'] == 'file'),
      isDir: json['is_dir'] as bool? ?? (json['type'] == 'directory'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'type': type,
      if (size != null) 'size': size,
      if (modified != null) 'modified': modified,
      if (created != null) 'created': created,
      'is_file': isFile,
      'is_dir': isDir,
    };
  }

  String get sizeFormatted {
    if (size == null || isDir) return '';

    if (size! < 1024) {
      return '$size B';
    } else if (size! < 1024 * 1024) {
      return '${(size! / 1024).toStringAsFixed(1)} KB';
    } else if (size! < 1024 * 1024 * 1024) {
      return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  DateTime? get modifiedDate {
    if (modified == null) return null;
    return DateTime.fromMillisecondsSinceEpoch((modified! * 1000).toInt());
  }

  bool get isDirectory => isDir;
  bool get isRegularFile => isFile;
}


class FileContent {
  final String path;
  final String name;
  final String content;
  final int size;
  final double? modified;

  FileContent({
    required this.path,
    required this.name,
    required this.content,
    required this.size,
    this.modified,
  });

  factory FileContent.fromJson(Map<String, dynamic> json) {
    return FileContent(
      path: json['path'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      size: json['size'] as int,
      modified: json['modified'] != null
          ? (json['modified'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'content': content,
      'size': size,
      if (modified != null) 'modified': modified,
    };
  }
}
