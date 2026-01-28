"""
ZAI API provider implementation.

This module provides the LLM provider implementation for ZAI models.
ZAI (assuming OpenAI-compatible API).
"""

import logging
from typing import List

from .base import ModelInfo
from .openai_provider import OpenAIProvider

logger = logging.getLogger(__name__)


# Available ZAI models
ZAI_MODELS: List[ModelInfo] = [
    ModelInfo(
        id="zai-1.0",
        name="ZAI 1.0",
        provider="zai",
        description="ZAI's primary conversational model",
        max_tokens=4096,
        supports_tools=True,
        supports_vision=False,
        supports_streaming=True,
        input_cost_per_million=1.0,
        output_cost_per_million=2.0,
    ),
    ModelInfo(
        id="zai-1.0-mini",
        name="ZAI 1.0 Mini",
        provider="zai",
        description="Smaller, faster ZAI model",
        max_tokens=4096,
        supports_tools=True,
        supports_vision=False,
        supports_streaming=True,
        input_cost_per_million=0.3,
        output_cost_per_million=0.6,
    ),
]


class ZAIProvider(OpenAIProvider):
    """
    ZAI API provider.

    Uses OpenAI-compatible API with ZAI's endpoint.
    """

    provider_name = "zai"
    # Note: Update this URL to the actual ZAI API endpoint
    ZAI_BASE_URL = "https://api.zai.ai/v1"

    def __init__(self, api_key: str):
        """
        Initialize the ZAI provider.

        Args:
            api_key: ZAI API key
        """
        super().__init__(api_key, base_url=self.ZAI_BASE_URL)

    def get_available_models(self) -> List[ModelInfo]:
        """Get available ZAI models."""
        return ZAI_MODELS.copy()

    def supports_tools(self, model: str) -> bool:
        """Check if the model supports tools."""
        for m in ZAI_MODELS:
            if m.id == model:
                return m.supports_tools
        return True

    def supports_vision(self, model: str) -> bool:
        """Check if the model supports vision."""
        for m in ZAI_MODELS:
            if m.id == model:
                return m.supports_vision
        return False
