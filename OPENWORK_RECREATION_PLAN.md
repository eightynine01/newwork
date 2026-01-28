# OpenWork Python + Flutter Recreation Plan

## Project Overview
OpenWork is an open-source alternative to Claude Cowork, providing a clean, guided workflow for OpenCode operations. This document outlines the recreation of OpenWork using Python (backend) and Flutter (frontend).

## Architecture Summary

### Technology Stack

| Component | Original (OpenWork) | Recreation (Our) |
|-----------|---------------------|------------------|
| **Frontend** | SolidJS + TailwindCSS | Flutter + Material Design 3 |
| **Desktop** | Tauri 2.x (Rust) | Native mobile + Desktop support |
| **Backend** | OpenCode CLI (spawned) | FastAPI (Python) |
| **State** | Solid stores + IndexedDB | Riverpod + SQLite/SharedPreferences |
| **IPC** | Tauri commands | HTTP/REST + WebSocket/SSE |
| **OpenCode Integration** | SDK | Direct HTTP API calls |

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Frontend)                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ Onboard  │  │Dashboard │  │ Session  │          │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘          │
│       │              │              │                        │
│       └──────────────┼──────────────┘                        │
│                      │                                      │
│              ┌───────▼────────┐                           │
│              │ Riverpod State │                           │
│              └───────┬────────┘                           │
│                      │                                      │
└──────────────────────┼──────────────────────────────────────┘
                       │
                       │ HTTP/REST + WebSocket/SSE
                       │
┌──────────────────────▼──────────────────────────────────────┐
│              FastAPI Backend (Python)                      │
│  ┌──────────────────────────────────────────┐              │
│  │  OpenCode Integration Layer           │              │
│  │  - Session Management                │              │
│  │  - Message/Part Handling            │              │
│  │  - Todo Tracking                   │              │
│  │  - Permission Handling              │              │
│  └──────────────────────────────────────────┘              │
│  ┌──────────────────────────────────────────┐              │
│  │  Config Management                   │              │
│  │  - opencode.json                   │              │
│  │  - MCP servers                     │              │
│  │  - Skills                         │              │
│  │  - Plugins                        │              │
│  └──────────────────────────────────────────┘              │
│  ┌──────────────────────────────────────────┐              │
│  │  File System Operations              │              │
│  │  - Workspace management             │              │
│  │  - Template storage                 │              │
│  │  - Skill folder operations          │              │
│  └──────────────────────────────────────────┘              │
└───────────────────────────────────────────────────────────────┘
                       │
                       │ OpenCode CLI API
                       │
┌──────────────────────▼──────────────────────────────────────┐
│              OpenCode Server (CLI)                          │
└───────────────────────────────────────────────────────────────┘
```

## Core Features Breakdown

### 1. Onboarding
**Status**: Pending
**Description**: Initial setup flow for users to select operating mode

**Sub-features**:
- Mode selection (Host mode vs Client mode)
- Host mode: Pick workspace folder, authorize directories
- Client mode: Connect to remote OpenCode server URL
- Engine detection and version check
- Settings persistence

**Flutter Implementation**:
- `OnboardingPage` widget with step-based flow
- Mode selection cards (Host vs Client)
- File picker for workspace selection
- URL input for client mode
- Riverpod state for onboarding progress

**Python Backend**:
- GET `/api/health` - Check OpenCode availability
- GET `/api/engine/info` - Get OpenCode version
- POST `/api/workspace/validate` - Validate workspace path

### 2. Dashboard
**Status**: Pending
**Description**: Main hub with tabs for different features

**Tabs**:
- **Home**: Welcome, quick actions, recent sessions
- **Sessions**: List all sessions with status
- **Templates**: Workspace and global templates management
- **Skills**: Installed skills, install new skills
- **Plugins**: opencode.json plugin management
- **MCP**: Model Context Protocol server connections
- **Settings**: App preferences, model selection, theme

**Flutter Implementation**:
- `DashboardPage` with bottom navigation or sidebar
- `DashboardTab` enum for tab management
- Individual tab widgets:
  - `HomeTab`
  - `SessionsTab`
  - `TemplatesTab`
  - `SkillsTab`
  - `PluginsTab`
  - `McpTab`
  - `SettingsTab`

**Python Backend**:
- GET `/api/sessions` - List all sessions
- GET `/api/templates` - List templates
- GET `/api/skills` - List installed skills
- GET `/api/plugins` - Get plugin config
- GET `/api/mcp/servers` - List MCP servers
- GET `/api/providers` - List available AI providers

### 3. Session View
**Status**: Pending
**Description**: Active session interface for interacting with OpenCode

**Sub-features**:
- Message display (user and assistant)
- Real-time progress updates (SSE/WebSocket)
- Todo/timeline visualization
- Permission request handling
- Artifact display (files, text)
- Working files list
- Send prompt input

**Flutter Implementation**:
- `SessionPage` widget
- `MessageList` with `MessageBubble` components
- `TodoTimeline` widget for step-by-step progress
- `PermissionDialog` for approving/denying requests
- `ArtifactCard` for showing created files
- `PromptInput` with send button

**Python Backend**:
- POST `/api/session/create` - Create new session
- GET `/api/session/{id}` - Get session details
- POST `/api/session/{id}/prompt` - Send a prompt
- GET `/api/session/{id}/events` - SSE endpoint for real-time updates
- POST `/api/permission/{id}/respond` - Respond to permission requests

### 4. Real-time Updates
**Status**: Pending
**Description**: SSE/WebSocket for live progress and updates

**Events**:
- Message created/updated
- Todo items added/updated/completed
- Permission requests
- Session status changes
- MCP status updates

**Flutter Implementation**:
- WebSocket client or EventSource (SSE) listener
- Riverpod notifiers for real-time state updates
- Auto-scroll to latest messages
- Connection status indicator

**Python Backend**:
- WebSocket endpoint: `/ws/session/{id}`
- SSE endpoint: `/api/session/{id}/events`
- Event types: `message`, `todo`, `permission`, `status`, `mcp`

### 5. Templates
**Status**: Pending
**Description**: Save and re-run common workflows

**Features**:
- Create template from current prompt
- Save as workspace or global template
- List templates with metadata
- Run template (fills in variables)
- Delete template

**Data Model**:
```json
{
  "id": "uuid",
  "title": "string",
  "description": "string",
  "prompt": "string",
  "createdAt": "timestamp",
  "scope": "workspace|global"
}
```

**Flutter Implementation**:
- `TemplatesTab` with template list
- `TemplateCard` showing title, description, date
- `CreateTemplateModal` for saving new template
- `RunTemplateDialog` for executing template

**Python Backend**:
- GET `/api/templates` - List templates
- POST `/api/templates` - Create template
- DELETE `/api/templates/{id}` - Delete template
- POST `/api/templates/{id}/run` - Execute template

### 6. Skills Manager
**Status**: Pending
**Description**: Manage OpenCode skills

**Features**:
- List installed skills from `.opencode/skill/`
- Install skill from OpenPackage (`opkg install`)
- Import local skill folder
- Uninstall skill
- View skill description/metadata

**Data Model**:
```json
{
  "name": "string",
  "path": "string",
  "description": "string"
}
```

**Flutter Implementation**:
- `SkillsTab` with skill list
- `SkillCard` showing name, description
- `InstallSkillDialog` for opkg install
- `ImportSkillDialog` for local folder import

**Python Backend**:
- GET `/api/skills` - List skills
- POST `/api/skills/install` - Install from opkg
- POST `/api/skills/import` - Import local folder
- DELETE `/api/skills/{name}` - Uninstall skill

### 7. Plugins Manager
**Status**: Pending
**Description**: Manage opencode.json plugin configurations

**Features**:
- Read opencode.json (project and global scope)
- List installed plugins
- Add plugin to config
- Remove plugin from config
- Edit plugin configuration

**Config Format**:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["plugin-name"],
  "mcp": {
    "server-name": {
      "type": "remote",
      "url": "https://...",
      "enabled": true
    }
  }
}
```

**Flutter Implementation**:
- `PluginsTab` with plugin list
- `PluginCard` with toggle switch
- `AddPluginDialog` for adding new plugin
- Scope selector (project vs global)

**Python Backend**:
- GET `/api/plugins` - Get plugin config
- POST `/api/plugins` - Add plugin
- DELETE `/api/plugins/{name}` - Remove plugin
- GET `/api/plugins/scope` - Get current scope path

### 8. MCP Manager
**Status**: Pending
**Description**: Model Context Protocol server management

**Features**:
- List configured MCP servers
- Add new MCP server
- Connect/disconnect MCP server
- OAuth flow for auth-required MCPs
- View MCP status

**Data Model**:
```json
{
  "name": "string",
  "config": {
    "type": "remote|local",
    "url": "string",
    "enabled": true,
    "oauth": {}
  }
}
```

**Flutter Implementation**:
- `McpTab` with server list
- `McpServerCard` showing name, status, type
- `AddMcpDialog` for adding new server
- `McpAuthDialog` for OAuth flow

**Python Backend**:
- GET `/api/mcp/servers` - List MCP servers
- POST `/api/mcp/add` - Add MCP server
- DELETE `/api/mcp/{name}` - Remove MCP server
- GET `/api/mcp/status` - Get MCP server status
- POST `/api/mcp/oauth/callback` - Handle OAuth callback

### 9. Workspace Manager
**Status**: Pending
**Description**: Manage authorized workspace directories

**Features**:
- Pick workspace folder
- Authorize directories for OpenCode
- List workspaces
- Switch between workspaces
- Remove authorized directory

**Data Model**:
```json
{
  "id": "uuid",
  "name": "string",
  "path": "string",
  "createdAt": "timestamp",
  "preset": "starter|automation|minimal"
}
```

**Flutter Implementation**:
- Workspace picker in dashboard header
- `WorkspaceSelector` showing current workspace
- `WorkspaceListDialog` for switching
- File picker for folder selection

**Python Backend**:
- GET `/api/workspaces` - List workspaces
- POST `/api/workspaces` - Add new workspace
- DELETE `/api/workspaces/{id}` - Remove workspace
- POST `/api/workspaces/authorize` - Authorize directory
- GET `/api/workspace/active` - Get active workspace

### 10. Permissions
**Status**: Pending
**Description**: Handle OpenCode permission requests

**Features**:
- Display pending permission requests
- Show request details (tool, parameters)
- Approve once
- Approve always
- Deny
- Permission history

**Data Model**:
```json
{
  "id": "string",
  "type": "string",
  "tool": "string",
  "parameters": {},
  "status": "pending|approved|denied"
}
```

**Flutter Implementation**:
- `PermissionBanner` appearing when request is pending
- `PermissionDialog` with Approve Once, Always, Deny buttons
- Permission history list in settings

**Python Backend**:
- GET `/api/permissions/pending` - Get pending permissions
- POST `/api/permissions/{id}/respond` - Respond to permission
- GET `/api/permissions/history` - Get permission history

### 11. Model Picker
**Status**: Pending
**Description**: Select AI model and provider

**Features**:
- List available providers
- List models per provider
- Set default model
- Override model per session
- Show model capabilities (free, reasoning, etc.)

**Data Model**:
```json
{
  "id": "string",
  "name": "string",
  "providerID": "string",
  "capabilities": {
    "reasoning": true,
    "vision": false
  },
  "cost": {
    "input": 0,
    "output": 0
  }
}
```

**Flutter Implementation**:
- `ModelPickerModal` with search and filtering
- Model cards showing provider, name, capabilities
- "Set Default" button
- Session-level override option

**Python Backend**:
- GET `/api/providers` - List providers
- GET `/api/models` - List all models
- POST `/api/settings/model` - Set default model
- POST `/api/session/{id}/model` - Override session model

### 12. Theme Support
**Status**: Pending
**Description**: Light/dark mode support

**Features**:
- Light theme
- Dark theme
- System theme (follow OS preference)
- Theme persistence

**Flutter Implementation**:
- Material 3 theme system
- `ThemeMode` enum (light, dark, system)
- Theme switching in Settings
- SharedPreferences for persistence

**Python Backend**:
- None (client-side only)

### 13. Persistence
**Status**: Pending
**Description**: Local data storage

**Flutter Storage**:
- `SharedPreferences` for app settings
- `sqflite` for session history, templates, workspaces
- File system for skill/plugin configs

**Python Storage**:
- SQLite for session data, templates
- File system for opencode.json, .opencode folder

**Data Tables**:
- `sessions`: id, title, path, created_at, updated_at
- `templates`: id, title, description, prompt, scope, created_at
- `workspaces`: id, name, path, created_at
- `permissions`: id, type, status, created_at

## Implementation Priority

### Phase 1: Core Infrastructure (High Priority)
1. Setup Python FastAPI backend
2. Setup Flutter project structure
3. Implement basic OpenCode API integration
4. Implement data persistence (SQLite)
5. Implement WebSocket/SSE for real-time updates

### Phase 2: Core Features (High Priority)
6. Implement onboarding flow
7. Implement dashboard with tabs
8. Implement session view (messages, todos)
9. Implement workspace manager
10. Implement permission handling

### Phase 3: Advanced Features (Medium Priority)
11. Implement templates
12. Implement skills manager
13. Implement plugins manager
14. Implement MCP manager
15. Implement model picker

### Phase 4: Polish (Low Priority)
16. Implement theme support
17. Add animations and transitions
18. Improve error handling
19. Add accessibility features
20. Write documentation

## OpenCode API Integration

The Python backend will integrate with OpenCode via its HTTP API:

### Key Endpoints to Use:
- `POST /session` - Create session
- `GET /session/{id}` - Get session details
- `POST /session/{id}/prompt` - Send prompt
- `GET /event` - SSE for real-time events
- `GET /todos` - Get todo items
- `GET /permission` - Get pending permissions
- `POST /permission/{id}/respond` - Respond to permission

### Configuration:
- `opencode.json` for plugins and MCP
- `.opencode/skill/` for skill files
- `.opencode/agent/` for agent configurations

## File Structure

### Python Backend
```
openwork-python/
├── app/
│   ├── main.py                 # FastAPI app entry point
│   ├── api/
│   │   ├── __init__.py
│   │   ├── sessions.py         # Session endpoints
│   │   ├── templates.py       # Template endpoints
│   │   ├── skills.py          # Skill endpoints
│   │   ├── plugins.py         # Plugin endpoints
│   │   ├── mcp.py            # MCP endpoints
│   │   ├── workspaces.py      # Workspace endpoints
│   │   ├── permissions.py     # Permission endpoints
│   │   └── providers.py      # Model/Provider endpoints
│   ├── models/
│   │   ├── __init__.py
│   │   ├── session.py
│   │   ├── template.py
│   │   ├── skill.py
│   │   └── workspace.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── opencode_client.py # OpenCode API client
│   │   ├── config_service.py  # opencode.json management
│   │   ├── file_service.py    # File system operations
│   │   └── event_service.py  # Real-time events
│   └── db/
│       ├── __init__.py
│       ├── database.py        # SQLite setup
│       └── repositories.py    # Data access layer
├── tests/
├── requirements.txt
├── pyproject.toml
└── README.md
```

### Flutter Frontend
```
openwork-flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart                 # App widget with routing
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── colors.dart
│   │   │   └── text_styles.dart
│   │   └── constants.dart
│   ├── data/
│   │   ├── models/             # Data models
│   │   │   ├── session.dart
│   │   │   ├── message.dart
│   │   │   ├── todo.dart
│   │   │   └── template.dart
│   │   ├── repositories/        # API clients
│   │   │   ├── api_client.dart
│   │   │   └── websocket_client.dart
│   │   └── providers/          # Local storage
│   │       └── storage_provider.dart
│   ├── features/
│   │   ├── onboarding/
│   │   │   ├── onboarding_page.dart
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   ├── dashboard/
│   │   │   ├── dashboard_page.dart
│   │   │   ├── widgets/
│   │   │   └── tabs/
│   │   │       ├── home_tab.dart
│   │   │       ├── sessions_tab.dart
│   │   │       ├── templates_tab.dart
│   │   │       ├── skills_tab.dart
│   │   │       ├── plugins_tab.dart
│   │   │       ├── mcp_tab.dart
│   │   │       └── settings_tab.dart
│   │   └── session/
│   │       ├── session_page.dart
│   │       ├── widgets/
│   │       │   ├── message_bubble.dart
│   │       │   ├── todo_timeline.dart
│   │       │   ├── permission_dialog.dart
│   │       │   └── artifact_card.dart
│   │       └── providers/
│   └── shared/
│       ├── widgets/
│       │   ├── app_button.dart
│       │   ├── app_card.dart
│       │   ├── app_input.dart
│       │   └── loading_indicator.dart
│       └── providers/
│           └── app_state.dart
├── pubspec.yaml
├── README.md
└── assets/
```

## Testing Strategy

### Backend Tests
- Unit tests for services
- Integration tests for API endpoints
- OpenCode client mocking
- Database operations tests

### Frontend Tests
- Widget tests for UI components
- Integration tests for user flows
- State management tests
- Mock API responses

### End-to-End Tests
- Complete onboarding flow
- Create and run session
- Template creation and execution
- Skill installation
- MCP connection

## Deployment

### Python Backend
- Docker container
- Environment configuration
- Process manager (systemd/supervisord)

### Flutter App
- Android APK/AAB
- iOS IPA
- Windows/MacOS/Linux executables
- App Store deployment

## Notes

- This is a recreation of OpenWork functionality
- Original uses SolidJS + Tauri, we use Flutter + Python
- OpenCode CLI integration via HTTP API
- Focus on mobile-first design while maintaining desktop support
- Real-time updates via WebSocket/SSE
- Local-first with optional cloud sync (future feature)
