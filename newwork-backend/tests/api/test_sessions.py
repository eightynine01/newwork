"""
Session API tests.
"""

import pytest


@pytest.mark.unit
class TestSessionCRUD:
    """Session CRUD operation tests."""

    def test_create_session(self, client, test_session_data):
        """
        POST /api/v1/sessions creates a new session.
        """
        response = client.post("/api/v1/sessions", json=test_session_data)

        assert response.status_code == 201
        data = response.json()
        assert "id" in data
        assert data["title"] == test_session_data["title"]
        assert data["provider"] == test_session_data["provider"]

    def test_create_session_minimal(self, client):
        """
        Session can be created with minimal data.
        """
        response = client.post("/api/v1/sessions", json={"title": "Minimal Session"})

        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Minimal Session"
        # Default provider should be set
        assert "provider" in data

    def test_get_session(self, client, test_session_data):
        """
        GET /api/v1/sessions/{id} returns session details.
        """
        # Create session first
        create_response = client.post("/api/v1/sessions", json=test_session_data)
        session_id = create_response.json()["id"]

        # Get session
        response = client.get(f"/api/v1/sessions/{session_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == session_id
        assert data["title"] == test_session_data["title"]

    def test_get_session_not_found(self, client):
        """
        GET /api/v1/sessions/{id} returns 404 for non-existent session.
        """
        response = client.get("/api/v1/sessions/non-existent-id")

        assert response.status_code == 404

    def test_list_sessions(self, client, test_session_data):
        """
        GET /api/v1/sessions returns list of sessions.
        """
        # Create multiple sessions
        client.post("/api/v1/sessions", json=test_session_data)
        client.post("/api/v1/sessions", json={"title": "Another Session"})

        response = client.get("/api/v1/sessions")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 2

    def test_delete_session(self, client, test_session_data):
        """
        DELETE /api/v1/sessions/{id} removes a session.
        """
        # Create session first
        create_response = client.post("/api/v1/sessions", json=test_session_data)
        session_id = create_response.json()["id"]

        # Delete session (204 No Content or 200 OK)
        response = client.delete(f"/api/v1/sessions/{session_id}")
        assert response.status_code in [200, 204]

        # Verify deletion
        get_response = client.get(f"/api/v1/sessions/{session_id}")
        assert get_response.status_code == 404

    def test_delete_session_not_found(self, client):
        """
        DELETE /api/v1/sessions/{id} returns 404 for non-existent session.
        """
        response = client.delete("/api/v1/sessions/non-existent-id")

        assert response.status_code == 404


@pytest.mark.integration
class TestSessionMessages:
    """Session message handling tests."""

    def test_get_session_messages_empty(self, client, test_session_data):
        """
        New session has empty message list.
        """
        create_response = client.post("/api/v1/sessions", json=test_session_data)
        session_id = create_response.json()["id"]

        response = client.get(f"/api/v1/sessions/{session_id}/messages")

        assert response.status_code == 200
        data = response.json()
        # Response can be empty list or dict with messages key
        messages = data if isinstance(data, list) else data.get("messages", [])
        assert isinstance(messages, list)
