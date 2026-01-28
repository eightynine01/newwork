"""
Tests for Session Export Service.
"""

import pytest
import json
from datetime import datetime
from app.services.session_export_service import SessionExportService


class TestSessionExportService:
    """Test session export functionality."""

    def setup_method(self):
        """Create export service and sample session data."""
        self.service = SessionExportService()
        self.sample_session = {
            "id": "session-123",
            "title": "Test Session",
            "path": "/workspace/project",
            "created_at": "2024-01-15T10:30:00",
            "updated_at": "2024-01-15T11:00:00",
            "tags": ["python", "testing"],
            "messages": [
                {
                    "id": "msg-1",
                    "role": "user",
                    "content": "Hello, can you help me?",
                    "created_at": "2024-01-15T10:30:00",
                },
                {
                    "id": "msg-2",
                    "role": "assistant",
                    "content": "Of course! What do you need help with?",
                    "created_at": "2024-01-15T10:30:05",
                },
            ],
            "todos": [
                {
                    "id": "todo-1",
                    "title": "Fix the bug",
                    "status": "completed",
                    "created_at": "2024-01-15T10:35:00",
                },
                {
                    "id": "todo-2",
                    "title": "Write tests",
                    "status": "pending",
                    "created_at": "2024-01-15T10:36:00",
                },
            ],
            "artifacts": [
                {
                    "id": "artifact-1",
                    "name": "main.py",
                    "path": "/workspace/main.py",
                    "type": "file",
                    "created_at": "2024-01-15T10:40:00",
                },
            ],
        }


class TestJsonExport(TestSessionExportService):
    """Test JSON export format."""

    def test_to_json_basic(self):
        """Should export session as valid JSON string."""
        result = self.service.to_json(session=self.sample_session)

        # Should be valid JSON string
        parsed = json.loads(result)

        assert parsed["session"]["id"] == "session-123"
        assert parsed["session"]["title"] == "Test Session"
        assert len(parsed["session"]["messages"]) == 2
        assert parsed["export_version"] == "1.0"

    def test_to_json_includes_messages(self):
        """Should include messages in export."""
        result = self.service.to_json(session=self.sample_session)
        parsed = json.loads(result)

        messages = parsed["session"]["messages"]
        assert len(messages) == 2
        assert messages[0]["role"] == "user"
        assert messages[1]["role"] == "assistant"

    def test_to_json_includes_todos(self):
        """Should include todos when present."""
        result = self.service.to_json(session=self.sample_session)
        parsed = json.loads(result)

        todos = parsed["session"]["todos"]
        assert len(todos) == 2
        assert todos[0]["title"] == "Fix the bug"

    def test_to_json_includes_artifacts(self):
        """Should include artifacts when present."""
        result = self.service.to_json(session=self.sample_session)
        parsed = json.loads(result)

        artifacts = parsed["session"]["artifacts"]
        assert len(artifacts) == 1
        assert artifacts[0]["name"] == "main.py"

    def test_to_json_metadata(self):
        """Should include export metadata."""
        result = self.service.to_json(session=self.sample_session)
        parsed = json.loads(result)

        assert "exported_at" in parsed
        assert "export_version" in parsed

    def test_to_json_pretty_format(self):
        """Should format with indentation when pretty=True."""
        result = self.service.to_json(session=self.sample_session, pretty=True)
        assert "\n" in result  # Should have newlines

    def test_to_json_compact_format(self):
        """Should be compact when pretty=False."""
        result = self.service.to_json(session=self.sample_session, pretty=False)
        # Still valid JSON but no pretty formatting
        parsed = json.loads(result)
        assert parsed["session"]["id"] == "session-123"


class TestMarkdownExport(TestSessionExportService):
    """Test Markdown export format."""

    def test_to_markdown_basic(self):
        """Should export session as Markdown string."""
        result = self.service.to_markdown(session=self.sample_session)

        assert isinstance(result, str)
        assert "# Test Session" in result
        assert "## Conversation" in result

    def test_to_markdown_includes_messages(self):
        """Should include all messages in Markdown."""
        result = self.service.to_markdown(session=self.sample_session)

        assert "### User" in result
        assert "Hello, can you help me?" in result
        assert "### Assistant" in result
        assert "Of course! What do you need help with?" in result

    def test_to_markdown_includes_todos(self):
        """Should include tasks section with checkboxes."""
        result = self.service.to_markdown(session=self.sample_session)

        assert "## Tasks" in result
        assert "[x] Fix the bug" in result  # Completed
        assert "[ ] Write tests" in result   # Not completed

    def test_to_markdown_excludes_todos(self):
        """Should exclude todos when include_todos=False."""
        result = self.service.to_markdown(
            session=self.sample_session,
            include_todos=False,
        )

        assert "## Tasks" not in result

    def test_to_markdown_includes_artifacts(self):
        """Should include artifacts section."""
        result = self.service.to_markdown(session=self.sample_session)

        assert "## Artifacts" in result
        assert "main.py" in result
        assert "/workspace/main.py" in result

    def test_to_markdown_excludes_artifacts(self):
        """Should exclude artifacts when include_artifacts=False."""
        result = self.service.to_markdown(
            session=self.sample_session,
            include_artifacts=False,
        )

        assert "## Artifacts" not in result

    def test_to_markdown_includes_metadata(self):
        """Should include session metadata."""
        result = self.service.to_markdown(session=self.sample_session)

        assert "**Created:**" in result
        assert "**Tags:**" in result

    def test_to_markdown_empty_messages(self):
        """Should handle empty messages gracefully."""
        session = {
            "id": "empty-123",
            "title": "Empty Session",
            "messages": [],
        }
        result = self.service.to_markdown(session=session)

        assert "# Empty Session" in result
        # Should not have conversation section if no messages
        assert "## Conversation" not in result


class TestExportFilename(TestSessionExportService):
    """Test filename generation."""

    def test_get_export_filename_json(self):
        """Should generate JSON filename."""
        filename = self.service.get_export_filename(
            session=self.sample_session,
            format="json",
        )

        assert filename.endswith(".json")
        assert "Test Session" in filename or "Test_Session" in filename

    def test_get_export_filename_markdown(self):
        """Should generate Markdown filename."""
        filename = self.service.get_export_filename(
            session=self.sample_session,
            format="markdown",
        )

        assert filename.endswith(".md")

    def test_get_export_filename_sanitizes(self):
        """Should sanitize special characters in filename."""
        session = {"title": "Test/Session:With*Special<Chars>"}
        filename = self.service.get_export_filename(session=session, format="json")

        # Should not contain special characters
        assert "/" not in filename
        assert ":" not in filename
        assert "*" not in filename


class TestExportEdgeCases(TestSessionExportService):
    """Test edge cases and error handling."""

    def test_export_with_special_characters(self):
        """Should handle special characters in content."""
        session = {
            "id": "special-123",
            "title": "Test <Script> & 'Quotes'",
            "created_at": "2024-01-15T10:00:00",
            "messages": [
                {
                    "id": "msg-1",
                    "role": "user",
                    "content": "Code: `print('hello')` and **bold**",
                    "created_at": "2024-01-15T10:00:00",
                },
            ],
        }

        json_result = self.service.to_json(session=session)
        parsed = json.loads(json_result)
        md_result = self.service.to_markdown(session=session)

        assert parsed["session"]["title"] == "Test <Script> & 'Quotes'"
        assert "`print('hello')`" in md_result

    def test_export_with_unicode(self):
        """Should handle Unicode characters."""
        session = {
            "id": "unicode-123",
            "title": "한글 테스트",
            "created_at": "2024-01-15T10:00:00",
            "messages": [
                {
                    "id": "msg-1",
                    "role": "user",
                    "content": "안녕하세요! こんにちは",
                    "created_at": "2024-01-15T10:00:00",
                },
            ],
        }

        json_result = self.service.to_json(session=session)
        parsed = json.loads(json_result)
        md_result = self.service.to_markdown(session=session)

        assert parsed["session"]["title"] == "한글 테스트"
        assert "안녕하세요" in md_result
        assert "こんにちは" in md_result

    def test_export_with_long_content(self):
        """Should handle long message content."""
        long_content = "A" * 10000  # 10KB of content
        session = {
            "id": "long-123",
            "title": "Long Session",
            "messages": [
                {
                    "id": "msg-1",
                    "role": "assistant",
                    "content": long_content,
                    "created_at": "2024-01-15T10:00:00",
                },
            ],
        }

        json_result = self.service.to_json(session=session)
        parsed = json.loads(json_result)

        assert len(parsed["session"]["messages"][0]["content"]) == 10000


class TestJsonImport(TestSessionExportService):
    """Test JSON import functionality."""

    def test_from_json_valid(self):
        """Should parse valid exported JSON."""
        json_str = self.service.to_json(session=self.sample_session)
        result = self.service.from_json(json_str)

        assert result["id"] == "session-123"
        assert result["title"] == "Test Session"

    def test_from_json_invalid(self):
        """Should raise error for invalid JSON."""
        with pytest.raises(ValueError, match="Invalid JSON"):
            self.service.from_json("not valid json")

    def test_from_json_missing_session(self):
        """Should raise error if session key is missing."""
        with pytest.raises(ValueError, match="missing 'session' key"):
            self.service.from_json('{"other": "data"}')
