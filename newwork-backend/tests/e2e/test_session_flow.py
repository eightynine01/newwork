"""
End-to-end session flow tests.

Tests the complete flow from session creation to message exchange.
"""

import pytest


@pytest.mark.integration
class TestCompleteSessionFlow:
    """Full session lifecycle tests."""

    def test_session_creation_flow(self, client):
        """
        Complete session creation and retrieval flow.
        """
        # 1. Create session
        create_response = client.post(
            "/api/v1/sessions",
            json={
                "title": "E2E Test Session",
                "provider": "anthropic",
                "model": "claude-sonnet-4-20250514",
            },
        )
        assert create_response.status_code == 201
        session = create_response.json()
        session_id = session["id"]

        # 2. Verify session exists in list
        list_response = client.get("/api/v1/sessions")
        assert list_response.status_code == 200
        sessions = list_response.json()
        assert any(s["id"] == session_id for s in sessions)

        # 3. Get session details
        get_response = client.get(f"/api/v1/sessions/{session_id}")
        assert get_response.status_code == 200
        session_detail = get_response.json()
        assert session_detail["title"] == "E2E Test Session"

        # 4. Clean up - delete session (204 No Content or 200 OK)
        delete_response = client.delete(f"/api/v1/sessions/{session_id}")
        assert delete_response.status_code in [200, 204]

        # 5. Verify deletion
        verify_response = client.get(f"/api/v1/sessions/{session_id}")
        assert verify_response.status_code == 404

    def test_multiple_sessions_management(self, client):
        """
        Create and manage multiple sessions.
        """
        session_ids = []

        # Create multiple sessions
        for i in range(3):
            response = client.post(
                "/api/v1/sessions",
                json={"title": f"Session {i}"},
            )
            assert response.status_code == 201
            session_ids.append(response.json()["id"])

        # Verify all exist
        list_response = client.get("/api/v1/sessions")
        sessions = list_response.json()
        for sid in session_ids:
            assert any(s["id"] == sid for s in sessions)

        # Delete all (204 No Content or 200 OK)
        for sid in session_ids:
            delete_response = client.delete(f"/api/v1/sessions/{sid}")
            assert delete_response.status_code in [200, 204]


@pytest.mark.integration
class TestSessionWithProviders:
    """Session tests with different providers."""

    def test_session_with_anthropic(self, client):
        """
        Create session with Anthropic provider.
        """
        response = client.post(
            "/api/v1/sessions",
            json={
                "title": "Anthropic Session",
                "provider": "anthropic",
                "model": "claude-sonnet-4-20250514",
            },
        )

        assert response.status_code == 201
        session = response.json()
        assert session["provider"] == "anthropic"

        # Cleanup
        client.delete(f"/api/v1/sessions/{session['id']}")

    def test_session_with_openai(self, client):
        """
        Create session with OpenAI provider.

        Note: Provider may be overridden to default if OpenAI is not configured.
        """
        response = client.post(
            "/api/v1/sessions",
            json={
                "title": "OpenAI Session",
                "provider": "openai",
                "model": "gpt-4",
            },
        )

        assert response.status_code == 201
        session = response.json()
        # Provider가 설정된 경우 openai, 아닌 경우 기본값 사용
        assert session["provider"] in ["openai", "anthropic"]

        # Cleanup
        client.delete(f"/api/v1/sessions/{session['id']}")


@pytest.mark.integration
class TestExportFlow:
    """Session export flow tests."""

    def test_export_session_json(self, client):
        """
        Export session as JSON.
        """
        # Create session
        create_response = client.post(
            "/api/v1/sessions",
            json={"title": "Export Test Session"},
        )
        session_id = create_response.json()["id"]

        # Export as JSON
        export_response = client.get(f"/api/v1/sessions/{session_id}/export/json")

        assert export_response.status_code == 200
        data = export_response.json()

        # Export 응답 구조: {session: {...}, export_version, exported_at} 또는 직접 session 데이터
        if "session" in data:
            assert data["session"]["title"] == "Export Test Session"
        else:
            assert data.get("title") == "Export Test Session"

        # Cleanup
        client.delete(f"/api/v1/sessions/{session_id}")

    def test_export_session_markdown(self, client):
        """
        Export session as Markdown.
        """
        # Create session
        create_response = client.post(
            "/api/v1/sessions",
            json={"title": "Markdown Export Test"},
        )
        session_id = create_response.json()["id"]

        # Export as Markdown
        export_response = client.get(f"/api/v1/sessions/{session_id}/export/markdown")

        assert export_response.status_code == 200
        content = export_response.text
        assert "Markdown Export Test" in content

        # Cleanup
        client.delete(f"/api/v1/sessions/{session_id}")
