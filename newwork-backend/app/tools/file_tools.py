"""
File operation tools.

This module provides tools for reading, writing, editing files,
and listing directory contents.
"""

import os
import fnmatch
from pathlib import Path
from typing import Any, Dict, List, Optional

try:
    import aiofiles
    AIOFILES_AVAILABLE = True
except ImportError:
    AIOFILES_AVAILABLE = False

from .base import Tool, ToolCategory, ToolContext, ToolResult, register_tool


class ReadFileTool(Tool):
    """Read the contents of a file."""

    name = "read_file"
    description = "Read the contents of a file at the specified path."
    category = ToolCategory.FILE
    requires_permission = False

    @property
    def input_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "file_path": {
                    "type": "string",
                    "description": "Path to the file to read (absolute or relative to workspace)",
                },
                "offset": {
                    "type": "integer",
                    "description": "Line number to start reading from (1-based). Optional.",
                },
                "limit": {
                    "type": "integer",
                    "description": "Maximum number of lines to read. Optional.",
                },
            },
            "required": ["file_path"],
        }

    async def execute(
        self,
        arguments: Dict[str, Any],
        context: ToolContext,
    ) -> ToolResult:
        file_path_str = arguments["file_path"]
        offset = arguments.get("offset", 1)
        limit = arguments.get("limit")

        try:
            file_path = context.resolve_path(file_path_str)

            if not file_path.exists():
                return ToolResult.error_result(f"File not found: {file_path}")

            if not file_path.is_file():
                return ToolResult.error_result(f"Not a file: {file_path}")

            # Read file content
            if AIOFILES_AVAILABLE:
                async with aiofiles.open(file_path, "r", encoding="utf-8") as f:
                    lines = await f.readlines()
            else:
                with open(file_path, "r", encoding="utf-8") as f:
                    lines = f.readlines()

            # Apply offset and limit
            start_idx = max(0, offset - 1)
            if limit:
                end_idx = start_idx + limit
                lines = lines[start_idx:end_idx]
            else:
                lines = lines[start_idx:]

            # Format with line numbers
            formatted_lines = []
            for i, line in enumerate(lines, start=start_idx + 1):
                formatted_lines.append(f"{i:6d}\t{line.rstrip()}")

            content = "\n".join(formatted_lines)

            return ToolResult.success_result(
                content,
                file_path=str(file_path),
                total_lines=len(lines),
            )

        except UnicodeDecodeError:
            return ToolResult.error_result(
                f"Cannot read file as text (binary file?): {file_path_str}"
            )
        except Exception as e:
            return ToolResult.error_result(str(e))


class WriteFileTool(Tool):
    """Write content to a file."""

    name = "write_file"
    description = "Write content to a file, creating it if it doesn't exist."
    category = ToolCategory.FILE
    requires_permission = True

    @property
    def input_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "file_path": {
                    "type": "string",
                    "description": "Path to the file to write (absolute or relative to workspace)",
                },
                "content": {
                    "type": "string",
                    "description": "Content to write to the file",
                },
            },
            "required": ["file_path", "content"],
        }

    async def execute(
        self,
        arguments: Dict[str, Any],
        context: ToolContext,
    ) -> ToolResult:
        file_path_str = arguments["file_path"]
        content = arguments["content"]

        try:
            file_path = context.resolve_path(file_path_str)

            # Create parent directories if needed
            file_path.parent.mkdir(parents=True, exist_ok=True)

            # Write content
            if AIOFILES_AVAILABLE:
                async with aiofiles.open(file_path, "w", encoding="utf-8") as f:
                    await f.write(content)
            else:
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(content)

            return ToolResult.success_result(
                f"Successfully wrote {len(content)} characters to {file_path}",
                file_path=str(file_path),
                bytes_written=len(content.encode("utf-8")),
            )

        except Exception as e:
            return ToolResult.error_result(str(e))


class EditFileTool(Tool):
    """Edit a file by replacing text."""

    name = "edit_file"
    description = "Edit a file by replacing old text with new text."
    category = ToolCategory.FILE
    requires_permission = True

    @property
    def input_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "file_path": {
                    "type": "string",
                    "description": "Path to the file to edit",
                },
                "old_string": {
                    "type": "string",
                    "description": "The text to find and replace",
                },
                "new_string": {
                    "type": "string",
                    "description": "The text to replace with",
                },
                "replace_all": {
                    "type": "boolean",
                    "description": "Replace all occurrences (default: false)",
                },
            },
            "required": ["file_path", "old_string", "new_string"],
        }

    async def execute(
        self,
        arguments: Dict[str, Any],
        context: ToolContext,
    ) -> ToolResult:
        file_path_str = arguments["file_path"]
        old_string = arguments["old_string"]
        new_string = arguments["new_string"]
        replace_all = arguments.get("replace_all", False)

        try:
            file_path = context.resolve_path(file_path_str)

            if not file_path.exists():
                return ToolResult.error_result(f"File not found: {file_path}")

            # Read current content
            if AIOFILES_AVAILABLE:
                async with aiofiles.open(file_path, "r", encoding="utf-8") as f:
                    content = await f.read()
            else:
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()

            # Check if old_string exists
            if old_string not in content:
                return ToolResult.error_result(
                    f"Text not found in file: '{old_string[:50]}...'"
                )

            # Check for uniqueness if not replace_all
            if not replace_all and content.count(old_string) > 1:
                return ToolResult.error_result(
                    f"Text found {content.count(old_string)} times. "
                    "Use replace_all=true or provide more context."
                )

            # Perform replacement
            if replace_all:
                new_content = content.replace(old_string, new_string)
                replacements = content.count(old_string)
            else:
                new_content = content.replace(old_string, new_string, 1)
                replacements = 1

            # Write back
            if AIOFILES_AVAILABLE:
                async with aiofiles.open(file_path, "w", encoding="utf-8") as f:
                    await f.write(new_content)
            else:
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(new_content)

            return ToolResult.success_result(
                f"Successfully made {replacements} replacement(s) in {file_path}",
                file_path=str(file_path),
                replacements=replacements,
            )

        except Exception as e:
            return ToolResult.error_result(str(e))


class ListDirectoryTool(Tool):
    """List contents of a directory."""

    name = "list_directory"
    description = "List files and directories at the specified path."
    category = ToolCategory.FILE
    requires_permission = False

    @property
    def input_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Directory path to list (default: workspace root)",
                },
            },
            "required": [],
        }

    async def execute(
        self,
        arguments: Dict[str, Any],
        context: ToolContext,
    ) -> ToolResult:
        path_str = arguments.get("path", ".")

        try:
            dir_path = context.resolve_path(path_str)

            if not dir_path.exists():
                return ToolResult.error_result(f"Directory not found: {dir_path}")

            if not dir_path.is_dir():
                return ToolResult.error_result(f"Not a directory: {dir_path}")

            entries = []
            for entry in sorted(dir_path.iterdir()):
                entry_type = "dir" if entry.is_dir() else "file"
                size = entry.stat().st_size if entry.is_file() else 0
                entries.append(f"[{entry_type}] {entry.name}" + (f" ({size} bytes)" if entry.is_file() else "/"))

            output = f"Contents of {dir_path}:\n" + "\n".join(entries)

            return ToolResult.success_result(
                output,
                path=str(dir_path),
                entry_count=len(entries),
            )

        except Exception as e:
            return ToolResult.error_result(str(e))


class GlobTool(Tool):
    """Find files matching a glob pattern."""

    name = "glob"
    description = "Find files matching a glob pattern (e.g., '**/*.py')."
    category = ToolCategory.FILE
    requires_permission = False

    @property
    def input_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "pattern": {
                    "type": "string",
                    "description": "Glob pattern to match (e.g., '**/*.py', 'src/*.ts')",
                },
                "path": {
                    "type": "string",
                    "description": "Base directory for the search (default: workspace root)",
                },
            },
            "required": ["pattern"],
        }

    async def execute(
        self,
        arguments: Dict[str, Any],
        context: ToolContext,
    ) -> ToolResult:
        pattern = arguments["pattern"]
        path_str = arguments.get("path", ".")

        try:
            base_path = context.resolve_path(path_str)

            if not base_path.exists():
                return ToolResult.error_result(f"Directory not found: {base_path}")

            if not base_path.is_dir():
                return ToolResult.error_result(f"Not a directory: {base_path}")

            # Find matching files
            matches = []
            for match in base_path.glob(pattern):
                # Get relative path from base
                try:
                    rel_path = match.relative_to(base_path)
                    matches.append(str(rel_path))
                except ValueError:
                    matches.append(str(match))

            # Sort by modification time (most recent first)
            matches_with_time = []
            for m in matches:
                full_path = base_path / m
                try:
                    mtime = full_path.stat().st_mtime
                except OSError:
                    mtime = 0
                matches_with_time.append((m, mtime))

            matches_with_time.sort(key=lambda x: x[1], reverse=True)
            sorted_matches = [m[0] for m in matches_with_time]

            output = f"Found {len(sorted_matches)} files matching '{pattern}':\n"
            output += "\n".join(sorted_matches[:100])  # Limit to 100 results

            if len(sorted_matches) > 100:
                output += f"\n... and {len(sorted_matches) - 100} more"

            return ToolResult.success_result(
                output,
                pattern=pattern,
                base_path=str(base_path),
                match_count=len(sorted_matches),
            )

        except Exception as e:
            return ToolResult.error_result(str(e))


# Register all file tools
def register_file_tools() -> None:
    """Register all file operation tools."""
    register_tool(ReadFileTool())
    register_tool(WriteFileTool())
    register_tool(EditFileTool())
    register_tool(ListDirectoryTool())
    register_tool(GlobTool())
