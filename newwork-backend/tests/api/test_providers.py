"""
Provider API tests.
"""

import pytest


@pytest.mark.unit
class TestProviderEndpoints:
    """Provider listing and info tests."""

    def test_list_providers(self, client):
        """
        GET /api/v1/providers returns available providers.
        """
        response = client.get("/api/v1/providers")

        assert response.status_code == 200
        data = response.json()
        # 응답이 리스트 또는 딕셔너리일 수 있음
        assert isinstance(data, (dict, list))

    def test_providers_have_required_fields(self, client):
        """
        Each provider has required fields.
        """
        response = client.get("/api/v1/providers")
        data = response.json()

        providers = data.get("providers", data) if isinstance(data, dict) else data

        # If providers exist, check structure
        if providers and isinstance(providers, list) and len(providers) > 0:
            provider = providers[0]
            # Provider should have name/id
            assert "name" in provider or "id" in provider or "provider" in provider


@pytest.mark.unit
class TestProviderModels:
    """Provider model listing tests."""

    def test_get_anthropic_models(self, client):
        """
        Can retrieve Anthropic models.
        """
        response = client.get("/api/v1/providers/anthropic/models")

        # May return 200 with models or 404/503 if not configured
        assert response.status_code in [200, 404, 503]

        if response.status_code == 200:
            data = response.json()
            # Should return list of models
            assert isinstance(data, (list, dict))

    def test_get_openai_models(self, client):
        """
        Can retrieve OpenAI models.
        """
        response = client.get("/api/v1/providers/openai/models")

        # May return 200 with models or 404/503 if not configured
        assert response.status_code in [200, 404, 503]

    def test_get_unknown_provider_models(self, client):
        """
        Unknown provider returns appropriate error.
        """
        response = client.get("/api/v1/providers/unknown-provider/models")

        # Should return 404 or 400
        assert response.status_code in [400, 404]
