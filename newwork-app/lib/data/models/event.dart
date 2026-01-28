enum EventType {
  message,
  todoUpdate,
  permissionRequest,
  status,
  streamChunk,
  error,
}

class Event {
  final EventType type;
  final String sessionId;
  final Map<String, dynamic> data;
  final DateTime? timestamp;

  Event({
    required this.type,
    required this.sessionId,
    required this.data,
    this.timestamp,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      type: _parseEventType(json['type'] as String?),
      sessionId: json['session_id'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': _eventTypeToString(type),
      'session_id': sessionId,
      'data': data,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  static EventType _parseEventType(String? type) {
    if (type == null) return EventType.message;

    switch (type) {
      case 'message':
        return EventType.message;
      case 'todo_update':
        return EventType.todoUpdate;
      case 'permission_request':
        return EventType.permissionRequest;
      case 'status':
        return EventType.status;
      case 'stream_chunk':
        return EventType.streamChunk;
      case 'error':
        return EventType.error;
      default:
        return EventType.message;
    }
  }

  static String _eventTypeToString(EventType type) {
    switch (type) {
      case EventType.message:
        return 'message';
      case EventType.todoUpdate:
        return 'todo_update';
      case EventType.permissionRequest:
        return 'permission_request';
      case EventType.status:
        return 'status';
      case EventType.streamChunk:
        return 'stream_chunk';
      case EventType.error:
        return 'error';
    }
  }

  Event copyWith({
    EventType? type,
    String? sessionId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return Event(
      type: type ?? this.type,
      sessionId: sessionId ?? this.sessionId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'Event(type: $type, sessionId: $sessionId, data: $data)';
  }
}
