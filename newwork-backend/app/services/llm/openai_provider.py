"""
OpenAI GPT API provider implementation.

This module provides the LLM provider implementation for OpenAI's GPT models.
"""

import json
import logging
from typing import Any, AsyncGenerator, Dict, List, Optional

try:
    from openai import AsyncOpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    AsyncOpenAI = None

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


# Available GPT models with their capabilities
GPT_MODELS: List[ModelInfo] = [
    ModelInfo(
        id="gpt-4o",
        name="GPT-4o",
        provider="openai",
        description="Most capable GPT-4 model with vision",
        max_tokens=4096,
        supports_tools=True,
        supports_vision=True,
        supports_streaming=True,
        input_cost_per_million=5.0,
        output_cost_per_million=15.0,
    ),
    ModelInfo(
        id="gpt-4o-mini",
        name="GPT-4o Mini",
        provider="openai",
        description="Smaller, faster, and cheaper GPT-4o",
        max_tokens=4096,
        supports_tools=True,
        supports_vision=True,
        supports_streaming=True,
        input_cost_per_million=0.15,
        output_cost_per_million=0.60,
    ),
    ModelInfo(
        id="gpt-4-turbo",
        name="GPT-4 Turbo",
        provider="openai",
        description="GPT-4 with improved performance",
        max_tokens=4096,
        supports_tools=True,
        supports_vision=True,
        supports_streaming=True,
        input_cost_per_million=10.0,
        output_cost_per_million=30.0,
    ),
    ModelInfo(
        id="gpt-3.5-turbo",
        name="GPT-3.5 Turbo",
        provider="openai",
        description="Fast and efficient for simpler tasks",
        max_tokens=4096,
        supports_tools=True,
        supports_vision=False,
        supports_streaming=True,
        input_cost_per_million=0.50,
        output_cost_per_million=1.50,
    ),
]


class OpenAIProvider(LLMProvider):
    """
    OpenAI GPT API provider.

    Implements the LLMProvider interface for OpenAI's GPT models.
    """

    provider_name = "openai"

    def __init__(self, api_key: str, base_url: Optional[str] = None):
        """
        Initialize the OpenAI provider.

        Args:
            api_key: OpenAI API key
            base_url: Optional custom base URL for API-compatible services

        Raises:
            ImportError: If the openai package is not installed
        """
        if not OPENAI_AVAILABLE:
            raise ImportError(
                "openai package is not installed. "
                "Install it with: pip install openai"
            )

        self.api_key = api_key
        self.base_url = base_url
        self._client: Optional[AsyncOpenAI] = None

    @property
    def client(self) -> AsyncOpenAI:
        """Get or create the async client."""
        if self._client is None:
            kwargs = {"api_key": self.api_key}
            if self.base_url:
                kwargs["base_url"] = self.base_url
            self._client = AsyncOpenAI(**kwargs)
        return self._client

    async def close(self) -> None:
        """Close the client connection."""
        if self._client is not None:
            await self._client.close()
            self._client = None

    def _convert_messages(self, messages: List[Message]) -> List[Dict[str, Any]]:
        """Convert internal message format to OpenAI API format."""
        return [msg.to_openai_format() for msg in messages]

    def _convert_tools(
        self, tools: Optional[List[ToolDefinition]]
    ) -> Optional[List[Dict[str, Any]]]:
        """Convert tool definitions to OpenAI API format."""
        if not tools:
            return None
        return [tool.to_openai_format() for tool in tools]

    def _parse_response(self, response: Any) -> LLMResponse:
        """Parse OpenAI API response to internal format."""
        content_blocks = []
        choice = response.choices[0]
        message = choice.message

        # Add text content
        if message.content:
            content_blocks.append(ContentBlock(
                type="text",
                text=message.content,
            ))

        # Add tool calls
        if message.tool_calls:
            for tool_call in message.tool_calls:
                try:
                    arguments = json.loads(tool_call.function.arguments)
                except json.JSONDecodeError:
                    arguments = {}

                content_blocks.append(ContentBlock(
                    type="tool_use",
                    tool_use=ToolUse(
                        id=tool_call.id,
                        name=tool_call.function.name,
                        arguments=arguments,
                    ),
                ))

        usage = None
        if hasattr(response, "usage") and response.usage:
            usage = {
                "input_tokens": response.usage.prompt_tokens,
                "output_tokens": response.usage.completion_tokens,
            }

        return LLMResponse(
            content=content_blocks,
            stop_reason=choice.finish_reason,
            usage=usage,
            model=response.model,
        )

    def _handle_error(self, error: Exception) -> None:
        """Convert OpenAI errors to internal error types."""
        if not OPENAI_AVAILABLE:
            raise LLMError(str(error), provider=self.provider_name)

        from openai import AuthenticationError as OAIAuthError
        from openai import RateLimitError as OAIRateLimitError
        from openai import BadRequestError as OAIBadRequestError

        error_msg = str(error)

        if isinstance(error, OAIAuthError):
            raise AuthenticationError(
                "Invalid OpenAI API key",
                provider=self.provider_name,
            )
        elif isinstance(error, OAIRateLimitError):
            raise RateLimitError(
                "OpenAI rate limit exceeded",
                provider=self.provider_name,
            )
        elif isinstance(error, OAIBadRequestError):
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
        """Generate a completion using GPT."""
        try:
            api_messages = self._convert_messages(messages)

            # Add system prompt if provided
            if system_prompt:
                api_messages.insert(0, {
                    "role": "system",
                    "content": system_prompt,
                })

            kwargs: Dict[str, Any] = {
                "model": model,
                "messages": api_messages,
                "max_tokens": max_tokens,
                "temperature": temperature,
            }

            api_tools = self._convert_tools(tools)
            if api_tools:
                kwargs["tools"] = api_tools

            response = await self.client.chat.completions.create(**kwargs)
            return self._parse_response(response)

        except Exception as e:
            logger.error(f"OpenAI completion error: {e}")
            self._handle_error(e)
            raise

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
        """Stream a completion using GPT."""
        try:
            api_messages = self._convert_messages(messages)

            # Add system prompt if provided
            if system_prompt:
                api_messages.insert(0, {
                    "role": "system",
                    "content": system_prompt,
                })

            kwargs: Dict[str, Any] = {
                "model": model,
                "messages": api_messages,
                "max_tokens": max_tokens,
                "temperature": temperature,
                "stream": True,
            }

            api_tools = self._convert_tools(tools)
            if api_tools:
                kwargs["tools"] = api_tools

            # Track current tool calls
            current_tool_calls: Dict[int, Dict[str, Any]] = {}

            yield StreamEvent(type=StreamEventType.MESSAGE_START)

            async for chunk in await self.client.chat.completions.create(**kwargs):
                if not chunk.choices:
                    continue

                delta = chunk.choices[0].delta

                # Handle text content
                if delta.content:
                    yield StreamEvent(
                        type=StreamEventType.TEXT_DELTA,
                        text=delta.content,
                    )

                # Handle tool calls
                if delta.tool_calls:
                    for tool_call in delta.tool_calls:
                        idx = tool_call.index

                        if idx not in current_tool_calls:
                            # New tool call
                            current_tool_calls[idx] = {
                                "id": tool_call.id or "",
                                "name": tool_call.function.name if tool_call.function else "",
                                "arguments": "",
                            }
                            if tool_call.function and tool_call.function.name:
                                yield StreamEvent(
                                    type=StreamEventType.TOOL_USE_START,
                                    tool_use_id=current_tool_calls[idx]["id"],
                                    tool_name=current_tool_calls[idx]["name"],
                                )

                        # Accumulate arguments
                        if tool_call.function and tool_call.function.arguments:
                            current_tool_calls[idx]["arguments"] += tool_call.function.arguments
                            yield StreamEvent(
                                type=StreamEventType.TOOL_USE_DELTA,
                                tool_use_id=current_tool_calls[idx]["id"],
                                tool_input_delta=tool_call.function.arguments,
                            )

                # Handle finish
                if chunk.choices[0].finish_reason:
                    # Complete any pending tool calls
                    for tc in current_tool_calls.values():
                        try:
                            args = json.loads(tc["arguments"]) if tc["arguments"] else {}
                        except json.JSONDecodeError:
                            args = {}

                        yield StreamEvent(
                            type=StreamEventType.TOOL_USE_END,
                            tool_use=ToolUse(
                                id=tc["id"],
                                name=tc["name"],
                                arguments=args,
                            ),
                        )

                    yield StreamEvent(type=StreamEventType.MESSAGE_END)

        except Exception as e:
            logger.error(f"OpenAI streaming error: {e}")
            yield StreamEvent(
                type=StreamEventType.ERROR,
                error=str(e),
            )

    def get_available_models(self) -> List[ModelInfo]:
        """Get available GPT models."""
        return GPT_MODELS.copy()

    def supports_tools(self, model: str) -> bool:
        """Check if the model supports tools."""
        for m in GPT_MODELS:
            if m.id == model:
                return m.supports_tools
        return True

    def supports_vision(self, model: str) -> bool:
        """Check if the model supports vision."""
        for m in GPT_MODELS:
            if m.id == model:
                return m.supports_vision
        return "gpt-4" in model
