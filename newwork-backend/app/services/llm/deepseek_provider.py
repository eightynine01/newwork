"""
DeepSeek API provider implementation.

This module provides the LLM provider implementation for DeepSeek models.
DeepSeek uses an OpenAI-compatible API.
"""

import logging
from typing import AsyncGenerator, List, Optional

from .base import (
    LLMResponse,
    Message,
    ModelInfo,
    StreamEvent,
    ToolDefinition,
)
from .openai_provider import OpenAIProvider

logger = logging.getLogger(__name__)


# Available DeepSeek models
DEEPSEEK_MODELS: List[ModelInfo] = [
    ModelInfo(
        id="deepseek-chat",
        name="DeepSeek Chat",
        provider="deepseek",
        description="DeepSeek's conversational AI model",
        max_tokens=4096,
        supports_tools=True,
        supports_vision=False,
        supports_streaming=True,
        input_cost_per_million=0.14,
        output_cost_per_million=0.28,
    ),
    ModelInfo(
        id="deepseek-coder",
        name="DeepSeek Coder",
        provider="deepseek",
        description="Specialized model for coding tasks",
        max_tokens=4096,
        supports_tools=True,
        supports_vision=False,
        supports_streaming=True,
        input_cost_per_million=0.14,
        output_cost_per_million=0.28,
    ),
    ModelInfo(
        id="deepseek-reasoner",
        name="DeepSeek Reasoner",
        provider="deepseek",
        description="Model with enhanced reasoning capabilities",
        max_tokens=8192,
        supports_tools=True,
        supports_vision=False,
        supports_streaming=True,
        input_cost_per_million=0.55,
        output_cost_per_million=2.19,
    ),
]


class DeepSeekProvider(OpenAIProvider):
    """
    DeepSeek API provider.

    Uses OpenAI-compatible API with DeepSeek's endpoint.
    """

    provider_name = "deepseek"
    DEEPSEEK_BASE_URL = "https://api.deepseek.com/v1"

    def __init__(self, api_key: str):
        """
        Initialize the DeepSeek provider.

        Args:
            api_key: DeepSeek API key
        """
        super().__init__(api_key, base_url=self.DEEPSEEK_BASE_URL)

    def get_available_models(self) -> List[ModelInfo]:
        """Get available DeepSeek models."""
        return DEEPSEEK_MODELS.copy()

    def supports_tools(self, model: str) -> bool:
        """Check if the model supports tools."""
        for m in DEEPSEEK_MODELS:
            if m.id == model:
                return m.supports_tools
        return True

    def supports_vision(self, model: str) -> bool:
        """Check if the model supports vision."""
        for m in DEEPSEEK_MODELS:
            if m.id == model:
                return m.supports_vision
        return False
