# OpenWork Python

FastAPI backend for OpenWork - an OpenCode GUI clone.

## Overview

OpenWork Python provides a REST API backend that integrates with the OpenCode CLI via HTTP API, manages local data using SQLite, and streams real-time updates via Server-Sent Events (SSE).

## Features

- FastAPI web framework with automatic API documentation
- SQLite database with SQLAlchemy ORM
- HTTP client for OpenCode API integration
- CORS support for frontend communication
- Event streaming for real-time updates
- Modular architecture for easy extension
- Test suite with pytest

## Project Structure

```
openwork-python/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application entry point
│   ├── api/                 # API route modules
│   │   ├── __init__.py
│   │   ├── sessions.py      # Session endpoints
│   │   ├── templates.py     # Template endpoints
│   │   ├── skills.py        # Skill endpoints
│   │   ├── plugins.py       # Plugin endpoints
│   │   ├── mcp.py           # MCP endpoints
│   │   ├── workspaces.py    # Workspace endpoints
│   │   ├── permissions.py   # Permission endpoints
│   │   └── providers.py     # Provider endpoints
│   ├── models/              # SQLAlchemy models
│   │   ├── __init__.py
│   │   ├── session.py       # Session model
│   │   ├── template.py      # Template model
│   │   ├── skill.py         # Skill model
│   │   └── workspace.py     # Workspace model
│   ├── services/            # Business logic services
│   │   ├── __init__.py
│   │   ├── opencode_client.py  # OpenCode HTTP client
│   │   ├── config_service.py   # Configuration management
│   │   ├── file_service.py     # File system operations
│   │   └── event_service.py    # Event streaming
│   └── db/                  # Database configuration
│       ├── __init__.py
│       ├── database.py       # SQLAlchemy setup
│       └── repositories.py  # Base repository classes
├── tests/                   # Test suite
│   ├── __init__.py
│   ├── conftest.py          # Test fixtures
│   ├── test_main.py         # Main app tests
│   ├── api/                # API tests
│   └── services/           # Service tests
├── requirements.txt         # Python dependencies
├── pyproject.toml          # Project configuration
└── README.md               # This file
```

## Installation

### Prerequisites

- Python 3.10 or higher
- OpenCode CLI (for API integration)

### Setup

1. Clone the repository:
```bash
cd /Users/phil/workspace/newwork/openwork-python
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Configuration

Configuration is managed through environment variables or a `.env` file:

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_NAME` | OpenWork API | Application name |
| `APP_VERSION` | 0.1.0 | Application version |
| `DEBUG` | False | Debug mode |
| `HOST` | 0.0.0.0 | Server host |
| `PORT` | 8000 | Server port |
| `OPENCODE_URL` | http://localhost:8080 | OpenCode API URL |
| `OPENCODE_TIMEOUT` | 30 | OpenCode API timeout |
| `DATABASE_URL` | sqlite:///./openwork.db | Database URL |
| `CORS_ORIGINS` | http://localhost:3000,http://localhost:8080 | Allowed CORS origins |

Create a `.env` file:
```env
DEBUG=True
OPENCODE_URL=http://localhost:8080
DATABASE_URL=sqlite:///./openwork.db
```

## Running the Application

### Development Mode

```bash
python -m app.main
```

Or using uvicorn directly:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Production Mode

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

The API will be available at `http://localhost:8000`

## API Documentation

Once the server is running, access the interactive API documentation:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

## API Endpoints

### Health Check

- `GET /` - API root endpoint
- `GET /health` - Health check endpoint

### Session Management (sessions.py)

- `GET /sessions` - List sessions
- `POST /sessions` - Create session
- `GET /sessions/{id}` - Get session
- `PUT /sessions/{id}` - Update session
- `DELETE /sessions/{id}` - Delete session

### Templates (templates.py)

- `GET /templates` - List templates
- `POST /templates` - Create template
- `GET /templates/{id}` - Get template
- `PUT /templates/{id}` - Update template
- `DELETE /templates/{id}` - Delete template

### Skills (skills.py)

- `GET /skills` - List skills
- `POST /skills` - Create skill
- `GET /skills/{id}` - Get skill
- `PUT /skills/{id}` - Update skill
- `DELETE /skills/{id}` - Delete skill

### Workspaces (workspaces.py)

- `GET /workspaces` - List workspaces
- `POST /workspaces` - Create workspace
- `GET /workspaces/{id}` - Get workspace
- `PUT /workspaces/{id}` - Update workspace
- `DELETE /workspaces/{id}` - Delete workspace

### Permissions (permissions.py)

- `GET /permissions` - List permissions
- `POST /permissions/{id}/respond` - Respond to permission request

### Plugins (plugins.py)

- `GET /plugins` - List plugins
- `POST /plugins` - Install plugin
- `DELETE /plugins/{id}` - Uninstall plugin

### MCP (mcp.py)

- `GET /mcp` - List MCP servers
- `POST /mcp` - Add MCP server
- `DELETE /mcp/{id}` - Remove MCP server

### Providers (providers.py)

- `GET /providers` - List AI providers
- `POST /providers` - Add provider
- `PUT /providers/{id}` - Update provider
- `DELETE /providers/{id}` - Remove provider

## Running Tests

Run the test suite:

```bash
pytest
```

Run tests with coverage:

```bash
pytest --cov=app tests/
```

Run specific test file:

```bash
pytest tests/test_main.py
```

## OpenCode Integration

The `OpenCodeClient` service provides methods to interact with OpenCode's HTTP API:

```python
from app.services.opencode_client import OpenCodeClient

async with OpenCodeClient() as client:
    # Create a session
    session = await client.create_session(path="/path/to/workspace")
    
    # Send a prompt
    response = await client.send_prompt(
        session_id=session["id"],
        prompt="Hello, OpenCode!"
    )
    
    # Stream events
    async for event in client.stream_events(session_id=session["id"]):
        print(event)
```

## Database

The application uses SQLite as the default database. The database file is created automatically on first run.

### Database Models

- **Session**: Represents OpenCode working sessions
- **Template**: Stores reusable prompt templates
- **Skill**: Manages specialized skills/agents
- **Workspace**: Represents project directories

### Migrations

Currently using SQLAlchemy's automatic schema creation. For production, consider using Alembic for database migrations.

## Development

### Code Style

The project uses:
- **Black** for code formatting
- **isort** for import sorting
- **pylint** for linting

### Formatting Code

```bash
black app/ tests/
isort app/ tests/
```

## License

[Specify your license here]

## Contributing

Contributions are welcome! Please submit pull requests or open issues for bugs and feature requests.
