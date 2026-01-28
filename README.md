# NewWork

> AI-Powered Coding Assistant - Integrated Desktop Application

<p align="center">
  <a href="README.md"><b>English</b></a> |
  <a href="README.ko.md">한국어</a> |
  <a href="README.zh-CN.md">简体中文</a> |
  <a href="README.ja.md">日本語</a> |
  <a href="README.pt-BR.md">Português</a> |
  <a href="README.es.md">Español</a> |
  <a href="README.ru.md">Русский</a> |
  <a href="README.de.md">Deutsch</a> |
  <a href="README.fr.md">Français</a>
</p>

[![GitHub stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/eightynine01/newwork?style=social)](https://github.com/eightynine01/newwork/watchers)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Flutter](https://img.shields.io/badge/flutter-3.0+-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-green.svg)](https://fastapi.tiangolo.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

<!-- Star History Chart -->
<a href="https://star-history.com/#eightynine01/newwork&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=eightynine01/newwork&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=eightynine01/newwork&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=eightynine01/newwork&type=Date" />
 </picture>
</a>

## 📖 Overview

**NewWork** is an integrated desktop GUI application for Claude Code (formerly OpenCode). The Flutter frontend and Python backend are bundled into a single executable, allowing you to use it immediately after installation without any additional setup.

### Key Features

- 🎯 **All-in-One Application**: Flutter UI + Python backend integrated into a single executable
- 🚀 **Instant Launch**: No Docker or separate server setup required
- 💾 **Local-First**: SQLite-based local data storage
- 🖥️ **Cross-Platform**: Windows, macOS, Linux support
- 🔒 **Privacy-Focused**: All data stored locally

### Main Features

- 🎯 **Session Management**: Create, view, and manage AI coding sessions
- 📝 **Template System**: Reusable prompts and workflows
- 🔧 **Skill Management**: AI agent capabilities and tool management
- 📁 **Workspace**: Project organization and management
- 🔌 **MCP Integration**: Model Context Protocol server support
- 🌐 **Real-time Communication**: Real-time streaming via WebSocket
- 🎨 **Material Design 3**: Modern and responsive UI

## 🏗️ Architecture

NewWork uses a fully integrated architecture where users don't notice the backend exists:

```
┌─────────────────────────────────────┐
│   NewWork Desktop Application      │
│   (Flutter - Single Executable)     │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │   Flutter   │  │   Python     │ │
│  │   UI Layer  │◄─┤   Backend    │ │
│  │             │  │   (FastAPI)  │ │
│  └─────────────┘  └──────┬───────┘ │
│         │                │         │
│         │         ┌──────▼───────┐ │
│         └────────►│   SQLite DB  │ │
│                   └──────────────┘ │
└─────────────────────────────────────┘
         │
         ▼
   ┌──────────────┐
   │  OpenCode    │
   │  CLI (ext.)  │
   └──────────────┘
```

**How it works**:
1. User launches NewWork app
2. Bundled Python backend starts automatically at app launch
3. Flutter UI communicates with localhost API
4. Backend automatically cleans up on app exit
5. All data stored in OS-standard locations

## 🚀 Quick Start

### Prerequisites

- **Development Environment**:
  - Python 3.10+
  - Flutter 3.0+
  - OpenCode CLI (optional)

- **Users (Release Version)**:
  - No prerequisites! Just download and run the executable.

### Release Installation

#### macOS
```bash
# Download and install DMG
open NewWork.dmg
# Drag and drop to Applications folder

# Run
open /Applications/NewWork.app
```

#### Linux
```bash
# Download AppImage
chmod +x NewWork-x86_64.AppImage
./NewWork-x86_64.AppImage

# Or .deb package
sudo dpkg -i newwork_0.2.0_amd64.deb
newwork
```

#### Windows
```bash
# Run Setup.exe to install
NewWork-Setup.exe

# Launch from Start Menu
# Or double-click desktop icon
```

### Development Setup

#### 1. Clone Repository

```bash
git clone https://github.com/eightynine01/newwork.git
cd newwork
```

#### 2. Backend Development Mode

```bash
cd newwork-backend

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run development server
make dev
# Or
uvicorn app.main:app --reload --port 8000
```

Backend runs at `http://localhost:8000`.

API Documentation: http://localhost:8000/docs

#### 3. Frontend Development Mode

```bash
cd newwork-app

# Install dependencies
flutter pub get

# Run app (backend must be running)
flutter run -d macos  # or linux, windows
```

#### 4. Integrated Build

```bash
# From project root
./scripts/build-all.sh

# macOS build only
cd newwork-app && flutter build macos --release

# Windows build only (PowerShell)
.\scripts\build-windows.ps1
```

## 📚 Project Structure

```
newwork/
├── newwork-backend/          # FastAPI Backend
│   ├── app/
│   │   ├── api/             # REST API endpoints
│   │   │   ├── sessions.py  # Session management API
│   │   │   ├── templates.py # Template API
│   │   │   ├── skills.py    # Skill management API
│   │   │   └── ...
│   │   ├── models/          # SQLAlchemy data models
│   │   ├── schemas/         # Pydantic request/response schemas
│   │   ├── services/        # Business logic
│   │   │   ├── opencode_client.py  # OpenCode CLI integration
│   │   │   └── file_service.py
│   │   ├── core/            # App settings and DB
│   │   └── main.py          # FastAPI app entry point
│   ├── tests/               # Backend tests
│   ├── pyproject.toml       # Python project settings
│   ├── newwork.spec         # PyInstaller spec
│   └── build.sh             # Backend build script
│
├── newwork-app/              # Flutter Frontend
│   ├── lib/
│   │   ├── main.dart        # App entry point
│   │   ├── app.dart         # App widget
│   │   ├── features/        # Feature modules
│   │   │   ├── session/     # Session pages
│   │   │   ├── template/    # Template management
│   │   │   ├── dashboard/   # Main dashboard
│   │   │   └── settings/    # Settings
│   │   ├── services/        # Service layer
│   │   │   ├── backend_manager.dart  # Backend process management
│   │   │   ├── api_client.dart       # HTTP API client
│   │   │   └── websocket_service.dart # WebSocket communication
│   │   ├── providers/       # Riverpod state management
│   │   ├── models/          # Data models
│   │   └── widgets/         # Shared widgets
│   ├── pubspec.yaml         # Flutter dependencies
│   └── assets/              # Assets (including backend binary)
│
├── newwork-reference/        # Tauri reference implementation (archived)
│
├── scripts/                  # Build and deployment scripts
│   ├── build-all.sh         # Full platform build
│   ├── build-windows.ps1    # Windows-only build
│   ├── package-macos.sh     # macOS DMG creation
│   └── package-linux.sh     # Linux package creation
│
├── docs/                     # Project documentation
│   ├── architecture.md      # Architecture guide
│   ├── api.md               # API documentation
│   ├── deployment.md        # Deployment guide
│   └── development.md       # Developer guide
│
├── .github/workflows/        # CI/CD pipelines
│   ├── backend-tests.yml    # Backend tests
│   ├── frontend-tests.yml   # Frontend tests
│   └── build-release.yml    # Release build
│
├── Makefile                  # Unified build commands
├── CONTRIBUTING.md           # Contribution guide
├── CODE_OF_CONDUCT.md        # Code of conduct
├── CHANGELOG.md              # Changelog
├── LICENSE                   # MIT License
└── README.md                 # This file
```

## 🔧 Configuration

### Data Storage Locations

NewWork stores data in OS-standard locations:

- **macOS**: `~/Library/Application Support/NewWork/`
- **Linux**: `~/.local/share/NewWork/`
- **Windows**: `%APPDATA%\NewWork\`

Database file: `newwork.db`

### Development Environment Variables (.env)

Backend development `.env` file settings:

```env
# Application settings
APP_NAME=NewWork API
APP_VERSION=0.2.0
DEBUG=True

# Server settings
HOST=127.0.0.1
PORT=8000

# OpenCode CLI settings
OPENCODE_URL=http://localhost:8080
OPENCODE_TIMEOUT=30

# Database (development mode)
DATABASE_URL=sqlite:///./newwork-dev.db

# CORS (development mode)
CORS_ORIGINS=http://localhost:*
```

## 🧪 Testing

### Backend Tests

```bash
cd newwork-backend

# Run all tests
make test
# Or
pytest

# With coverage
pytest --cov=app tests/

# Specific tests
pytest tests/api/test_sessions.py
```

### Frontend Tests

```bash
cd newwork-app

# Widget tests
flutter test

# Integration tests
flutter test integration_test/
```

### Integration Tests

```bash
# Full build and run test
./scripts/build-all.sh

# macOS
open newwork-app/build/macos/Build/Products/Release/NewWork.app

# Test checklist:
# - Backend auto-starts on app launch
# - Create new session
# - Send messages and receive real-time responses
# - Save and load templates
# - Backend cleans up on app exit
```

## 📖 API Documentation

After running the backend, API documentation is available at:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

### Key Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/v1/sessions` | GET, POST | Session management |
| `/api/v1/sessions/{id}/messages` | POST | Send message |
| `/api/v1/templates` | GET, POST | Template management |
| `/api/v1/skills` | GET, POST | Skill management |
| `/api/v1/workspaces` | GET, POST | Workspace management |
| `/api/v1/mcp` | GET, POST | MCP server management |
| `/ws/session/{id}` | WebSocket | Real-time session streaming |

## 🛠️ Development Guide

### Makefile Commands

```bash
# Help
make help

# Run development server (backend + frontend)
make dev

# Full build
make build-all

# Platform-specific builds
make build-macos
make build-linux
make build-windows

# Tests
make test

# Clean
make clean
```

### Code Quality

**Backend (Python)**:
```bash
cd newwork-backend

# Formatting
make format

# Lint
make lint

# Type check
make typecheck

# Security check
make security
```

**Frontend (Flutter)**:
```bash
cd newwork-app

# Analysis
flutter analyze

# Formatting
dart format lib/
```

## 🎯 Roadmap

### v0.2.0 (Current) - Integrated App
- [x] Project rename (OpenWork → NewWork)
- [x] Python backend standalone executable (PyInstaller)
- [ ] Flutter app backend integration
- [ ] Cross-platform build pipeline
- [ ] First release deployment

### v0.3.0 - Core Feature Enhancement
- [ ] Enhanced session management
- [ ] Template library
- [ ] Plugin marketplace
- [ ] Dark/Light theme

### v0.4.0 - Collaboration Features
- [ ] Workspace sharing
- [ ] Template export/import
- [ ] Cloud backup (optional)

### v1.0.0 - Production Release
- [ ] Complete feature set
- [ ] Comprehensive documentation
- [ ] Auto-update
- [ ] Community support

## 🔄 Similar Projects Comparison

See how NewWork differs from other AI coding assistant projects.

| Feature | NewWork | [OpenWork](https://github.com/different-ai/openwork) | [Moltbot](https://github.com/moltbot/moltbot) |
|---------|---------|----------|---------|
| ⭐ GitHub Stars | ![GitHub stars](https://img.shields.io/github/stars/eightynine01/newwork?style=social) | ![GitHub stars](https://img.shields.io/github/stars/different-ai/openwork?style=social) | ![GitHub stars](https://img.shields.io/github/stars/moltbot/moltbot?style=social) |
| 🎯 Core Goal | Integrated Desktop App | Agent Workflows | Personal AI Assistant |
| 🖥️ Frontend | Flutter | SolidJS + TailwindCSS | Node.js CLI |
| ⚙️ Backend | FastAPI (Python) | OpenCode CLI (spawned) | TypeScript |
| 📦 Desktop | Native (Flutter) | Tauri 2.x (Rust) | Electron/Native |
| 💾 Database | SQLite (local) | IndexedDB | Local files |
| 🔌 Messaging Integration | ❌ | WhatsApp (owpenbot) | WhatsApp, Telegram, Discord, Slack, etc. |
| 📱 Mobile | ✅ (Flutter) | ❌ | ❌ |
| 🚀 Installation | Single executable | DMG/source build | CLI install |
| 🔧 OpenCode Dependency | Optional | Required | Independent |

### Why NewWork?

1. **True All-in-One**: Backend fully embedded in app, no separate setup needed
2. **Flutter-Based**: Easy mobile expansion with Material Design 3
3. **Python Backend**: Easy to extend and customize with FastAPI architecture
4. **Privacy First**: All data stored locally, no external server required

## 🤝 Contributing

**We welcome all forms of contribution!** 🎉

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
[![Good First Issues](https://img.shields.io/github/issues/eightynine01/newwork/good%20first%20issue?color=7057ff&label=good%20first%20issues)](https://github.com/eightynine01/newwork/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

### 🌟 Ways to Contribute

| Type | Description |
|------|-------------|
| 🐛 **Bug Report** | Found a problem? [Open an issue](https://github.com/eightynine01/newwork/issues/new?template=bug_report.md) |
| 💡 **Feature Request** | Have an idea? [Suggest it](https://github.com/eightynine01/newwork/issues/new?template=feature_request.md) |
| 📝 **Documentation** | Typo fixes, translations, guide additions all welcome |
| 🔧 **Code Contribution** | Send a PR! OpenCode-related PRs especially welcome |
| ⭐ **Star** | If you like the project, give it a Star! |

### Development Flow

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/newwork.git
cd newwork

# 2. Create feature branch
git checkout -b feature/amazing-feature

# 3. Commit changes
git commit -m "feat: add amazing feature"

# 4. Create PR
git push origin feature/amazing-feature
```

### Development Guidelines

- **Code Style**: Python uses Ruff, Dart uses `dart format`
- **Tests**: All PRs should include tests
- **Documentation**: New features should be documented
- **Commit Messages**: [Conventional Commits](https://www.conventionalcommits.org/) format recommended

## ☕ Support

If you find this project useful, buy me a coffee! ☕

<a href="https://www.buymeacoffee.com/newwork" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50">
</a>

[![PayPal](https://img.shields.io/badge/PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white)](https://paypal.me/newwork)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/newwork)

> Donations will be used for server costs, domains, and better feature development.

## 📄 License

This project is distributed under the MIT License. See [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Claude Code](https://claude.ai/code) - AI coding assistant
- [FastAPI](https://fastapi.tiangolo.com/) - Modern Python web framework
- [Flutter](https://flutter.dev/) - Cross-platform UI framework
- [PyInstaller](https://www.pyinstaller.org/) - Python executable bundler
- [Riverpod](https://riverpod.dev/) - Flutter state management

## 📞 Contact & Support

- **Issue Tracker**: [GitHub Issues](https://github.com/eightynine01/newwork/issues)
- **Discussions**: [GitHub Discussions](https://github.com/eightynine01/newwork/discussions)
- **Documentation**: [docs/](docs/)

## 📊 Project Status

Current Version: **0.2.0** (In Development)

This project is actively under development. APIs may change before v1.0.0 release.

### Tech Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Frontend | Flutter | 3.0+ |
| Backend | FastAPI | 0.109+ |
| Database | SQLite | 3.0+ |
| State Management | Riverpod | 2.5+ |
| API Client | Dio | 5.4+ |
| Packaging | PyInstaller | 6.0+ |

---

**Made with ❤️ by the NewWork Team**
