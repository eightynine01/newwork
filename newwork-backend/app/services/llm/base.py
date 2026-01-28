"""
Base LLM Provider interface and common types.

This module defines the abstract interface that all LLM providers must implement,
along with common data structures for messages, tools, and responses.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum
from typing import (
    Any,
    AsyncGenerator,
    Dict,
    List,
    Optional,
    Union,
)


class MessageRole(str, Enum):
    """Role of the message sender."""

    SYSTEM = "system"
    USER = "user"
    ASSISTANT = "assistant"
    TOOL = "tool"


class StreamEventType(str, Enum):
    """Types of streaming events."""

    TEXT_DELTA = "text_delta"
    TOOL_USE_START = "tool_use_start"
    TOOL_USE_DELTA = "tool_use_delta"
    TOOL_USE_END = "tool_use_end"
    MESSAGE_START = "message_start"
    MESSAGE_DELTA = "message_delta"
    MESSAGE_END = "message_end"
    ERROR = "error"


@dataclass
class ToolDefinition:
    """Definition of a tool that can be used by the LLM."""

    name: str
    description: str
    input_schema: Dict[str, Any]

    def to_anthropic_format(self) -> Dict[str, Any]:
        """Convert to Anthropic API format."""
        return {
            "name": self.name,
            "description": self.description,
            "input_schema": self.input_schema,
        }

    def to_openai_format(self) -> Dict[str, Any]:
        """Convert to OpenAI API format."""
        return {
            "type": "function",
            "function": {
                "name": self.name,
                "description": self.description,
                "parameters": self.input_schema,
            },
        }


@dataclass
class ToolUse:
    """Represents a tool call made by the LLM."""

    id: str
    name: str
    arguments: Dict[str, Any]


@dataclass
class ToolResult:
    """Result of a tool execution."""

    tool_use_id: str
    content: str
    is_error: bool = False


@dataclass
class ContentBlock:
    """A block of content in a message."""

    type: str  # "text" or "tool_use" or "tool_result" or "image"
    text: Optional[str] = None
    tool_use: Optional[ToolUse] = None
    tool_result: Optional[ToolResult] = None
    image_data: Optional[str] = None  # base64 encoded
    image_media_type: Optional[str] = None


@dataclass
class Message:
    """A message in the conversation."""

    role: MessageRole
    content: Union[str, List[ContentBlock]]

    def to_anthropic_format(self) -> Dict[str, Any]:
        """Convert to Anthropic API format."""
        if isinstance(self.content, str):
            return {
                "role": self.role.value,
                "content": self.content,
            }

        # Handle content blocks
        content_blocks = []
        for block in self.content:
            if block.type == "text" and block.text:
                content_blocks.append({
                    "type": "text",
                    "text": block.text,
                })
            elif block.type == "tool_use" and block.tool_use:
                content_blocks.append({
                    "type": "tool_use",
                    "id": block.tool_use.id,
                    "name": block.tool_use.name,
                    "input": block.tool_use.arguments,
                })
            elif block.type == "tool_result" and block.tool_result:
                content_blocks.append({
                    "type": "tool_result",
                    "tool_use_id": block.tool_result.tool_use_id,
                    "content": block.tool_result.content,
                    "is_error": block.tool_result.is_error,
                })
            elif block.type == "image" and block.image_data:
                content_blocks.append({
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": block.image_media_type or "image/png",
                        "data": block.image_data,
                    },
                })

        return {
            "role": self.role.value,
            "content": content_blocks,
        }

    def to_openai_format(self) -> Dict[str, Any]:
        """Convert to OpenAI API format."""
        if isinstance(self.content, str):
            return {
                "role": self.role.value,
                "content": self.content,
            }

        # For OpenAI, tool results are handled differently
        result: Dict[str, Any] = {"role": self.role.value}

        # Collect text content
        text_parts = []
        tool_calls = []

        for block in self.content:
            if block.type == "text" and block.text:
                text_parts.append(block.text)
            elif block.type == "tool_use" and block.tool_use:
                tool_calls.append({
                    "id": block.tool_use.id,
                    "type": "function",
                    "function": {
                        "name": block.tool_use.name,
                        "arguments": str(block.tool_use.arguments),
                    },
                })
            elif block.type == "tool_result" and block.tool_result:
                # OpenAI uses separate messages for tool results
                return {
                    "role": "tool",
                    "tool_call_id": block.tool_result.tool_use_id,
                    "content": block.tool_result.content,
                }

        if text_parts:
            result["content"] = "\n".join(text_parts)
        if tool_calls:
            result["tool_calls"] = tool_calls

        return result


@dataclass
class StreamEvent:
    """An event from a streaming response."""

    type: StreamEventType
    text: Optional[str] = None
    tool_use: Optional[ToolUse] = None
    tool_use_id: Optional[str] = None
    tool_name: Optional[str] = None
    tool_input_delta: Optional[str] = None
    error: Optional[str] = None
    usage: Optional[Dict[str, int]] = None


@dataclass
class LLMResponse:
    """Response from an LLM completion."""

    content: List[ContentBlock]
    stop_reason: Optional[str] = None
    usage: Optional[Dict[str, int]] = None
    model: Optional[str] = None

    @property
    def text(self) -> str:
        """Get the text content of the response."""
        text_parts = []
        for block in self.content:
            if block.type == "text" and block.text:
                text_parts.append(block.text)
        return "\n".join(text_parts)

    @property
    def tool_uses(self) -> List[ToolUse]:
        """Get all tool uses from the response."""
        tool_uses = []
        for block in self.content:
            if block.type == "tool_use" and block.tool_use:
                tool_uses.append(block.tool_use)
        return tool_uses

    @property
    def has_tool_use(self) -> bool:
        """Check if the response contains tool uses."""
        return len(self.tool_uses) > 0


@dataclass
class ModelInfo:
    """Information about an available model."""

    id: str
    name: str
    provider: str
    description: Optional[str] = None
    max_tokens: int = 4096
    supports_tools: bool = True
    supports_vision: bool = False
    supports_streaming: bool = True
    input_cost_per_million: float = 0.0
    output_cost_per_million: float = 0.0


class LLMProvider(ABC):
    """
    Abstract base class for LLM providers.

    All LLM providers (Anthropic, OpenAI, DeepSeek, etc.) must implement this interface.
    """

    provider_name: str = "base"

    @abstractmethod
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
        """
        Generate a completion for the given messages.

        Args:
            messages: List of conversation messages
            model: Model identifier to use
            tools: Optional list of tool definitions
            max_tokens: Maximum tokens in the response
            temperature: Sampling temperature
            system_prompt: Optional system prompt

        Returns:
            LLMResponse containing the completion
        """
        pass

    @abstractmethod
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
        """
        Stream a completion for the given messages.

        Args:
            messages: List of conversation messages
            model: Model identifier to use
            tools: Optional list of tool definitions
            max_tokens: Maximum tokens in the response
            temperature: Sampling temperature
            system_prompt: Optional system prompt

        Yields:
            StreamEvent objects as the completion is generated
        """
        pass

    @abstractmethod
    def get_available_models(self) -> List[ModelInfo]:
        """
        Get list of available models for this provider.

        Returns:
            List of ModelInfo objects
        """
        pass

    @abstractmethod
    def supports_tools(self, model: str) -> bool:
        """
        Check if the given model supports tool use.

        Args:
            model: Model identifier

        Returns:
            True if the model supports tools
        """
        pass

    @abstractmethod
    def supports_vision(self, model: str) -> bool:
        """
        Check if the given model supports vision/image inputs.

        Args:
            model: Model identifier

        Returns:
            True if the model supports vision
        """
        pass

    async def close(self) -> None:
        """
        Close any resources held by the provider.

        Override this method if the provider needs cleanup.
        """
        pass


class LLMError(Exception):
    """Base exception for LLM-related errors."""

    def __init__(self, message: str, provider: str = "unknown", code: Optional[str] = None):
        super().__init__(message)
        self.provider = provider
        self.code = code


class AuthenticationError(LLMError):
    """Raised when authentication fails."""
    pass


class RateLimitError(LLMError):
    """Raised when rate limit is exceeded."""
    pass


class InvalidRequestError(LLMError):
    """Raised when the request is invalid."""
    pass


class ModelNotFoundError(LLMError):
    """Raised when the requested model is not found."""
    pass
