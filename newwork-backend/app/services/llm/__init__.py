"""
LLM Provider abstraction layer.

This module provides a unified interface for interacting with various LLM providers
(Anthropic, OpenAI, DeepSeek, Minimax, ZAI).

Usage:
    from app.services.llm import get_provider, LLMProvider

    # Get a provider instance
    provider = get_provider("anthropic", api_key="...")

    # Use the provider
    response = await provider.complete(messages, model="claude-sonnet-4-20250514")
"""

from typing import Dict, List, Optional, Type

from .base import (
    AuthenticationError,
    ContentBlock,
    InvalidRequestError,
    LLMError,
    LLMProvider,
    LLMResponse,
    Message,
    MessageRole,
    ModelInfo,
    ModelNotFoundError,
    RateLimitError,
    StreamEvent,
    StreamEventType,
    ToolDefinition,
    ToolResult,
    ToolUse,
)
from .anthropic_provider import AnthropicProvider
from .openai_provider import OpenAIProvider
from .deepseek_provider import DeepSeekProvider
from .minimax_provider import MinimaxProvider
from .zai_provider import ZAIProvider

# Registry of available providers
_PROVIDERS: Dict[str, Type[LLMProvider]] = {
    "anthropic": AnthropicProvider,
    "openai": OpenAIProvider,
    "deepseek": DeepSeekProvider,
    "minimax": MinimaxProvider,
    "zai": ZAIProvider,
}

# Cache of provider instances
_provider_instances: Dict[str, LLMProvider] = {}


def register_provider(name: str, provider_class: Type[LLMProvider]) -> None:
    """
    Register a new LLM provider.

    Args:
        name: Provider identifier
        provider_class: Provider class implementing LLMProvider
    """
    _PROVIDERS[name] = provider_class


def get_provider(
    provider_name: str,
    api_key: str,
    *,
    use_cache: bool = True,
) -> LLMProvider:
    """
    Get an LLM provider instance.

    Args:
        provider_name: Name of the provider (e.g., "anthropic", "openai")
        api_key: API key for the provider
        use_cache: Whether to cache and reuse provider instances

    Returns:
        LLMProvider instance

    Raises:
        ValueError: If the provider is not registered
    """
    if provider_name not in _PROVIDERS:
        available = ", ".join(_PROVIDERS.keys())
        raise ValueError(
            f"Unknown provider: {provider_name}. Available providers: {available}"
        )

    cache_key = f"{provider_name}:{api_key[:8]}..."

    if use_cache and cache_key in _provider_instances:
        return _provider_instances[cache_key]

    provider_class = _PROVIDERS[provider_name]
    instance = provider_class(api_key=api_key)

    if use_cache:
        _provider_instances[cache_key] = instance

    return instance


def get_available_providers() -> List[str]:
    """
    Get list of registered provider names.

    Returns:
        List of provider names
    """
    return list(_PROVIDERS.keys())


def get_all_models() -> List[ModelInfo]:
    """
    Get all available models from all registered providers.

    Note: This requires API keys to be configured in settings.

    Returns:
        List of ModelInfo from all providers
    """
    # Import here to avoid circular imports
    from app.services.config_service import settings

    all_models: List[ModelInfo] = []

    # Add Anthropic models if API key is configured
    if settings.ANTHROPIC_API_KEY:
        try:
            provider = get_provider("anthropic", settings.ANTHROPIC_API_KEY)
            all_models.extend(provider.get_available_models())
        except Exception:
            pass

    # Add OpenAI models if API key is configured
    if settings.OPENAI_API_KEY and "openai" in _PROVIDERS:
        try:
            provider = get_provider("openai", settings.OPENAI_API_KEY)
            all_models.extend(provider.get_available_models())
        except Exception:
            pass

    # Add DeepSeek models if API key is configured
    if settings.DEEPSEEK_API_KEY and "deepseek" in _PROVIDERS:
        try:
            provider = get_provider("deepseek", settings.DEEPSEEK_API_KEY)
            all_models.extend(provider.get_available_models())
        except Exception:
            pass

    # Add Minimax models if API key is configured
    if settings.MINIMAX_API_KEY and "minimax" in _PROVIDERS:
        try:
            provider = get_provider("minimax", settings.MINIMAX_API_KEY)
            all_models.extend(provider.get_available_models())
        except Exception:
            pass

    # Add ZAI models if API key is configured
    if settings.ZAI_API_KEY and "zai" in _PROVIDERS:
        try:
            provider = get_provider("zai", settings.ZAI_API_KEY)
            all_models.extend(provider.get_available_models())
        except Exception:
            pass

    return all_models


async def close_all_providers() -> None:
    """Close all cached provider instances."""
    for provider in _provider_instances.values():
        await provider.close()
    _provider_instances.clear()


__all__ = [
    # Base types
    "LLMProvider",
    "LLMResponse",
    "LLMError",
    "AuthenticationError",
    "RateLimitError",
    "InvalidRequestError",
    "ModelNotFoundError",
    # Message types
    "Message",
    "MessageRole",
    "ContentBlock",
    # Tool types
    "ToolDefinition",
    "ToolUse",
    "ToolResult",
    # Stream types
    "StreamEvent",
    "StreamEventType",
    # Model info
    "ModelInfo",
    # Provider implementations
    "AnthropicProvider",
    "OpenAIProvider",
    "DeepSeekProvider",
    "MinimaxProvider",
    "ZAIProvider",
    # Factory functions
    "get_provider",
    "get_available_providers",
    "get_all_models",
    "register_provider",
    "close_all_providers",
]
