"""
Grep/search tool.

This module provides a tool for searching file contents
using regular expressions.
"""

import asyncio
import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from .base import Tool, ToolCategory, ToolContext, ToolResult, register_tool


class GrepTool(Tool):
    """Search file contents using regex patterns."""

    name = "grep"
    description = (
        "Search for content in files using regular expressions. "
        "Supports filtering by file type and showing context lines."
    )
    category = ToolCategory.SEARCH
    requires_permission = False

    @property
    def input_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "pattern": {
                    "type": "string",
                    "description": "Regular expression pattern to search for",
                },
                "path": {
                    "type": "string",
                    "description": "File or directory to search in (default: workspace root)",
                },
                "glob": {
                    "type": "string",
                    "description": "Glob pattern to filter files (e.g., '*.py', '*.{ts,tsx}')",
                },
                "case_insensitive": {
                    "type": "boolean",
                    "description": "Case insensitive search (default: false)",
                },
                "context_lines": {
                    "type": "integer",
                    "description": "Number of context lines before and after matches",
                },
                "max_results": {
                    "type": "integer",
                    "description": "Maximum number of results to return (default: 100)",
                },
            },
            "required": ["pattern"],
        }

    def _search_file(
        self,
        file_path: Path,
        pattern: re.Pattern,
        context_lines: int = 0,
    ) -> List[Tuple[int, str, List[str], List[str]]]:
        """
        Search a single file for pattern matches.

        Args:
            file_path: Path to the file
            pattern: Compiled regex pattern
            context_lines: Number of context lines

        Returns:
            List of (line_number, matched_line, before_context, after_context)
        """
        try:
            with open(file_path, "r", encoding="utf-8", errors="replace") as f:
                lines = f.readlines()
        except Exception:
            return []

        matches = []
        for i, line in enumerate(lines):
            if pattern.search(line):
                # Get context
                before = []
                after = []

                if context_lines > 0:
                    start = max(0, i - context_lines)
                    before = [l.rstrip() for l in lines[start:i]]

                    end = min(len(lines), i + context_lines + 1)
                    after = [l.rstrip() for l in lines[i + 1:end]]

                matches.append((i + 1, line.rstrip(), before, after))

        return matches

    async def execute(
        self,
        arguments: Dict[str, Any],
        context: ToolContext,
    ) -> ToolResult:
        pattern_str = arguments["pattern"]
        path_str = arguments.get("path", ".")
        glob_pattern = arguments.get("glob")
        case_insensitive = arguments.get("case_insensitive", False)
        context_lines = arguments.get("context_lines", 0)
        max_results = arguments.get("max_results", 100)

        try:
            # Compile pattern
            flags = re.IGNORECASE if case_insensitive else 0
            try:
                pattern = re.compile(pattern_str, flags)
            except re.error as e:
                return ToolResult.error_result(f"Invalid regex pattern: {e}")

            # Resolve search path
            search_path = context.resolve_path(path_str)

            if not search_path.exists():
                return ToolResult.error_result(f"Path not found: {search_path}")

            # Collect files to search
            files_to_search: List[Path] = []

            if search_path.is_file():
                files_to_search = [search_path]
            else:
                # Get all files, optionally filtered by glob
                if glob_pattern:
                    files_to_search = list(search_path.glob(f"**/{glob_pattern}"))
                else:
                    files_to_search = [
                        f for f in search_path.rglob("*")
                        if f.is_file() and not self._should_skip(f)
                    ]

            # Search files
            all_matches: List[Tuple[Path, int, str, List[str], List[str]]] = []
            total_files_searched = 0

            for file_path in files_to_search:
                if not file_path.is_file():
                    continue

                if self._should_skip(file_path):
                    continue

                total_files_searched += 1
                matches = self._search_file(file_path, pattern, context_lines)

                for line_num, line, before, after in matches:
                    all_matches.append((file_path, line_num, line, before, after))

                    if len(all_matches) >= max_results:
                        break

                if len(all_matches) >= max_results:
                    break

            # Format output
            if not all_matches:
                return ToolResult.success_result(
                    f"No matches found for '{pattern_str}'",
                    pattern=pattern_str,
                    files_searched=total_files_searched,
                    match_count=0,
                )

            output_lines = []
            current_file = None

            for file_path, line_num, line, before, after in all_matches:
                # Get relative path
                try:
                    rel_path = file_path.relative_to(context.workspace_path)
                except ValueError:
                    rel_path = file_path

                # Add file header if changed
                if current_file != file_path:
                    if current_file is not None:
                        output_lines.append("")  # Blank line between files
                    output_lines.append(f"--- {rel_path} ---")
                    current_file = file_path

                # Add context before
                if before:
                    for i, ctx_line in enumerate(before):
                        ctx_num = line_num - len(before) + i
                        output_lines.append(f"  {ctx_num}: {ctx_line}")

                # Add matched line
                output_lines.append(f"> {line_num}: {line}")

                # Add context after
                if after:
                    for i, ctx_line in enumerate(after):
                        ctx_num = line_num + i + 1
                        output_lines.append(f"  {ctx_num}: {ctx_line}")

            output = "\n".join(output_lines)

            # Add summary
            summary = f"\n\nFound {len(all_matches)} matches in {total_files_searched} files"
            if len(all_matches) >= max_results:
                summary += f" (limited to {max_results})"

            return ToolResult.success_result(
                output + summary,
                pattern=pattern_str,
                files_searched=total_files_searched,
                match_count=len(all_matches),
            )

        except Exception as e:
            return ToolResult.error_result(str(e))

    def _should_skip(self, path: Path) -> bool:
        """Check if a file should be skipped."""
        # Skip hidden files and directories
        if any(part.startswith(".") for part in path.parts):
            return True

        # Skip common non-text directories
        skip_dirs = {
            "node_modules",
            "__pycache__",
            ".git",
            ".svn",
            "venv",
            ".venv",
            "dist",
            "build",
            ".next",
            ".nuxt",
        }
        if any(part in skip_dirs for part in path.parts):
            return True

        # Skip binary file extensions
        binary_extensions = {
            ".pyc",
            ".pyo",
            ".so",
            ".dll",
            ".exe",
            ".bin",
            ".jpg",
            ".jpeg",
            ".png",
            ".gif",
            ".ico",
            ".pdf",
            ".zip",
            ".tar",
            ".gz",
            ".rar",
            ".7z",
            ".mp3",
            ".mp4",
            ".avi",
            ".mov",
            ".woff",
            ".woff2",
            ".ttf",
            ".eot",
        }
        if path.suffix.lower() in binary_extensions:
            return True

        return False


# Register grep tools
def register_grep_tools() -> None:
    """Register search tools."""
    register_tool(GrepTool())
