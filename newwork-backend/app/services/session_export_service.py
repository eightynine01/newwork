"""
Session Export Service.

Provides functionality to export sessions in various formats.
"""

import json
from typing import Dict, Any, List, Optional
from datetime import datetime


class SessionExportService:
    """
    Service for exporting session data to different formats.
    """

    @staticmethod
    def to_json(session: Dict[str, Any], pretty: bool = True) -> str:
        """
        Export session to JSON format.

        Args:
            session: Session data dictionary
            pretty: Whether to format JSON with indentation

        Returns:
            JSON string
        """
        export_data = {
            "export_version": "1.0",
            "exported_at": datetime.now().isoformat(),
            "session": {
                "id": session.get("id"),
                "title": session.get("title"),
                "path": session.get("path"),
                "created_at": session.get("created_at"),
                "updated_at": session.get("updated_at"),
                "messages": session.get("messages", []),
                "todos": session.get("todos", []),
                "artifacts": session.get("artifacts", []),
                "tags": session.get("tags", []),
            },
        }

        if pretty:
            return json.dumps(export_data, indent=2, ensure_ascii=False)
        return json.dumps(export_data, ensure_ascii=False)

    @staticmethod
    def to_markdown(
        session: Dict[str, Any],
        include_todos: bool = True,
        include_artifacts: bool = True,
    ) -> str:
        """
        Export session to Markdown format.

        Args:
            session: Session data dictionary
            include_todos: Whether to include todos section
            include_artifacts: Whether to include artifacts section

        Returns:
            Markdown string
        """
        lines = []

        # Header
        title = session.get("title", "Untitled Session")
        lines.append(f"# {title}")
        lines.append("")

        # Metadata
        created_at = session.get("created_at")
        if created_at:
            if isinstance(created_at, str):
                try:
                    created_at = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                except ValueError:
                    pass

            if isinstance(created_at, datetime):
                created_str = created_at.strftime("%Y-%m-%d %H:%M")
            else:
                created_str = str(created_at)
        else:
            created_str = "Unknown"

        tags = session.get("tags", [])
        tags_str = ", ".join(tags) if tags else "None"

        lines.append(f"**Created:** {created_str} | **Tags:** {tags_str}")
        lines.append("")
        lines.append("---")
        lines.append("")

        # Conversation section
        messages = session.get("messages", [])
        if messages:
            lines.append("## Conversation")
            lines.append("")

            for msg in messages:
                role = msg.get("role", "unknown").capitalize()
                content = msg.get("content", "")
                timestamp = msg.get("created_at", "")

                if timestamp:
                    if isinstance(timestamp, str):
                        try:
                            ts = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
                            timestamp = ts.strftime("%H:%M")
                        except ValueError:
                            pass

                lines.append(f"### {role} ({timestamp})")
                lines.append("")
                lines.append(content)
                lines.append("")

        # Todos section
        if include_todos:
            todos = session.get("todos", [])
            if todos:
                lines.append("## Tasks")
                lines.append("")

                for todo in todos:
                    status = todo.get("status", "pending")
                    title = todo.get("title", todo.get("content", ""))
                    checkbox = "[x]" if status == "completed" else "[ ]"
                    lines.append(f"- {checkbox} {title}")

                lines.append("")

        # Artifacts section
        if include_artifacts:
            artifacts = session.get("artifacts", [])
            if artifacts:
                lines.append("## Artifacts")
                lines.append("")

                for artifact in artifacts:
                    name = artifact.get("name", "Unnamed")
                    artifact_type = artifact.get("type", "file")
                    path = artifact.get("path", "")

                    lines.append(f"- **{name}** ({artifact_type})")
                    if path:
                        lines.append(f"  - Path: `{path}`")

                lines.append("")

        # Footer
        lines.append("---")
        lines.append("")
        lines.append(f"*Exported from NewWork on {datetime.now().strftime('%Y-%m-%d %H:%M')}*")

        return "\n".join(lines)

    @staticmethod
    def get_export_filename(session: Dict[str, Any], format: str) -> str:
        """
        Generate an appropriate filename for the export.

        Args:
            session: Session data dictionary
            format: Export format ('json' or 'markdown')

        Returns:
            Filename string
        """
        title = session.get("title", "session")
        # Sanitize filename
        safe_title = "".join(
            c if c.isalnum() or c in (" ", "-", "_") else "_"
            for c in title
        ).strip()
        safe_title = safe_title[:50]  # Limit length

        timestamp = datetime.now().strftime("%Y%m%d")
        extension = "md" if format == "markdown" else "json"

        return f"{safe_title}_{timestamp}.{extension}"

    @staticmethod
    def from_json(json_str: str) -> Dict[str, Any]:
        """
        Parse an exported JSON session.

        Args:
            json_str: JSON string

        Returns:
            Session data dictionary

        Raises:
            ValueError: If JSON is invalid or not a valid export
        """
        try:
            data = json.loads(json_str)
        except json.JSONDecodeError as e:
            raise ValueError(f"Invalid JSON: {e}")

        if "session" not in data:
            raise ValueError("Invalid export format: missing 'session' key")

        return data["session"]
