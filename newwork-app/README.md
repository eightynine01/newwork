# OpenWork Flutter

Flutter frontend for OpenWork (OpenCode GUI clone) - an AI-powered coding assistant.

## Overview

This Flutter application provides a cross-platform (mobile and desktop) interface for the OpenWork system, which connects to a Python FastAPI backend to provide AI-assisted coding capabilities.

## Features

- **Session Management**: Create, view, and manage coding sessions
- **Real-time Communication**: WebSocket/SSE support for live updates
- **Templates**: Pre-built prompts and configurations
- **Skills**: AI agent capabilities and tools
- **Workspaces**: Project organization and management
- **MCP Integration**: Model Context Protocol server support
- **Local Storage**: SQLite and SharedPreferences for data persistence
- **Material 3 Design**: Modern, responsive UI

## Project Structure

```
lib/
├── main.dart                 # App entry point with ProviderScope
├── app.dart                  # Root app with routing and theme
├── core/
│   ├── constants.dart           # App-wide constants
│   └── theme/
│       ├── app_theme.dart      # Theme configuration
│       ├── colors.dart         # Color definitions
│       └── text_styles.dart   # Typography styles
├── data/
│   ├── models/                # Data models
│   │   ├── session.dart
│   │   ├── message.dart
│   │   ├── todo.dart
│   │   ├── template.dart
│   │   ├── skill.dart
│   │   ├── workspace.dart
│   │   ├── permission.dart
│   │   └── mcp_server.dart
│   ├── repositories/           # API clients
│   │   ├── api_client.dart    # HTTP client for backend API
│   │   └── websocket_client.dart # WebSocket/SSE client
│   └── providers/
│       └── storage_provider.dart # SharedPreferences wrapper
├── features/                # Feature modules
│   ├── onboarding/
│   │   └── onboarding_page.dart
│   ├── dashboard/
│   │   ├── dashboard_page.dart
│   │   └── tabs/
│   │       ├── home_tab.dart
│   │       ├── sessions_tab.dart
│   │       ├── templates_tab.dart
│   │       ├── skills_tab.dart
│   │       ├── plugins_tab.dart
│   │       ├── mcp_tab.dart
│   │       └── settings_tab.dart
│   └── session/
│       └── session_page.dart
└── shared/
    └── widgets/              # Reusable UI components
        ├── app_button.dart
        ├── app_card.dart
        ├── app_input.dart
        └── loading_indicator.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Python FastAPI backend (see [openwork-python](../openwork-python/))

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd openwork-flutter
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Configuration

Update the API base URL in `lib/core/constants.dart`:

```dart
class AppConstants {
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String wsBaseUrl = 'ws://localhost:8000';
}
```

## State Management

This project uses **Riverpod** for state management:

```dart
// Providers are defined in future feature files
final sessionProvider = StateNotifierProvider<SessionNotifier, Session>((ref) {
  return SessionNotifier(ref.read(apiProvider));
});
```

## Routing

Uses **go_router** for navigation:

```dart
GoRouter routes:
- /                     → OnboardingPage
- /dashboard          → DashboardPage
- /session/:id         → SessionPage
```

## API Integration

### HTTP Client (ApiClient)

```dart
final apiClient = ApiClient();

// Get sessions
final sessions = await apiClient.getSessions();

// Create session
final session = await apiClient.createSession(title: 'My Session');

// Send prompt
final message = await apiClient.sendPrompt(
  sessionId: 'id',
  prompt: 'Hello, AI!',
);
```

### WebSocket Client (WebSocketClient)

```dart
final wsClient = WebSocketClient();

// Connect to session
await wsClient.connect(sessionId: 'session-id');

// Listen for messages
wsClient.onMessageAdded().listen((message) {
  // Handle new message
});

// Send data
wsClient.send({'type': 'prompt', 'content': 'Hello'});
```

## Local Storage

```dart
final storage = StorageProvider();
await storage.init();

// Save data
await storage.setString('key', 'value');

// Retrieve data
final value = storage.getString('key');

// JSON support
await storage.setJson('user', {'name': 'John'});
final user = storage.getJson('user');
```

## Shared Widgets

### AppButton

```dart
AppButton(
  text: 'Click Me',
  variant: AppButtonVariant.primary,
  onPressed: () {},
  isLoading: false,
)
```

Variants: `primary`, `secondary`, `text`, `danger`, `success`

### AppCard

```dart
AppCard(
  title: 'Card Title',
  variant: AppCardVariant.elevated,
  child: Text('Card content'),
  onTap: () {},
)
```

Variants: `elevated`, `outlined`, `filled`

### AppInput

```dart
AppInput(
  label: 'Email',
  hint: 'Enter your email',
  inputType: AppInputType.email,
  onChanged: (value) {},
)
```

Types: `text`, `multiline`, `password`, `email`, `number`, `search`

### LoadingIndicator

```dart
// Small indicator
LoadingIndicator(size: 24)

// Full screen
FullScreenLoading(message: 'Loading...')

// Inline
InlineLoading(message: 'Processing')

// Card skeleton
CardLoading(itemCount: 3)
```

## Development

### Running Tests

```bash
flutter test
```

### Build for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

### Code Generation

For JSON serialization (future implementation):

```bash
flutter pub run build_runner build
```

## Backend API

The Flutter app connects to a FastAPI backend with the following endpoints:

- `GET /health` - Health check
- `GET /api/sessions` - List sessions
- `POST /api/session/create` - Create session
- `POST /api/session/{id}/prompt` - Send prompt
- `GET /api/session/{id}/events` - SSE events
- `GET /api/templates` - List templates
- `POST /api/templates` - Create template
- `GET /api/skills` - List skills
- `GET /api/workspaces` - List workspaces
- `GET /api/permissions/pending` - Get pending permissions

See [openwork-python](../openwork-python/) for backend implementation.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Related Projects

- [openwork-python](../openwork-python/) - FastAPI backend
- [openwork-web](../openwork-web/) - Web frontend (SolidJS + Tauri reference)
