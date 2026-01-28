"""
OAuth Service.

Manages OAuth state parameters and token storage for MCP server connections.
"""

import secrets
import hashlib
import base64
import json
import logging
from typing import Dict, Any, Optional, Tuple
from datetime import datetime, timedelta
from pathlib import Path
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

logger = logging.getLogger(__name__)


class OAuthService:
    """
    Service for managing OAuth authentication flows.

    Features:
    - State parameter generation and validation (CSRF protection)
    - Token encryption and secure storage
    - Token refresh handling
    """

    # State TTL in minutes
    STATE_TTL_MINUTES = 10

    # Storage paths
    _oauth_dir: Optional[Path] = None
    _states: Dict[str, Dict[str, Any]] = {}
    _cipher: Optional[Fernet] = None

    def __init__(self, secret_key: Optional[str] = None):
        """
        Initialize OAuth service.

        Args:
            secret_key: Secret key for token encryption. If not provided,
                       generates a new one (tokens won't persist across restarts).
        """
        self._init_storage()
        self._init_cipher(secret_key)

    def _init_storage(self) -> None:
        """Initialize storage directory."""
        home = Path.home()
        self._oauth_dir = home / ".newwork" / "oauth"
        self._oauth_dir.mkdir(parents=True, exist_ok=True)

    def _init_cipher(self, secret_key: Optional[str] = None) -> None:
        """Initialize encryption cipher."""
        if secret_key:
            # Derive a key from the provided secret
            kdf = PBKDF2HMAC(
                algorithm=hashes.SHA256(),
                length=32,
                salt=b"newwork-oauth-salt",
                iterations=100000,
            )
            key = base64.urlsafe_b64encode(kdf.derive(secret_key.encode()))
        else:
            # Generate a random key (tokens won't persist across restarts)
            key = Fernet.generate_key()

        self._cipher = Fernet(key)

    # ========== State Management (CSRF Protection) ==========

    def generate_state(
        self,
        server_name: str,
        redirect_uri: Optional[str] = None,
        extra_data: Optional[Dict[str, Any]] = None,
    ) -> str:
        """
        Generate a state parameter for OAuth flow.

        The state parameter prevents CSRF attacks by ensuring the OAuth
        callback is from a flow we initiated.

        Args:
            server_name: Name of the MCP server
            redirect_uri: Optional redirect URI
            extra_data: Optional additional data to store

        Returns:
            State token string
        """
        state = secrets.token_urlsafe(32)

        self._states[state] = {
            "server_name": server_name,
            "redirect_uri": redirect_uri,
            "extra_data": extra_data or {},
            "created_at": datetime.now().isoformat(),
            "expires_at": (
                datetime.now() + timedelta(minutes=self.STATE_TTL_MINUTES)
            ).isoformat(),
        }

        logger.debug(f"Generated OAuth state for {server_name}")
        return state

    def validate_state(self, state: str) -> Tuple[bool, Optional[Dict[str, Any]]]:
        """
        Validate a state parameter from OAuth callback.

        Args:
            state: State token to validate

        Returns:
            Tuple of (is_valid, state_data)
        """
        if state not in self._states:
            logger.warning(f"OAuth state not found: {state[:8]}...")
            return False, None

        state_data = self._states[state]
        expires_at = datetime.fromisoformat(state_data["expires_at"])

        if datetime.now() > expires_at:
            logger.warning(f"OAuth state expired: {state[:8]}...")
            del self._states[state]
            return False, None

        # State is valid - remove it to prevent reuse
        del self._states[state]
        logger.debug(f"Validated OAuth state for {state_data['server_name']}")

        return True, state_data

    def cleanup_expired_states(self) -> int:
        """
        Remove expired state entries.

        Returns:
            Number of states removed
        """
        now = datetime.now()
        expired = []

        for state, data in self._states.items():
            expires_at = datetime.fromisoformat(data["expires_at"])
            if now > expires_at:
                expired.append(state)

        for state in expired:
            del self._states[state]

        if expired:
            logger.info(f"Cleaned up {len(expired)} expired OAuth states")

        return len(expired)

    # ========== Token Storage (Encrypted) ==========

    def _get_token_path(self, server_name: str) -> Path:
        """Get the token file path for a server."""
        # Use a hash of the server name for the filename
        name_hash = hashlib.sha256(server_name.encode()).hexdigest()[:16]
        return self._oauth_dir / f"tokens_{name_hash}.enc"

    def store_tokens(
        self,
        server_name: str,
        tokens: Dict[str, Any],
    ) -> None:
        """
        Store OAuth tokens securely.

        Args:
            server_name: Name of the MCP server
            tokens: Token data including:
                - access_token: The access token
                - refresh_token: Optional refresh token
                - expires_in: Optional expiration time in seconds
                - token_type: Usually "Bearer"
        """
        if not self._cipher:
            raise RuntimeError("OAuth service not initialized")

        # Add metadata
        token_data = {
            "server_name": server_name,
            "tokens": tokens,
            "stored_at": datetime.now().isoformat(),
        }

        # Calculate expiration if expires_in is provided
        if "expires_in" in tokens:
            expires_at = datetime.now() + timedelta(seconds=tokens["expires_in"])
            token_data["expires_at"] = expires_at.isoformat()

        # Encrypt and store
        json_data = json.dumps(token_data)
        encrypted = self._cipher.encrypt(json_data.encode())

        token_path = self._get_token_path(server_name)
        token_path.write_bytes(encrypted)

        logger.info(f"Stored OAuth tokens for {server_name}")

    def get_tokens(self, server_name: str) -> Optional[Dict[str, Any]]:
        """
        Retrieve OAuth tokens for a server.

        Args:
            server_name: Name of the MCP server

        Returns:
            Token data or None if not found
        """
        if not self._cipher:
            raise RuntimeError("OAuth service not initialized")

        token_path = self._get_token_path(server_name)

        if not token_path.exists():
            return None

        try:
            encrypted = token_path.read_bytes()
            decrypted = self._cipher.decrypt(encrypted)
            token_data = json.loads(decrypted.decode())

            # Check if tokens are expired
            if "expires_at" in token_data:
                expires_at = datetime.fromisoformat(token_data["expires_at"])
                if datetime.now() > expires_at:
                    logger.info(f"OAuth tokens expired for {server_name}")
                    # Don't delete - might be able to refresh
                    token_data["expired"] = True

            return token_data

        except Exception as e:
            logger.error(f"Error reading tokens for {server_name}: {e}")
            return None

    def delete_tokens(self, server_name: str) -> bool:
        """
        Delete stored tokens for a server.

        Args:
            server_name: Name of the MCP server

        Returns:
            True if tokens were deleted
        """
        token_path = self._get_token_path(server_name)

        if token_path.exists():
            token_path.unlink()
            logger.info(f"Deleted OAuth tokens for {server_name}")
            return True

        return False

    def is_token_expired(self, server_name: str) -> bool:
        """
        Check if tokens for a server are expired.

        Args:
            server_name: Name of the MCP server

        Returns:
            True if expired or not found
        """
        token_data = self.get_tokens(server_name)

        if not token_data:
            return True

        if "expires_at" not in token_data:
            return False

        expires_at = datetime.fromisoformat(token_data["expires_at"])
        return datetime.now() > expires_at

    def needs_refresh(self, server_name: str, buffer_seconds: int = 300) -> bool:
        """
        Check if tokens need to be refreshed soon.

        Args:
            server_name: Name of the MCP server
            buffer_seconds: Seconds before expiration to trigger refresh

        Returns:
            True if tokens should be refreshed
        """
        token_data = self.get_tokens(server_name)

        if not token_data:
            return True

        if "expires_at" not in token_data:
            return False

        expires_at = datetime.fromisoformat(token_data["expires_at"])
        refresh_threshold = expires_at - timedelta(seconds=buffer_seconds)

        return datetime.now() > refresh_threshold

    def get_access_token(self, server_name: str) -> Optional[str]:
        """
        Get the access token for a server.

        Args:
            server_name: Name of the MCP server

        Returns:
            Access token string or None
        """
        token_data = self.get_tokens(server_name)

        if not token_data:
            return None

        tokens = token_data.get("tokens", {})
        return tokens.get("access_token")

    def get_refresh_token(self, server_name: str) -> Optional[str]:
        """
        Get the refresh token for a server.

        Args:
            server_name: Name of the MCP server

        Returns:
            Refresh token string or None
        """
        token_data = self.get_tokens(server_name)

        if not token_data:
            return None

        tokens = token_data.get("tokens", {})
        return tokens.get("refresh_token")


# Singleton instance
_oauth_service: Optional[OAuthService] = None


def get_oauth_service(secret_key: Optional[str] = None) -> OAuthService:
    """
    Get the OAuth service singleton.

    Args:
        secret_key: Optional secret key for encryption

    Returns:
        OAuthService instance
    """
    global _oauth_service

    if _oauth_service is None:
        _oauth_service = OAuthService(secret_key)

    return _oauth_service
