"""
Health check API tests.
"""

import pytest


@pytest.mark.unit
class TestHealthEndpoint:
    """Health check endpoint tests."""

    def test_health_returns_ok(self, client):
        """
        GET /health returns healthy status.
        """
        response = client.get("/health")

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        # 앱 이름은 환경에 따라 다를 수 있음
        assert "app" in data
        assert "version" in data
        assert "providers" in data

    def test_health_includes_provider_info(self, client):
        """
        Health check includes provider availability info.
        """
        response = client.get("/health")

        data = response.json()
        providers = data.get("providers", {})

        assert "available" in providers
        assert "default" in providers
        assert isinstance(providers["available"], list)

    def test_root_redirects_or_returns_info(self, client):
        """
        GET / returns application info or redirects.
        """
        response = client.get("/")

        assert response.status_code == 200
        data = response.json()
        assert "app" in data or "message" in data
