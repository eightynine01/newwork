"""
Tool system for NewWork.

This module provides the tool execution system that enables the LLM
to interact with files, run commands, and access web resources.

Usage:
    from app.tools import get_tool, get_all_tools, ToolContext

    # Initialize tools (call once at startup)
    initialize_tools()

    # Get a specific tool
    tool = get_tool("read_file")

    # Execute a tool
    context = ToolContext(workspace_path=Path("/path/to/workspace"), session_id="...")
    result = await tool.execute({"file_path": "README.md"}, context)
"""

from .base import (
    Tool,
    ToolCategory,
    ToolContext,
    ToolResult,
    get_tool,
    get_all_tools,
    get_tools_by_category,
    get_tools_requiring_permission,
    register_tool,
)
from .file_tools import (
    ReadFileTool,
    WriteFileTool,
    EditFileTool,
    ListDirectoryTool,
    GlobTool,
    register_file_tools,
)
from .bash_tool import BashTool, register_bash_tools
from .grep_tool import GrepTool, register_grep_tools
from .web_tools import WebFetchTool, WebSearchTool, register_web_tools


_initialized = False


def initialize_tools() -> None:
    """
    Initialize and register all tools.

    Call this once at application startup.
    """
    global _initialized
    if _initialized:
        return

    register_file_tools()
    register_bash_tools()
    register_grep_tools()
    register_web_tools()

    _initialized = True


__all__ = [
    # Base types
    "Tool",
    "ToolCategory",
    "ToolContext",
    "ToolResult",
    # Registry functions
    "get_tool",
    "get_all_tools",
    "get_tools_by_category",
    "get_tools_requiring_permission",
    "register_tool",
    # Tool classes
    "ReadFileTool",
    "WriteFileTool",
    "EditFileTool",
    "ListDirectoryTool",
    "GlobTool",
    "BashTool",
    "GrepTool",
    "WebFetchTool",
    "WebSearchTool",
    # Initialization
    "initialize_tools",
]
