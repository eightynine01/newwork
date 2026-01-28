import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/session.dart';
import '../../../data/models/message.dart';
import '../../../data/models/todo.dart';
import '../../../data/models/permission.dart';
import '../../../data/models/event.dart';
import '../../../data/repositories/api_client.dart';
import '../../../data/repositories/websocket_client.dart';

// API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// WebSocket Client provider
final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  return WebSocketClient();
});

// Session State
class SessionState {
  final Session? session;
  final List<Message> messages;
  final List<Todo> todos;
  final Permission? pendingPermission;
  final List<Permission> permissionHistory;
  final List<Map<String, dynamic>> artifacts;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final Set<String> expandedTodos;

  const SessionState({
    this.session,
    this.messages = const [],
    this.todos = const [],
    this.pendingPermission,
    this.permissionHistory = const [],
    this.artifacts = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.expandedTodos = const {},
  });

  SessionState copyWith({
    Session? session,
    List<Message>? messages,
    List<Todo>? todos,
    Permission? pendingPermission,
    List<Permission>? permissionHistory,
    List<Map<String, dynamic>>? artifacts,
    bool? isLoading,
    bool? isSending,
    String? error,
    Set<String>? expandedTodos,
  }) {
    return SessionState(
      session: session ?? this.session,
      messages: messages ?? this.messages,
      todos: todos ?? this.todos,
      pendingPermission: pendingPermission ?? this.pendingPermission,
      permissionHistory: permissionHistory ?? this.permissionHistory,
      artifacts: artifacts ?? this.artifacts,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      expandedTodos: expandedTodos ?? this.expandedTodos,
    );
  }
}

// Session Notifier
class SessionNotifier extends StateNotifier<SessionState> {
  final ApiClient _apiClient;
  final WebSocketClient _wsClient;
  StreamSubscription? _eventsSubscription;

  SessionNotifier(this._apiClient, this._wsClient)
      : super(const SessionState()) {
    _wsClient.eventStream.listen(_handleEvent);
  }

  Future<void> loadSession(String sessionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = await _apiClient.getSession(sessionId);

      state = state.copyWith(
        session: session,
        messages: session.messages,
        todos: session.todos,
        isLoading: false,
      );

      // Connect to SSE events
      _eventsSubscription = _wsClient
          .getSessionEvents(sessionId)
          .listen(_handleSSEEvent, onError: _handleError);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendPrompt(
    String sessionId,
    String model,
    String content,
  ) async {
    state = state.copyWith(isSending: true, error: null);

    try {
      final message = await _apiClient.sendPrompt(
        sessionId: sessionId,
        model: model,
        prompt: content,
      );

      state = state.copyWith(
        messages: [...state.messages, message],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  Future<void> respondPermission(String permissionId, String response) async {
    try {
      await _apiClient.respondPermission(permissionId, response);

      state = state.copyWith(pendingPermission: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadPermissionHistory(String sessionId) async {
    try {
      final history =
          await _apiClient.getPermissionHistoryForSession(sessionId);
      state = state.copyWith(permissionHistory: history);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void showPermissionDialog(Permission permission) {
    state = state.copyWith(pendingPermission: permission);
  }

  void hidePermissionDialog() {
    state = state.copyWith(pendingPermission: null);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void expandTodo(String todoId) {
    final expanded = Set<String>.from(state.expandedTodos);
    expanded.add(todoId);
    state = state.copyWith(expandedTodos: expanded);
  }

  void collapseTodo(String todoId) {
    final expanded = Set<String>.from(state.expandedTodos);
    expanded.remove(todoId);
    state = state.copyWith(expandedTodos: expanded);
  }

  void _handleEvent(dynamic event) {
    // Handle generic WebSocket events
  }

  void _handleSSEEvent(Event event) {
    switch (event.type) {
      case EventType.message:
        if (event.data['role'] != null && event.data['content'] != null) {
          final message = Message.fromJson(event.data);
          state = state.copyWith(messages: [...state.messages, message]);
        }
        break;
      case EventType.todoUpdate:
        if (event.data['id'] != null) {
          final todo = Todo.fromJson(event.data);
          final existingIndex = state.todos.indexWhere((t) => t.id == todo.id);
          if (existingIndex >= 0) {
            final updatedTodos = List<Todo>.from(state.todos);
            updatedTodos[existingIndex] = todo;
            state = state.copyWith(todos: updatedTodos);
          } else {
            state = state.copyWith(todos: [...state.todos, todo]);
          }
        }
        break;
      case EventType.permissionRequest:
        if (event.data['id'] != null) {
          final permission = Permission.fromJson(event.data);
          state = state.copyWith(pendingPermission: permission);
        }
        break;
      case EventType.status:
        // Handle session status changes
        if (event.data['status'] != null) {
          // Could update session state here
        }
        break;
      case EventType.streamChunk:
        // Handle stream chunks - could update the current assistant message
        break;
      case EventType.error:
        // Handle error events
        state = state.copyWith(error: event.data['error_message'] as String?);
        break;
    }
  }

  void _handleError(dynamic error) {
    state = state.copyWith(error: error.toString());
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _wsClient.disconnect();
    super.dispose();
  }
}

// Session provider family
final sessionProvider =
    StateNotifierProvider.family<SessionNotifier, SessionState, String>((
  ref,
  sessionId,
) {
  final apiClient = ref.watch(apiClientProvider);
  final wsClient = ref.watch(webSocketClientProvider);
  final notifier = SessionNotifier(apiClient, wsClient);

  ref.onDispose(() {
    notifier.dispose();
  });

  return notifier;
});

// Current session state provider
final currentSessionProvider = Provider<SessionState>((ref) {
  // This will be accessed with sessionId
  throw UnimplementedError('Use sessionProvider(sessionId) instead');
});

// Computed: Session loading state
final sessionLoadingProvider = Provider.family<bool, String>((ref, sessionId) {
  final state = ref.watch(sessionProvider(sessionId));
  return state.isLoading;
});

// Computed: Session error
final sessionErrorProvider = Provider.family<String?, String>((ref, sessionId) {
  final state = ref.watch(sessionProvider(sessionId));
  return state.error;
});

// Computed: Messages list
final sessionMessagesProvider = Provider.family<List<Message>, String>((
  ref,
  sessionId,
) {
  final state = ref.watch(sessionProvider(sessionId));
  return state.messages;
});

// Computed: Todos list
final sessionTodosProvider = Provider.family<List<Todo>, String>((
  ref,
  sessionId,
) {
  final state = ref.watch(sessionProvider(sessionId));
  return state.todos;
});

// Computed: Pending permission
final sessionPermissionProvider = Provider.family<Permission?, String>((
  ref,
  sessionId,
) {
  final state = ref.watch(sessionProvider(sessionId));
  return state.pendingPermission;
});

// Computed: Is sending
final isSendingProvider = Provider.family<bool, String>((ref, sessionId) {
  final state = ref.watch(sessionProvider(sessionId));
  return state.isSending;
});

// Computed: Permission history
final permissionHistoryProvider = Provider.family<List<Permission>, String>((
  ref,
  sessionId,
) {
  final state = ref.watch(sessionProvider(sessionId));
  return state.permissionHistory;
});
