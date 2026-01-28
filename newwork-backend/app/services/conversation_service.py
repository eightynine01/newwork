"""
Conversation Service.

This module manages conversation history and context for LLM interactions.
"""

import logging
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import uuid4

from app.services.llm.base import (
    ContentBlock,
    Message,
    MessageRole,
    ToolResult as LLMToolResult,
    ToolUse,
)

logger = logging.getLogger(__name__)


@dataclass
class ConversationMessage:
    """
    A message in the conversation with metadata.

    Extends the LLM Message format with additional tracking information.
    """

    id: str
    role: MessageRole
    content: str
    tool_uses: List[ToolUse] = field(default_factory=list)
    tool_results: List[LLMToolResult] = field(default_factory=list)
    tokens_used: Optional[int] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_llm_message(self) -> Message:
        """Convert to LLM Message format."""
        # Simple text message
        if not self.tool_uses and not self.tool_results:
            return Message(role=self.role, content=self.content)

        # Message with content blocks
        blocks: List[ContentBlock] = []

        # Add text content if present
        if self.content:
            blocks.append(ContentBlock(type="text", text=self.content))

        # Add tool uses
        for tu in self.tool_uses:
            blocks.append(ContentBlock(
                type="tool_use",
                tool_use=tu,
            ))

        # Add tool results
        for tr in self.tool_results:
            blocks.append(ContentBlock(
                type="tool_result",
                tool_result=tr,
            ))

        return Message(role=self.role, content=blocks)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for storage."""
        return {
            "id": self.id,
            "role": self.role.value,
            "content": self.content,
            "tool_uses": [
                {
                    "id": tu.id,
                    "name": tu.name,
                    "arguments": tu.arguments,
                }
                for tu in self.tool_uses
            ],
            "tool_results": [
                {
                    "tool_use_id": tr.tool_use_id,
                    "content": tr.content,
                    "is_error": tr.is_error,
                }
                for tr in self.tool_results
            ],
            "tokens_used": self.tokens_used,
            "created_at": self.created_at.isoformat(),
            "metadata": self.metadata,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "ConversationMessage":
        """Create from dictionary."""
        return cls(
            id=data["id"],
            role=MessageRole(data["role"]),
            content=data.get("content", ""),
            tool_uses=[
                ToolUse(
                    id=tu["id"],
                    name=tu["name"],
                    arguments=tu["arguments"],
                )
                for tu in data.get("tool_uses", [])
            ],
            tool_results=[
                LLMToolResult(
                    tool_use_id=tr["tool_use_id"],
                    content=tr["content"],
                    is_error=tr.get("is_error", False),
                )
                for tr in data.get("tool_results", [])
            ],
            tokens_used=data.get("tokens_used"),
            created_at=datetime.fromisoformat(data["created_at"]) if data.get("created_at") else datetime.utcnow(),
            metadata=data.get("metadata", {}),
        )


@dataclass
class Conversation:
    """
    Manages a conversation session.

    Tracks message history, system prompt, and conversation metadata.
    """

    session_id: str
    messages: List[ConversationMessage] = field(default_factory=list)
    system_prompt: Optional[str] = None
    model: str = "claude-sonnet-4-20250514"
    provider: str = "anthropic"
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    metadata: Dict[str, Any] = field(default_factory=dict)

    # Token tracking
    total_input_tokens: int = 0
    total_output_tokens: int = 0

    def add_user_message(self, content: str) -> ConversationMessage:
        """
        Add a user message to the conversation.

        Args:
            content: The message content

        Returns:
            The created message
        """
        message = ConversationMessage(
            id=str(uuid4()),
            role=MessageRole.USER,
            content=content,
        )
        self.messages.append(message)
        self.updated_at = datetime.utcnow()
        return message

    def add_assistant_message(
        self,
        content: str,
        tool_uses: Optional[List[ToolUse]] = None,
        tokens_used: Optional[int] = None,
    ) -> ConversationMessage:
        """
        Add an assistant message to the conversation.

        Args:
            content: The message content
            tool_uses: Any tool uses in the message
            tokens_used: Token count for this message

        Returns:
            The created message
        """
        message = ConversationMessage(
            id=str(uuid4()),
            role=MessageRole.ASSISTANT,
            content=content,
            tool_uses=tool_uses or [],
            tokens_used=tokens_used,
        )
        self.messages.append(message)
        self.updated_at = datetime.utcnow()

        if tokens_used:
            self.total_output_tokens += tokens_used

        return message

    def add_tool_results(
        self,
        tool_results: List[LLMToolResult],
    ) -> ConversationMessage:
        """
        Add tool results as a user message.

        Args:
            tool_results: The tool execution results

        Returns:
            The created message
        """
        message = ConversationMessage(
            id=str(uuid4()),
            role=MessageRole.USER,
            content="",
            tool_results=tool_results,
        )
        self.messages.append(message)
        self.updated_at = datetime.utcnow()
        return message

    def get_llm_messages(self) -> List[Message]:
        """
        Get messages in LLM format.

        Returns:
            List of Message objects for the LLM API
        """
        return [msg.to_llm_message() for msg in self.messages]

    def get_last_assistant_message(self) -> Optional[ConversationMessage]:
        """Get the last assistant message."""
        for msg in reversed(self.messages):
            if msg.role == MessageRole.ASSISTANT:
                return msg
        return None

    def get_pending_tool_uses(self) -> List[ToolUse]:
        """
        Get tool uses that haven't been responded to yet.

        Returns:
            List of pending ToolUse objects
        """
        last_assistant = self.get_last_assistant_message()
        if not last_assistant or not last_assistant.tool_uses:
            return []

        # Check if there's a tool result message after the assistant message
        assistant_idx = self.messages.index(last_assistant)
        for msg in self.messages[assistant_idx + 1:]:
            if msg.tool_results:
                return []  # Tool uses have been responded to

        return last_assistant.tool_uses

    def update_token_usage(self, input_tokens: int, output_tokens: int) -> None:
        """Update token usage tracking."""
        self.total_input_tokens += input_tokens
        self.total_output_tokens += output_tokens

    def to_dict(self) -> Dict[str, Any]:
        """Convert conversation to dictionary for storage."""
        return {
            "session_id": self.session_id,
            "messages": [msg.to_dict() for msg in self.messages],
            "system_prompt": self.system_prompt,
            "model": self.model,
            "provider": self.provider,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "metadata": self.metadata,
            "total_input_tokens": self.total_input_tokens,
            "total_output_tokens": self.total_output_tokens,
        }

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Conversation":
        """Create conversation from dictionary."""
        conv = cls(
            session_id=data["session_id"],
            system_prompt=data.get("system_prompt"),
            model=data.get("model", "claude-sonnet-4-20250514"),
            provider=data.get("provider", "anthropic"),
            created_at=datetime.fromisoformat(data["created_at"]) if data.get("created_at") else datetime.utcnow(),
            updated_at=datetime.fromisoformat(data["updated_at"]) if data.get("updated_at") else datetime.utcnow(),
            metadata=data.get("metadata", {}),
            total_input_tokens=data.get("total_input_tokens", 0),
            total_output_tokens=data.get("total_output_tokens", 0),
        )
        conv.messages = [
            ConversationMessage.from_dict(msg)
            for msg in data.get("messages", [])
        ]
        return conv


class ConversationService:
    """
    Service for managing conversations.

    Provides methods for creating, loading, and updating conversations.
    """

    def __init__(self):
        self._conversations: Dict[str, Conversation] = {}

    def create_conversation(
        self,
        session_id: str,
        *,
        system_prompt: Optional[str] = None,
        model: str = "claude-sonnet-4-20250514",
        provider: str = "anthropic",
    ) -> Conversation:
        """
        Create a new conversation.

        Args:
            session_id: Unique session identifier
            system_prompt: Optional system prompt
            model: Model to use
            provider: Provider to use

        Returns:
            New Conversation instance
        """
        conv = Conversation(
            session_id=session_id,
            system_prompt=system_prompt,
            model=model,
            provider=provider,
        )
        self._conversations[session_id] = conv
        return conv

    def get_conversation(self, session_id: str) -> Optional[Conversation]:
        """Get a conversation by session ID."""
        return self._conversations.get(session_id)

    def get_or_create_conversation(
        self,
        session_id: str,
        **kwargs,
    ) -> Conversation:
        """Get existing conversation or create new one."""
        conv = self.get_conversation(session_id)
        if conv is None:
            conv = self.create_conversation(session_id, **kwargs)
        return conv

    def delete_conversation(self, session_id: str) -> bool:
        """Delete a conversation."""
        if session_id in self._conversations:
            del self._conversations[session_id]
            return True
        return False

    def load_conversation(self, session_id: str, data: Dict[str, Any]) -> Conversation:
        """
        Load a conversation from stored data.

        Args:
            session_id: Session identifier
            data: Stored conversation data

        Returns:
            Loaded Conversation instance
        """
        conv = Conversation.from_dict(data)
        self._conversations[session_id] = conv
        return conv


# Global conversation service instance
conversation_service = ConversationService()
