"""
Tool Execution Service.

This module handles the execution of tools requested by the LLM,
including permission management and result formatting.
"""

import asyncio
import logging
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set
from uuid import uuid4

from app.tools import (
    Tool,
    ToolContext,
    ToolResult,
    get_tool,
    get_all_tools,
    initialize_tools,
)
from app.services.llm.base import ToolDefinition, ToolUse, ToolResult as LLMToolResult

logger = logging.getLogger(__name__)


@dataclass
class PendingPermission:
    """A pending permission request."""

    id: str
    session_id: str
    tool_name: str
    arguments: Dict[str, Any]
    description: str
    created_at: datetime
    callback: Optional[Callable[[], None]] = None


@dataclass
class ToolExecutionService:
    """
    Service for executing tools requested by the LLM.

    Manages tool execution, permission requests, and result formatting.
    """

    workspace_path: Path
    session_id: str
    user_id: Optional[str] = None
    allowed_paths: List[Path] = field(default_factory=list)
    environment: Dict[str, str] = field(default_factory=dict)

    # Permission management
    _pending_permissions: Dict[str, PendingPermission] = field(default_factory=dict)
    _approved_tools: Set[str] = field(default_factory=set)  # Tools approved for session
    _always_approved: Set[str] = field(default_factory=set)  # Tools approved permanently

    # Event callbacks
    on_permission_request: Optional[Callable[[PendingPermission], None]] = None
    on_tool_start: Optional[Callable[[str, Dict[str, Any]], None]] = None
    on_tool_complete: Optional[Callable[[str, ToolResult], None]] = None

    def __post_init__(self):
        """Initialize tools if not already done."""
        initialize_tools()

    def get_tool_context(self) -> ToolContext:
        """Create a tool context for execution."""
        return ToolContext(
            workspace_path=self.workspace_path,
            session_id=self.session_id,
            user_id=self.user_id,
            allowed_paths=self.allowed_paths,
            environment=self.environment,
        )

    def get_available_tools(self) -> List[ToolDefinition]:
        """
        Get all available tools as LLM tool definitions.

        Returns:
            List of ToolDefinition for LLM API
        """
        tools = get_all_tools()
        return [
            ToolDefinition(
                name=t.name,
                description=t.description,
                input_schema=t.input_schema,
            )
            for t in tools
        ]

    def _needs_permission(self, tool: Tool, arguments: Dict[str, Any]) -> bool:
        """
        Check if a tool execution needs permission.

        Args:
            tool: The tool to check
            arguments: The arguments for the tool

        Returns:
            True if permission is needed
        """
        if not tool.requires_permission:
            return False

        # Check if tool is always approved
        if tool.name in self._always_approved:
            return False

        # Check if tool is approved for this session
        if tool.name in self._approved_tools:
            return False

        return True

    async def request_permission(
        self,
        tool: Tool,
        arguments: Dict[str, Any],
    ) -> PendingPermission:
        """
        Create a permission request for a tool execution.

        Args:
            tool: The tool requesting permission
            arguments: The arguments for the tool

        Returns:
            PendingPermission object
        """
        # Generate description
        if tool.name == "bash":
            desc = f"Execute command: {arguments.get('command', '')[:100]}"
        elif tool.name in ("write_file", "edit_file"):
            desc = f"{tool.name}: {arguments.get('file_path', 'unknown')}"
        else:
            desc = f"{tool.name} with arguments: {str(arguments)[:100]}"

        permission = PendingPermission(
            id=str(uuid4()),
            session_id=self.session_id,
            tool_name=tool.name,
            arguments=arguments,
            description=desc,
            created_at=datetime.utcnow(),
        )

        self._pending_permissions[permission.id] = permission

        # Notify listener
        if self.on_permission_request:
            self.on_permission_request(permission)

        return permission

    def respond_permission(
        self,
        permission_id: str,
        approved: bool,
        always: bool = False,
    ) -> bool:
        """
        Respond to a permission request.

        Args:
            permission_id: ID of the permission request
            approved: Whether to approve the request
            always: If approved, whether to always approve this tool

        Returns:
            True if the permission was found and processed
        """
        if permission_id not in self._pending_permissions:
            return False

        permission = self._pending_permissions.pop(permission_id)

        if approved:
            if always:
                self._always_approved.add(permission.tool_name)
            else:
                self._approved_tools.add(permission.tool_name)

            # Execute callback if set
            if permission.callback:
                permission.callback()

        return True

    def get_pending_permissions(self) -> List[PendingPermission]:
        """Get all pending permission requests."""
        return list(self._pending_permissions.values())

    async def execute_tool(
        self,
        tool_use: ToolUse,
        *,
        skip_permission: bool = False,
    ) -> LLMToolResult:
        """
        Execute a tool use request.

        Args:
            tool_use: The tool use request from the LLM
            skip_permission: Skip permission check (for approved tools)

        Returns:
            LLMToolResult for sending back to the LLM
        """
        tool = get_tool(tool_use.name)

        if not tool:
            return LLMToolResult(
                tool_use_id=tool_use.id,
                content=f"Error: Unknown tool '{tool_use.name}'",
                is_error=True,
            )

        # Validate arguments
        validation_error = tool.validate_arguments(tool_use.arguments)
        if validation_error:
            return LLMToolResult(
                tool_use_id=tool_use.id,
                content=f"Error: {validation_error}",
                is_error=True,
            )

        # Check permission
        if not skip_permission and self._needs_permission(tool, tool_use.arguments):
            permission = await self.request_permission(tool, tool_use.arguments)
            return LLMToolResult(
                tool_use_id=tool_use.id,
                content=f"Permission required for {tool.name}. Request ID: {permission.id}",
                is_error=True,
            )

        # Notify tool start
        if self.on_tool_start:
            self.on_tool_start(tool_use.name, tool_use.arguments)

        # Execute tool
        try:
            context = self.get_tool_context()
            result = await tool.execute(tool_use.arguments, context)
        except Exception as e:
            logger.error(f"Tool execution error: {e}")
            result = ToolResult.error_result(f"Execution error: {str(e)}")

        # Notify tool complete
        if self.on_tool_complete:
            self.on_tool_complete(tool_use.name, result)

        # Convert to LLM format
        if result.success:
            return LLMToolResult(
                tool_use_id=tool_use.id,
                content=result.output,
                is_error=False,
            )
        else:
            return LLMToolResult(
                tool_use_id=tool_use.id,
                content=result.error or "Unknown error",
                is_error=True,
            )

    async def execute_tools(
        self,
        tool_uses: List[ToolUse],
        *,
        parallel: bool = True,
    ) -> List[LLMToolResult]:
        """
        Execute multiple tool uses.

        Args:
            tool_uses: List of tool use requests
            parallel: Execute in parallel if possible

        Returns:
            List of LLMToolResult
        """
        if parallel:
            tasks = [self.execute_tool(tu) for tu in tool_uses]
            return await asyncio.gather(*tasks)
        else:
            results = []
            for tu in tool_uses:
                result = await self.execute_tool(tu)
                results.append(result)
            return results
