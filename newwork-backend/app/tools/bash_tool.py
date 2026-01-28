"""
Bash command execution tool.

This module provides a tool for executing bash commands
in a controlled environment.
"""

import asyncio
import os
import shlex
from typing import Any, Dict, Optional

from .base import Tool, ToolCategory, ToolContext, ToolResult, register_tool


# Commands that are explicitly blocked for security
BLOCKED_COMMANDS = {
    "rm -rf /",
    "rm -rf /*",
    "mkfs",
    "> /dev/sda",
    "dd if=/dev/zero",
    ":(){:|:&};:",  # Fork bomb
    "chmod -R 777 /",
    "curl | sh",
    "wget | sh",
    "curl | bash",
    "wget | bash",
}

# Patterns that indicate dangerous operations
DANGEROUS_PATTERNS = [
    "rm -rf /",
    "rm -rf /*",
    "> /dev/",
    "mkfs.",
    "dd if=",
    ":(){",
    "chmod -R 777 /",
]


class BashTool(Tool):
    """Execute bash commands."""

    name = "bash"
    description = (
        "Execute a bash command in the workspace directory. "
        "Use for running scripts, git operations, build commands, etc."
    )
    category = ToolCategory.BASH
    requires_permission = True

    @property
    def input_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "command": {
                    "type": "string",
                    "description": "The bash command to execute",
                },
                "timeout": {
                    "type": "integer",
                    "description": "Command timeout in seconds (default: 30, max: 300)",
                },
                "description": {
                    "type": "string",
                    "description": "Brief description of what the command does",
                },
            },
            "required": ["command"],
        }

    def _is_command_safe(self, command: str) -> Optional[str]:
        """
        Check if a command is safe to execute.

        Args:
            command: The command to check

        Returns:
            Error message if unsafe, None if safe
        """
        # Check for explicitly blocked commands
        for blocked in BLOCKED_COMMANDS:
            if blocked in command:
                return f"Blocked command pattern detected: {blocked}"

        # Check for dangerous patterns
        for pattern in DANGEROUS_PATTERNS:
            if pattern in command:
                return f"Dangerous pattern detected: {pattern}"

        return None

    async def execute(
        self,
        arguments: Dict[str, Any],
        context: ToolContext,
    ) -> ToolResult:
        command = arguments["command"]
        timeout = min(arguments.get("timeout", 30), 300)  # Max 5 minutes
        description = arguments.get("description", "")

        # Safety check
        safety_error = self._is_command_safe(command)
        if safety_error:
            return ToolResult.error_result(f"Command blocked: {safety_error}")

        try:
            # Set up environment
            env = os.environ.copy()
            env.update(context.environment)

            # Execute command
            process = await asyncio.create_subprocess_shell(
                command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(context.workspace_path),
                env=env,
            )

            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=timeout,
                )
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                return ToolResult.error_result(
                    f"Command timed out after {timeout} seconds"
                )

            # Decode output
            stdout_str = stdout.decode("utf-8", errors="replace")
            stderr_str = stderr.decode("utf-8", errors="replace")

            # Build output
            output_parts = []

            if stdout_str:
                output_parts.append(stdout_str)

            if stderr_str:
                if output_parts:
                    output_parts.append(f"\n[stderr]\n{stderr_str}")
                else:
                    output_parts.append(f"[stderr]\n{stderr_str}")

            output = "".join(output_parts) if output_parts else "(no output)"

            # Truncate if too long
            max_output = 30000
            if len(output) > max_output:
                output = output[:max_output] + f"\n... (truncated, total {len(output)} chars)"

            # Check exit code
            if process.returncode != 0:
                return ToolResult(
                    success=False,
                    output=output,
                    error=f"Command exited with code {process.returncode}",
                    metadata={
                        "exit_code": process.returncode,
                        "command": command,
                    },
                )

            return ToolResult.success_result(
                output,
                exit_code=process.returncode,
                command=command,
            )

        except Exception as e:
            return ToolResult.error_result(f"Error executing command: {str(e)}")


# Register the bash tool
def register_bash_tools() -> None:
    """Register bash execution tools."""
    register_tool(BashTool())
