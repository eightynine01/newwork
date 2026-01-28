import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../models/todo.dart';
import '../models/event.dart';
import '../../core/constants.dart';

class WebSocketClient {
  final String wsUrl;
  StreamSubscription? _subscription;
  final _messageController = StreamController<dynamic>.broadcast();
  final _eventController = StreamController<Event>.broadcast();
  http.Client? _sseClient;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  WebSocketClient({this.wsUrl = AppConstants.wsBaseUrl});

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<Event> get eventStream => _eventController.stream;

  bool get isConnected => _sseClient != null;

  Future<void> connect({
    String? sessionId,
    Map<String, dynamic>? extraParams,
  }) async {
    // TODO: Implement WebSocket connection for bi-directional communication
  }

  void disconnect() {
    _subscription?.cancel();
    _sseClient?.close();
    _sseClient = null;
    _reconnectAttempts = 0;
  }

  // SSE Events - Server-Sent Events for real-time updates
  Stream<Event> getSessionEvents(String sessionId) async* {
    while (_reconnectAttempts < _maxReconnectAttempts) {
      try {
        final client = http.Client();
        _sseClient = client;

        final request = http.Request(
          'GET',
          Uri.parse('$wsUrl/sessions/$sessionId/events'),
        );
        request.headers['Accept'] = 'text/event-stream';
        request.headers['Cache-Control'] = 'no-cache';

        final streamedResponse = await client.send(request);

        // Reset reconnect attempts on successful connection
        _reconnectAttempts = 0;

        await for (final chunk in streamedResponse.stream) {
          final lines = utf8.decode(chunk).split('\n');

          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data.trim().isEmpty) continue;

              try {
                final eventMap = jsonDecode(data) as Map<String, dynamic>;
                final event = Event.fromJson(eventMap);

                _eventController.add(event);

                final eventType = eventMap['type'] as String?;
                switch (eventType) {
                  case 'message':
                  case 'message_added':
                  case 'message_updated':
                    _messageController.add(eventMap);
                    break;
                  case 'todo':
                  case 'todo_added':
                  case 'todo_updated':
                  case 'todo_completed':
                    _messageController.add(eventMap);
                    break;
                  case 'permission':
                  case 'permission_requested':
                    _messageController.add(eventMap);
                    break;
                  case 'status':
                    _messageController.add(eventMap);
                    break;
                }

                yield event;
              } catch (e) {
                // Ignore JSON parsing errors for malformed events
              }
            }
          }
        }
      } catch (e) {
        _eventController.addError(e);
        _reconnectAttempts++;

        if (_reconnectAttempts < _maxReconnectAttempts) {
          // Wait before reconnecting
          await Future.delayed(_reconnectDelay);
        } else {
          // Max reconnection attempts reached
          rethrow;
        }
      } finally {
        _sseClient?.close();
        _sseClient = null;
      }
    }
  }

  // Message Events
  Stream<Message> onMessageAdded() {
    return _messageController.stream
        .where((data) => data is Map<String, dynamic>)
        .map((data) => Message.fromJson(data as Map<String, dynamic>));
  }

  // Todo Events
  Stream<Todo> onTodoAdded() {
    return _messageController.stream
        .where((data) => data is Map<String, dynamic>)
        .map((data) => Todo.fromJson(data as Map<String, dynamic>));
  }

  Stream<Todo> onTodoUpdated() {
    return _messageController.stream
        .where((data) => data is Map<String, dynamic>)
        .map((data) => Todo.fromJson(data as Map<String, dynamic>));
  }

  // General Events
  Stream<Event> onAnyEvent() {
    return _eventController.stream;
  }

  void dispose() {
    _subscription?.cancel();
    _sseClient?.close();
    _messageController.close();
    _eventController.close();
  }
}
