"""
Minimax API provider implementation.

This module provides the LLM provider implementation for Minimax models.
Minimax uses an OpenAI-compatible API.
"""

import logging
from typing import List

from .base import ModelInfo
from .openai_provider import OpenAIProvider

logger = logging.getLogger(__name__)


# Available Minimax models
MINIMAX_MODELS: List[ModelInfo] = [
    ModelInfo(
        id="abab6.5s-chat",
        name="ABAB 6.5s Chat",
        provider="minimax",
        description="Minimax's conversational AI model",
        max_tokens=8192,
        supports_tools=True,
        supports_vision=False,
        supports_streaming=True,
        input_cost_per_million=1.0,
        output_cost_per_million=2.0,
    ),
    ModelInfo(
        id="abab6.5t-chat",
        name="ABAB 6.5t Chat",
        provider="minimax",
        description="Minimax's turbo chat model",
        max_tokens=8192,
        supports_tools=True,
        supports_vision=False,
        supports_streaming=True,
        input_cost_per_million=0.5,
        output_cost_per_million=1.0,
    ),
    ModelInfo(
        id="abab5.5s-chat",
        name="ABAB 5.5s Chat",
        provider="minimax",
        description="Previous generation Minimax model",
        max_tokens=4096,
        supports_tools=True,
        supports_vision=False,
        supports_streaming=True,
        input_cost_per_million=0.3,
        output_cost_per_million=0.6,
    ),
]


class MinimaxProvider(OpenAIProvider):
    """
    Minimax API provider.

    Uses OpenAI-compatible API with Minimax's endpoint.
    """

    provider_name = "minimax"
    MINIMAX_BASE_URL = "https://api.minimax.chat/v1"

    def __init__(self, api_key: str):
        """
        Initialize the Minimax provider.

        Args:
            api_key: Minimax API key
        """
        super().__init__(api_key, base_url=self.MINIMAX_BASE_URL)

    def get_available_models(self) -> List[ModelInfo]:
        """Get available Minimax models."""
        return MINIMAX_MODELS.copy()

    def supports_tools(self, model: str) -> bool:
        """Check if the model supports tools."""
        for m in MINIMAX_MODELS:
            if m.id == model:
                return m.supports_tools
        return True

    def supports_vision(self, model: str) -> bool:
        """Check if the model supports vision."""
        for m in MINIMAX_MODELS:
            if m.id == model:
                return m.supports_vision
        return False
