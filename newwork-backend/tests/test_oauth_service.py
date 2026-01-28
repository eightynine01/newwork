"""
Tests for OAuth Service.
"""

import pytest
import time
from datetime import datetime, timedelta
from app.services.oauth_service import OAuthService


class TestOAuthStateManagement:
    """Test OAuth state parameter generation and validation."""

    def setup_method(self):
        """Create fresh OAuth service for each test."""
        self.oauth = OAuthService(secret_key="test-secret-key")

    def test_generate_state_returns_string(self):
        """State should be a URL-safe string."""
        state = self.oauth.generate_state("test-server")
        assert isinstance(state, str)
        assert len(state) > 20  # Should be sufficiently long

    def test_generate_state_unique(self):
        """Each state should be unique."""
        states = [self.oauth.generate_state("test-server") for _ in range(10)]
        assert len(set(states)) == 10

    def test_validate_state_success(self):
        """Valid state should return True with data."""
        state = self.oauth.generate_state(
            "my-server",
            redirect_uri="http://localhost/callback",
            extra_data={"foo": "bar"}
        )

        is_valid, data = self.oauth.validate_state(state)

        assert is_valid is True
        assert data is not None
        assert data["server_name"] == "my-server"
        assert data["redirect_uri"] == "http://localhost/callback"
        assert data["extra_data"]["foo"] == "bar"

    def test_validate_state_invalid(self):
        """Invalid state should return False."""
        is_valid, data = self.oauth.validate_state("invalid-state-token")

        assert is_valid is False
        assert data is None

    def test_validate_state_single_use(self):
        """State should only be valid once (prevent replay attacks)."""
        state = self.oauth.generate_state("test-server")

        # First validation should succeed
        is_valid1, _ = self.oauth.validate_state(state)
        assert is_valid1 is True

        # Second validation should fail (state consumed)
        is_valid2, _ = self.oauth.validate_state(state)
        assert is_valid2 is False

    def test_cleanup_expired_states(self):
        """Expired states should be cleaned up."""
        # Generate state with very short TTL by manipulating internal state
        state = self.oauth.generate_state("test-server")

        # Manually expire the state
        self.oauth._states[state]["expires_at"] = (
            datetime.now() - timedelta(minutes=1)
        ).isoformat()

        # Cleanup should remove expired state
        count = self.oauth.cleanup_expired_states()
        assert count == 1

        # State should no longer be valid
        is_valid, _ = self.oauth.validate_state(state)
        assert is_valid is False


class TestOAuthTokenStorage:
    """Test OAuth token encryption and storage."""

    def setup_method(self):
        """Create fresh OAuth service for each test."""
        self.oauth = OAuthService(secret_key="test-secret-key")

    def test_store_and_retrieve_tokens(self):
        """Tokens should be stored and retrieved correctly."""
        tokens = {
            "access_token": "test-access-token-12345",
            "refresh_token": "test-refresh-token-67890",
            "token_type": "Bearer",
            "expires_in": 3600,
        }

        self.oauth.store_tokens("my-mcp-server", tokens)
        retrieved = self.oauth.get_tokens("my-mcp-server")

        assert retrieved is not None
        assert retrieved["tokens"]["access_token"] == tokens["access_token"]
        assert retrieved["tokens"]["refresh_token"] == tokens["refresh_token"]
        assert retrieved["server_name"] == "my-mcp-server"

        # Cleanup
        self.oauth.delete_tokens("my-mcp-server")

    def test_get_access_token(self):
        """Should retrieve just the access token."""
        tokens = {"access_token": "my-access-token", "token_type": "Bearer"}
        self.oauth.store_tokens("server1", tokens)

        access_token = self.oauth.get_access_token("server1")
        assert access_token == "my-access-token"

        # Cleanup
        self.oauth.delete_tokens("server1")

    def test_get_refresh_token(self):
        """Should retrieve just the refresh token."""
        tokens = {
            "access_token": "access",
            "refresh_token": "my-refresh-token",
        }
        self.oauth.store_tokens("server2", tokens)

        refresh_token = self.oauth.get_refresh_token("server2")
        assert refresh_token == "my-refresh-token"

        # Cleanup
        self.oauth.delete_tokens("server2")

    def test_get_tokens_nonexistent(self):
        """Should return None for nonexistent server."""
        result = self.oauth.get_tokens("nonexistent-server")
        assert result is None

    def test_delete_tokens(self):
        """Should delete stored tokens."""
        tokens = {"access_token": "to-be-deleted"}
        self.oauth.store_tokens("delete-me", tokens)

        # Verify stored
        assert self.oauth.get_tokens("delete-me") is not None

        # Delete
        result = self.oauth.delete_tokens("delete-me")
        assert result is True

        # Verify deleted
        assert self.oauth.get_tokens("delete-me") is None

    def test_is_token_expired(self):
        """Should correctly detect expired tokens."""
        # Store non-expired token
        tokens = {"access_token": "valid", "expires_in": 3600}
        self.oauth.store_tokens("not-expired", tokens)
        assert self.oauth.is_token_expired("not-expired") is False

        # Cleanup
        self.oauth.delete_tokens("not-expired")

    def test_needs_refresh(self):
        """Should detect tokens needing refresh."""
        # Token that expires in 10 minutes (within 5 minute buffer)
        tokens = {"access_token": "soon-expired", "expires_in": 600}
        self.oauth.store_tokens("needs-refresh", tokens)

        # With 10 minute buffer, should need refresh
        assert self.oauth.needs_refresh("needs-refresh", buffer_seconds=600) is True

        # With 1 minute buffer, should not need refresh yet
        assert self.oauth.needs_refresh("needs-refresh", buffer_seconds=60) is False

        # Cleanup
        self.oauth.delete_tokens("needs-refresh")


class TestOAuthServiceEncryption:
    """Test that tokens are actually encrypted."""

    def test_different_keys_cannot_decrypt(self):
        """Tokens encrypted with one key cannot be read with another."""
        oauth1 = OAuthService(secret_key="key-one")
        oauth2 = OAuthService(secret_key="key-two")

        tokens = {"access_token": "secret-data"}
        oauth1.store_tokens("encrypted-server", tokens)

        # oauth2 with different key should not be able to read
        result = oauth2.get_tokens("encrypted-server")
        # Should either return None or fail to decrypt
        assert result is None or "access_token" not in result.get("tokens", {})

        # Cleanup with correct key
        oauth1.delete_tokens("encrypted-server")
