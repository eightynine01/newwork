"""
Base Tool interface and common types.

This module defines the abstract interface that all tools must implement,
along with common data structures for tool execution.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any, Dict, List, Optional


class ToolCategory(str, Enum):
    """Categories of tools."""

    FILE = "file"
    BASH = "bash"
    SEARCH = "search"
    WEB = "web"
    MCP = "mcp"


@dataclass
class ToolContext:
    """
    Context for tool execution.

    Provides necessary information for tools to execute safely
    within the appropriate scope.
    """

    workspace_path: Path
    session_id: str
    user_id: Optional[str] = None
    allowed_paths: List[Path] = field(default_factory=list)
    environment: Dict[str, str] = field(default_factory=dict)
    timeout: int = 30  # seconds

    def is_path_allowed(self, path: Path) -> bool:
        """
        Check if a path is within allowed boundaries.

        Args:
            path: Path to check

        Returns:
            True if the path is allowed
        """
        # Resolve to absolute path
        resolved = path.resolve()

        # Always allow paths within workspace
        if resolved.is_relative_to(self.workspace_path.resolve()):
            return True

        # Check against explicitly allowed paths
        for allowed in self.allowed_paths:
            if resolved.is_relative_to(allowed.resolve()):
                return True

        return False

    def resolve_path(self, path_str: str) -> Path:
        """
        Resolve a path string relative to workspace.

        Args:
            path_str: Path string (absolute or relative)

        Returns:
            Resolved absolute Path

        Raises:
            ValueError: If the path is outside allowed boundaries
        """
        path = Path(path_str)

        # If not absolute, resolve relative to workspace
        if not path.is_absolute():
            path = self.workspace_path / path

        path = path.resolve()

        if not self.is_path_allowed(path):
            raise ValueError(f"Path '{path}' is outside allowed boundaries")

        return path


@dataclass
class ToolResult:
    """
    Result of a tool execution.

    Contains the output, error status, and any metadata from the execution.
    """

    success: bool
    output: str
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    @classmethod
    def success_result(cls, output: str, **metadata: Any) -> "ToolResult":
        """Create a successful result."""
        return cls(success=True, output=output, metadata=metadata)

    @classmethod
    def error_result(cls, error: str, **metadata: Any) -> "ToolResult":
        """Create an error result."""
        return cls(success=False, output="", error=error, metadata=metadata)


class Tool(ABC):
    """
    Abstract base class for tools.

    All tools must implement this interface to be usable by the LLM.
    """

    name: str
    description: str
    category: ToolCategory
    requires_permission: bool = True

    @property
    @abstractmethod
    def input_schema(self) -> Dict[str, Any]:
        """
        JSON Schema for the tool's input parameters.

        Returns:
            JSON Schema dictionary
        """
        pass

    @abstractmethod
    async def execute(
        self,
        arguments: Dict[str, Any],
        context: ToolContext,
    ) -> ToolResult:
        """
        Execute the tool with the given arguments.

        Args:
            arguments: Tool arguments matching the input_schema
            context: Execution context

        Returns:
            ToolResult containing the output or error
        """
        pass

    def validate_arguments(self, arguments: Dict[str, Any]) -> Optional[str]:
        """
        Validate tool arguments against the schema.

        Args:
            arguments: Arguments to validate

        Returns:
            Error message if validation fails, None otherwise
        """
        schema = self.input_schema
        required = schema.get("required", [])

        # Check required fields
        for field in required:
            if field not in arguments:
                return f"Missing required field: {field}"

        # Check field types (basic validation)
        properties = schema.get("properties", {})
        for key, value in arguments.items():
            if key in properties:
                expected_type = properties[key].get("type")
                if expected_type:
                    if expected_type == "string" and not isinstance(value, str):
                        return f"Field '{key}' must be a string"
                    elif expected_type == "integer" and not isinstance(value, int):
                        return f"Field '{key}' must be an integer"
                    elif expected_type == "number" and not isinstance(value, (int, float)):
                        return f"Field '{key}' must be a number"
                    elif expected_type == "boolean" and not isinstance(value, bool):
                        return f"Field '{key}' must be a boolean"
                    elif expected_type == "array" and not isinstance(value, list):
                        return f"Field '{key}' must be an array"
                    elif expected_type == "object" and not isinstance(value, dict):
                        return f"Field '{key}' must be an object"

        return None

    def to_llm_tool(self) -> Dict[str, Any]:
        """
        Convert to LLM tool definition format.

        Returns:
            Tool definition for LLM API
        """
        from app.services.llm.base import ToolDefinition

        return ToolDefinition(
            name=self.name,
            description=self.description,
            input_schema=self.input_schema,
        )


# Tool registry
_TOOLS: Dict[str, Tool] = {}


def register_tool(tool: Tool) -> None:
    """
    Register a tool in the global registry.

    Args:
        tool: Tool instance to register
    """
    _TOOLS[tool.name] = tool


def get_tool(name: str) -> Optional[Tool]:
    """
    Get a tool by name.

    Args:
        name: Tool name

    Returns:
        Tool instance or None if not found
    """
    return _TOOLS.get(name)


def get_all_tools() -> List[Tool]:
    """
    Get all registered tools.

    Returns:
        List of all tools
    """
    return list(_TOOLS.values())


def get_tools_by_category(category: ToolCategory) -> List[Tool]:
    """
    Get tools by category.

    Args:
        category: Tool category

    Returns:
        List of tools in the category
    """
    return [t for t in _TOOLS.values() if t.category == category]


def get_tools_requiring_permission() -> List[Tool]:
    """
    Get tools that require permission.

    Returns:
        List of tools requiring permission
    """
    return [t for t in _TOOLS.values() if t.requires_permission]
