import json
import os
import platform
from pathlib import Path
from pydantic_settings import BaseSettings
from typing import Optional, Dict, Any
from datetime import datetime
import uuid


class Settings(BaseSettings):
    """
    Application settings.

    Configuration loaded from environment variables.
    """

    # Application
    APP_NAME: str = "NewWork API"
    APP_VERSION: str = "0.3.0"
    DEBUG: bool = False

    # Server
    HOST: str = "127.0.0.1"  # 로컬 전용 (통합 앱)
    PORT: int = 8000

    # LLM Provider API Keys
    ANTHROPIC_API_KEY: Optional[str] = None
    OPENAI_API_KEY: Optional[str] = None
    DEEPSEEK_API_KEY: Optional[str] = None
    MINIMAX_API_KEY: Optional[str] = None
    ZAI_API_KEY: Optional[str] = None

    # Default LLM settings
    DEFAULT_PROVIDER: str = "anthropic"
    DEFAULT_MODEL: str = "claude-sonnet-4-20250514"

    # Database (동적 경로 사용)
    _DATABASE_URL: Optional[str] = None

    # CORS (로컬 전용)
    CORS_ORIGINS: list[str] = ["http://localhost:*"]

    @property
    def data_dir(self) -> Path:
        """
        OS별 표준 데이터 디렉토리 경로 반환.

        Returns:
            데이터 디렉토리 Path 객체
        """
        system = platform.system()

        if system == "Darwin":  # macOS
            base = Path.home() / "Library" / "Application Support"
        elif system == "Windows":
            base = Path(os.getenv("APPDATA", str(Path.home() / "AppData" / "Roaming")))
        else:  # Linux 및 기타 Unix 계열
            base = Path.home() / ".local" / "share"

        data_path = base / "NewWork"
        data_path.mkdir(parents=True, exist_ok=True)
        return data_path

    @property
    def DATABASE_URL(self) -> str:
        """
        데이터베이스 URL 반환 (OS별 표준 위치 사용).

        Returns:
            SQLite 데이터베이스 URL
        """
        if self._DATABASE_URL:
            return self._DATABASE_URL

        db_path = self.data_dir / "newwork.db"
        return f"sqlite:///{db_path}"

    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"  # 정의되지 않은 환경 변수 무시


# Global settings instance
settings = Settings()


class ConfigService:
    """
    Service for managing application configuration.
    """

    @staticmethod
    def get_settings() -> Settings:
        """
        Get the current application settings.

        Returns:
            Settings object with current configuration
        """
        return settings

    @staticmethod
    def get_api_key(provider: str) -> Optional[str]:
        """
        Get API key for a specific provider.

        Args:
            provider: Provider name (anthropic, openai, deepseek, minimax, zai)

        Returns:
            API key if configured, None otherwise
        """
        key_map = {
            "anthropic": settings.ANTHROPIC_API_KEY,
            "openai": settings.OPENAI_API_KEY,
            "deepseek": settings.DEEPSEEK_API_KEY,
            "minimax": settings.MINIMAX_API_KEY,
            "zai": settings.ZAI_API_KEY,
        }
        return key_map.get(provider.lower())

    @staticmethod
    def get_default_provider() -> str:
        """
        Get the default LLM provider.

        Returns:
            Default provider name
        """
        return settings.DEFAULT_PROVIDER

    @staticmethod
    def get_default_model() -> str:
        """
        Get the default LLM model.

        Returns:
            Default model identifier
        """
        return settings.DEFAULT_MODEL

    @staticmethod
    def get_available_providers() -> list[str]:
        """
        Get list of providers with configured API keys.

        Returns:
            List of available provider names
        """
        providers = []
        if settings.ANTHROPIC_API_KEY:
            providers.append("anthropic")
        if settings.OPENAI_API_KEY:
            providers.append("openai")
        if settings.DEEPSEEK_API_KEY:
            providers.append("deepseek")
        if settings.MINIMAX_API_KEY:
            providers.append("minimax")
        if settings.ZAI_API_KEY:
            providers.append("zai")
        return providers

    @staticmethod
    def is_debug() -> bool:
        """
        Check if debug mode is enabled.

        Returns:
            True if debug mode is enabled
        """
        return settings.DEBUG

    # OpenCode Configuration Methods

    @staticmethod
    def _get_opencode_path(scope: str, workspace_path: Optional[str] = None) -> Path:
        """
        Get the opencode.json file path based on scope.

        Args:
            scope: Either 'project' or 'global'
            workspace_path: Required for project scope

        Returns:
            Path to opencode.json
        """
        if scope == "project":
            if not workspace_path:
                raise ValueError("workspace_path is required for project scope")
            return Path(workspace_path) / "opencode.json"
        elif scope == "global":
            # Global config in user's home directory
            home = Path.home()
            opencode_dir = home / ".config" / "opencode"
            opencode_dir.mkdir(parents=True, exist_ok=True)
            return opencode_dir / "opencode.json"
        else:
            raise ValueError(f"Invalid scope: {scope}. Must be 'project' or 'global'")

    @staticmethod
    def read_opencode_json(
        workspace_path: Optional[str] = None, scope: str = "global"
    ) -> Dict[str, Any]:
        """
        Read opencode.json file.

        Args:
            scope: Either 'project' or 'global'
            workspace_path: Required for project scope

        Returns:
            Dictionary containing the configuration
        """
        config_path = ConfigService._get_opencode_path(scope, workspace_path)

        if not config_path.exists():
            # Return empty config with schema
            return {
                "$schema": "https://opencode.ai/config.json",
                "plugin": [],
                "mcp": {},
            }

        with open(config_path, "r") as f:
            return json.load(f)

    @staticmethod
    def write_opencode_json(
        config: Dict[str, Any],
        workspace_path: Optional[str] = None,
        scope: str = "global",
    ) -> None:
        """
        Write opencode.json file.

        Args:
            scope: Either 'project' or 'global'
            workspace_path: Required for project scope
            config: Configuration dictionary to write
        """
        config_path = ConfigService._get_opencode_path(scope, workspace_path)

        # Ensure directory exists
        config_path.parent.mkdir(parents=True, exist_ok=True)

        # Ensure schema is present
        if "$schema" not in config:
            config["$schema"] = "https://opencode.ai/config.json"

        # Ensure required keys exist
        if "plugin" not in config:
            config["plugin"] = []
        if "mcp" not in config:
            config["mcp"] = {}

        with open(config_path, "w") as f:
            json.dump(config, f, indent=2)

    @staticmethod
    def add_plugin_to_config(
        plugin_name: str,
        workspace_path: Optional[str] = None,
        config: Optional[Dict[str, Any]] = None,
        scope: str = "global",
    ) -> Dict[str, Any]:
        """
        Add a plugin to opencode.json configuration.

        Args:
            scope: Either 'project' or 'global'
            workspace_path: Required for project scope
            plugin_name: Name of the plugin to add
            config: Optional configuration for the plugin

        Returns:
            Updated configuration dictionary
        """
        current_config = ConfigService.read_opencode_json(workspace_path, scope)

        # Initialize plugin list if not present
        if "plugin" not in current_config or not isinstance(
            current_config["plugin"], list
        ):
            current_config["plugin"] = []

        # Check if plugin already exists
        if plugin_name not in current_config["plugin"]:
            current_config["plugin"].append(plugin_name)

        # If there's MCP configuration for this plugin, add it
        if config:
            if "mcp" not in current_config:
                current_config["mcp"] = {}
            current_config["mcp"][plugin_name] = config

        ConfigService.write_opencode_json(current_config, workspace_path, scope)
        return current_config

    @staticmethod
    def remove_plugin_from_config(
        plugin_name: str, workspace_path: Optional[str] = None, scope: str = "global"
    ) -> Dict[str, Any]:
        """
        Remove a plugin from opencode.json configuration.

        Args:
            scope: Either 'project' or 'global'
            workspace_path: Required for project scope
            plugin_name: Name of the plugin to remove

        Returns:
            Updated configuration dictionary
        """
        current_config = ConfigService.read_opencode_json(workspace_path, scope)

        # Remove from plugin list
        if "plugin" in current_config and isinstance(current_config["plugin"], list):
            current_config["plugin"] = [
                p for p in current_config["plugin"] if p != plugin_name
            ]

        # Remove from mcp configuration
        if "mcp" in current_config and plugin_name in current_config["mcp"]:
            del current_config["mcp"][plugin_name]

        ConfigService.write_opencode_json(current_config, workspace_path, scope)
        return current_config

    @staticmethod
    def list_plugins(
        workspace_path: Optional[str] = None, scope: str = "global"
    ) -> list:
        """
        List all configured plugins from opencode.json.

        Args:
            scope: Either 'project' or 'global'
            workspace_path: Required for project scope

        Returns:
            List of plugin objects with id, name, scope, config, etc.
        """
        current_config = ConfigService.read_opencode_json(workspace_path, scope)
        plugins = []

        # Process plugin list
        plugin_list = current_config.get("plugin", [])
        mcp_config = current_config.get("mcp", {})

        for plugin_name in plugin_list:
            plugin_config = mcp_config.get(plugin_name, {})
            enabled = plugin_config.get("enabled", True)

            plugin = {
                "id": str(uuid.uuid4()),
                "name": plugin_name,
                "scope": scope,
                "is_enabled": enabled,
                "config": plugin_config if plugin_config else None,
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat(),
            }
            plugins.append(plugin)

        return plugins

    # MCP Server Management Methods

    @staticmethod
    def add_mcp_server(
        name: str,
        server_type: str = "remote",
        endpoint: str = "",
        workspace_path: Optional[str] = None,
        scope: str = "global",
        config: Optional[Dict[str, Any]] = None,
        description: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Add an MCP server to opencode.json configuration.

        Args:
            name: Name/ID of the MCP server
            server_type: Either 'remote' or 'local'
            endpoint: URL for remote servers, command/path for local servers
            workspace_path: Optional workspace path for project scope
            scope: Either 'project' or 'global'
            config: Additional configuration (env vars, oauth settings, etc.)
            description: Optional description of the server

        Returns:
            Updated configuration dictionary
        """
        current_config = ConfigService.read_opencode_json(workspace_path, scope)

        # Initialize mcp section if not present
        if "mcp" not in current_config:
            current_config["mcp"] = {}

        # Add server configuration
        server_config = {
            "type": server_type,
            "enabled": True,
            "status": "disconnected",
            "created_at": datetime.now().isoformat(),
        }

        if server_type == "remote" and endpoint:
            server_config["url"] = endpoint
        elif server_type == "local" and endpoint:
            server_config["path"] = endpoint

        if description:
            server_config["description"] = description

        if config:
            server_config["config"] = config

        current_config["mcp"][name] = server_config

        ConfigService.write_opencode_json(current_config, workspace_path, scope)
        return current_config

    @staticmethod
    def remove_mcp_server(
        name: str,
        workspace_path: Optional[str] = None,
        scope: str = "global",
    ) -> Dict[str, Any]:
        """
        Remove an MCP server from opencode.json configuration.

        Args:
            name: Name/ID of the MCP server to remove
            workspace_path: Optional workspace path for project scope
            scope: Either 'project' or 'global'

        Returns:
            Updated configuration dictionary

        Raises:
            KeyError: If server with given name doesn't exist
        """
        current_config = ConfigService.read_opencode_json(workspace_path, scope)

        if "mcp" not in current_config:
            raise KeyError(f"MCP server '{name}' not found")

        if name not in current_config["mcp"]:
            raise KeyError(f"MCP server '{name}' not found")

        del current_config["mcp"][name]

        ConfigService.write_opencode_json(current_config, workspace_path, scope)
        return current_config

    @staticmethod
    def list_mcp_servers(
        workspace_path: Optional[str] = None,
        scope: str = "global",
    ) -> list:
        """
        List all configured MCP servers from opencode.json.

        Args:
            workspace_path: Optional workspace path for project scope
            scope: Either 'project' or 'global'

        Returns:
            List of MCP server objects with id, name, type, status, config, etc.
        """
        current_config = ConfigService.read_opencode_json(workspace_path, scope)
        servers = []

        mcp_config = current_config.get("mcp", {})

        for server_name, server_config in mcp_config.items():
            server_type = server_config.get("type", "remote")
            status = server_config.get("status", "disconnected")

            # Determine endpoint based on type
            endpoint = ""
            if server_type == "remote":
                endpoint = server_config.get("url", "")
            elif server_type == "local":
                endpoint = server_config.get("path", "")

            server = {
                "id": server_name,
                "name": server_name,
                "endpoint": endpoint,
                "server_type": server_type,
                "status": status,
                "description": server_config.get("description"),
                "available_tools": server_config.get("available_tools", []),
                "capabilities": server_config.get("capabilities"),
                "created_at": server_config.get(
                    "created_at", datetime.now().isoformat()
                ),
                "last_connected_at": server_config.get("last_connected_at"),
                "config": server_config.get("config"),
                "enabled": server_config.get("enabled", True),
            }
            servers.append(server)

        return servers

    @staticmethod
    def update_mcp_server_status(
        name: str,
        status: str,
        workspace_path: Optional[str] = None,
        scope: str = "global",
        capabilities: Optional[Dict[str, Any]] = None,
        available_tools: Optional[list] = None,
        oauth_tokens: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Update MCP server status and metadata.

        Args:
            name: Name/ID of the MCP server
            status: New status ('connected', 'disconnected', 'connecting', 'error')
            workspace_path: Optional workspace path for project scope
            scope: Either 'project' or 'global'
            capabilities: Optional capabilities dictionary
            available_tools: Optional list of available tool names
            oauth_tokens: Optional OAuth tokens to store

        Returns:
            Updated configuration dictionary

        Raises:
            KeyError: If server with given name doesn't exist
        """
        current_config = ConfigService.read_opencode_json(workspace_path, scope)

        if "mcp" not in current_config:
            raise KeyError(f"MCP server '{name}' not found")

        if name not in current_config["mcp"]:
            raise KeyError(f"MCP server '{name}' not found")

        # Update status
        current_config["mcp"][name]["status"] = status

        # Update last_connected_at if connecting/connected
        if status in ["connecting", "connected"]:
            current_config["mcp"][name]["last_connected_at"] = (
                datetime.now().isoformat()
            )

        # Update capabilities if provided
        if capabilities:
            current_config["mcp"][name]["capabilities"] = capabilities

        # Update available_tools if provided
        if available_tools is not None:
            current_config["mcp"][name]["available_tools"] = available_tools

        # Update OAuth tokens in config if provided
        if oauth_tokens:
            if "config" not in current_config["mcp"][name]:
                current_config["mcp"][name]["config"] = {}
            current_config["mcp"][name]["config"].update(oauth_tokens)

        ConfigService.write_opencode_json(current_config, workspace_path, scope)
        return current_config

    @staticmethod
    def get_mcp_server(
        name: str,
        workspace_path: Optional[str] = None,
        scope: str = "global",
    ) -> Dict[str, Any]:
        """
        Get a specific MCP server configuration.

        Args:
            name: Name/ID of the MCP server
            workspace_path: Optional workspace path for project scope
            scope: Either 'project' or 'global'

        Returns:
            MCP server configuration dictionary

        Raises:
            KeyError: If server with given name doesn't exist
        """
        servers = ConfigService.list_mcp_servers(workspace_path, scope)
        for server in servers:
            if server["id"] == name:
                return server

        raise KeyError(f"MCP server '{name}' not found")

    @staticmethod
    def get_config_file_path(
        workspace_path: Optional[str] = None, scope: str = "global"
    ) -> str:
        """
        Get the path to the opencode.json file.

        Args:
            scope: Either 'project' or 'global'
            workspace_path: Required for project scope

        Returns:
            String path to the config file
        """
        return str(ConfigService._get_opencode_path(scope, workspace_path))

    @staticmethod
    def get_plugin_schema() -> Dict[str, Any]:
        """
        Get the plugin schema.

        Returns:
            Dictionary containing the plugin schema
        """
        return {
            "$schema": "https://opencode.ai/config.json",
            "type": "object",
            "properties": {
                "plugin": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "List of enabled plugin names",
                },
                "mcp": {
                    "type": "object",
                    "description": "MCP server configurations keyed by plugin name",
                    "additionalProperties": {
                        "type": "object",
                        "properties": {
                            "type": {
                                "type": "string",
                                "enum": ["remote", "local"],
                                "description": "Type of MCP server",
                            },
                            "url": {
                                "type": "string",
                                "description": "URL for remote MCP servers",
                            },
                            "enabled": {
                                "type": "boolean",
                                "default": True,
                                "description": "Whether the plugin is enabled",
                            },
                        },
                    },
                },
            },
        }
