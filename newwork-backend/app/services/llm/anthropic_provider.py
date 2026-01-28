"""
Anthropic Claude API provider implementation.

This module provides the LLM provider implementation for Anthropic's Claude models.
"""

import json
import logging
from typing import Any, AsyncGenerator, Dict, List, Optional

try:
    import anthropic
    from anthropic import AsyncAnthropic
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False
    anthropic = None
    AsyncAnthropic = None

from .base import (
    ContentBlock,
    LLMError,
    LLMProvider,
    LLMResponse,
    Message,
    ModelInfo,
    StreamEvent,
    StreamEventType,
    ToolDefinition,
    ToolUse,
    AuthenticationError,
    RateLimitError,
    InvalidRequestError,
)

logger = logging.getLogger(__name__)


# Available Claude models with their capabilities
CLAUDE_MODELS: List[ModelInfo] = [
    ModelInfo(
        id="claude-sonnet-4-20250514",
        name="Claude Sonnet 4",
        provider="anthropic",
        description="Best balance of intelligence and speed",
        max_tokens=8192,
        supports_tools=True,
        supports_vision=True,
        supports_streaming=True,
        input_cost_per_million=3.0,
        output_cost_per_million=15.0,
    ),
    ModelInfo(
        id="claude-opus-4-20250514",
        name="Claude Opus 4",
        provider="anthropic",
        description="Most capable model for complex tasks",
        max_tokens=8192,
        supports_tools=True,
        supports_vision=True,
        supports_streaming=True,
        input_cost_per_million=15.0,
        output_cost_per_million=75.0,
    ),
    ModelInfo(
        id="claude-3-5-sonnet-20241022",
        name="Claude 3.5 Sonnet",
        provider="anthropic",
        description="Previous generation balanced model",
        max_tokens=8192,
        supports_tools=True,
        supports_vision=True,
        supports_streaming=True,
        input_cost_per_million=3.0,
        output_cost_per_million=15.0,
    ),
    ModelInfo(
        id="claude-3-5-haiku-20241022",
        name="Claude 3.5 Haiku",
        provider="anthropic",
        description="Fast and efficient for simple tasks",
        max_tokens=8192,
        supports_tools=True,
        supports_vision=True,
        supports_streaming=True,
        input_cost_per_million=0.8,
        output_cost_per_million=4.0,
    ),
]


class AnthropicProvider(LLMProvider):
    """
    Anthropic Claude API provider.

    Implements the LLMProvider interface for Anthropic's Claude models.
    """

    provider_name = "anthropic"

    def __init__(self, api_key: str):
        """
        Initialize the Anthropic provider.

        Args:
            api_key: Anthropic API key

        Raises:
            ImportError: If the anthropic package is not installed
        """
        if not ANTHROPIC_AVAILABLE:
            raise ImportError(
                "anthropic package is not installed. "
                "Install it with: pip install anthropic"
            )

        self.api_key = api_key
        self._client: Optional[AsyncAnthropic] = None

    @property
    def client(self) -> AsyncAnthropic:
        """Get or create the async client."""
        if self._client is None:
            self._client = AsyncAnthropic(api_key=self.api_key)
        return self._client

    async def close(self) -> None:
        """Close the client connection."""
        if self._client is not None:
            await self._client.close()
            self._client = None

    def _convert_messages(self, messages: List[Message]) -> List[Dict[str, Any]]:
        """Convert internal message format to Anthropic API format."""
        return [msg.to_anthropic_format() for msg in messages]

    def _convert_tools(
        self, tools: Optional[List[ToolDefinition]]
    ) -> Optional[List[Dict[str, Any]]]:
        """Convert tool definitions to Anthropic API format."""
        if not tools:
            return None
        return [tool.to_anthropic_format() for tool in tools]

    def _parse_response(self, response: Any) -> LLMResponse:
        """Parse Anthropic API response to internal format."""
        content_blocks = []

        for block in response.content:
            if block.type == "text":
                content_blocks.append(ContentBlock(
                    type="text",
                    text=block.text,
                ))
            elif block.type == "tool_use":
                content_blocks.append(ContentBlock(
                    type="tool_use",
                    tool_use=ToolUse(
                        id=block.id,
                        name=block.name,
                        arguments=block.input,
                    ),
                ))

        usage = None
        if hasattr(response, "usage") and response.usage:
            usage = {
                "input_tokens": response.usage.input_tokens,
                "output_tokens": response.usage.output_tokens,
            }

        return LLMResponse(
            content=content_blocks,
            stop_reason=response.stop_reason,
            usage=usage,
            model=response.model,
        )

    def _handle_error(self, error: Exception) -> None:
        """Convert Anthropic errors to internal error types."""
        if not ANTHROPIC_AVAILABLE:
            raise LLMError(str(error), provider=self.provider_name)

        error_msg = str(error)

        if isinstance(error, anthropic.AuthenticationError):
            raise AuthenticationError(
                "Invalid Anthropic API key",
                provider=self.provider_name,
            )
        elif isinstance(error, anthropic.RateLimitError):
            raise RateLimitError(
                "Anthropic rate limit exceeded",
                provider=self.provider_name,
            )
        elif isinstance(error, anthropic.BadRequestError):
            raise InvalidRequestError(
                f"Invalid request: {error_msg}",
                provider=self.provider_name,
            )
        else:
            raise LLMError(error_msg, provider=self.provider_name)

    async def complete(
        self,
        messages: List[Message],
        model: str,
        *,
        tools: Optional[List[ToolDefinition]] = None,
        max_tokens: int = 4096,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None,
    ) -> LLMResponse:
        """Generate a completion using Claude."""
        try:
            api_messages = self._convert_messages(messages)
            api_tools = self._convert_tools(tools)

            kwargs: Dict[str, Any] = {
                "model": model,
                "messages": api_messages,
                "max_tokens": max_tokens,
                "temperature": temperature,
            }

            if system_prompt:
                kwargs["system"] = system_prompt

            if api_tools:
                kwargs["tools"] = api_tools

            response = await self.client.messages.create(**kwargs)
            return self._parse_response(response)

        except Exception as e:
            logger.error(f"Anthropic completion error: {e}")
            self._handle_error(e)
            raise  # This line won't be reached but helps type checkers

    async def stream_complete(
        self,
        messages: List[Message],
        model: str,
        *,
        tools: Optional[List[ToolDefinition]] = None,
        max_tokens: int = 4096,
        temperature: float = 0.7,
        system_prompt: Optional[str] = None,
    ) -> AsyncGenerator[StreamEvent, None]:
        """Stream a completion using Claude."""
        try:
            api_messages = self._convert_messages(messages)
            api_tools = self._convert_tools(tools)

            kwargs: Dict[str, Any] = {
                "model": model,
                "messages": api_messages,
                "max_tokens": max_tokens,
                "temperature": temperature,
            }

            if system_prompt:
                kwargs["system"] = system_prompt

            if api_tools:
                kwargs["tools"] = api_tools

            # Track current tool use state for accumulating input
            current_tool_id: Optional[str] = None
            current_tool_name: Optional[str] = None
            current_tool_input: str = ""

            async with self.client.messages.stream(**kwargs) as stream:
                async for event in stream:
                    if event.type == "message_start":
                        yield StreamEvent(type=StreamEventType.MESSAGE_START)

                    elif event.type == "content_block_start":
                        if hasattr(event, "content_block"):
                            block = event.content_block
                            if block.type == "tool_use":
                                current_tool_id = block.id
                                current_tool_name = block.name
                                current_tool_input = ""
                                yield StreamEvent(
                                    type=StreamEventType.TOOL_USE_START,
                                    tool_use_id=block.id,
                                    tool_name=block.name,
                                )

                    elif event.type == "content_block_delta":
                        if hasattr(event, "delta"):
                            delta = event.delta
                            if delta.type == "text_delta":
                                yield StreamEvent(
                                    type=StreamEventType.TEXT_DELTA,
                                    text=delta.text,
                                )
                            elif delta.type == "input_json_delta":
                                current_tool_input += delta.partial_json
                                yield StreamEvent(
                                    type=StreamEventType.TOOL_USE_DELTA,
                                    tool_use_id=current_tool_id,
                                    tool_input_delta=delta.partial_json,
                                )

                    elif event.type == "content_block_stop":
                        if current_tool_id and current_tool_name:
                            # Parse the accumulated tool input
                            try:
                                tool_args = json.loads(current_tool_input) if current_tool_input else {}
                            except json.JSONDecodeError:
                                tool_args = {}

                            yield StreamEvent(
                                type=StreamEventType.TOOL_USE_END,
                                tool_use=ToolUse(
                                    id=current_tool_id,
                                    name=current_tool_name,
                                    arguments=tool_args,
                                ),
                            )
                            current_tool_id = None
                            current_tool_name = None
                            current_tool_input = ""

                    elif event.type == "message_delta":
                        usage = None
                        if hasattr(event, "usage") and event.usage:
                            usage = {
                                "output_tokens": event.usage.output_tokens,
                            }
                        yield StreamEvent(
                            type=StreamEventType.MESSAGE_DELTA,
                            usage=usage,
                        )

                    elif event.type == "message_stop":
                        yield StreamEvent(type=StreamEventType.MESSAGE_END)

        except Exception as e:
            logger.error(f"Anthropic streaming error: {e}")
            yield StreamEvent(
                type=StreamEventType.ERROR,
                error=str(e),
            )

    def get_available_models(self) -> List[ModelInfo]:
        """Get available Claude models."""
        return CLAUDE_MODELS.copy()

    def supports_tools(self, model: str) -> bool:
        """Check if the model supports tools."""
        for m in CLAUDE_MODELS:
            if m.id == model:
                return m.supports_tools
        # Default to True for unknown models
        return True

    def supports_vision(self, model: str) -> bool:
        """Check if the model supports vision."""
        for m in CLAUDE_MODELS:
            if m.id == model:
                return m.supports_vision
        # Default to True for Claude 3+ models
        return "claude-3" in model or "claude-sonnet-4" in model or "claude-opus-4" in model
