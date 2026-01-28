"""
Streaming Handler.

This module handles streaming responses from LLM providers
and converts them to SSE events for the frontend.
"""

import asyncio
import json
import logging
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, AsyncGenerator, Callable, Dict, List, Optional

from app.services.llm import (
    LLMProvider,
    LLMResponse,
    Message,
    StreamEvent,
    StreamEventType,
    ToolDefinition,
    ToolUse,
    get_provider,
)
from app.services.llm.base import ToolResult as LLMToolResult, ContentBlock
from app.services.conversation_service import Conversation, ConversationMessage
from app.services.tool_execution_service import ToolExecutionService, PendingPermission
from app.services.config_service import ConfigService

logger = logging.getLogger(__name__)


class SSEEventType:
    """SSE event types for the frontend."""

    MESSAGE = "message"
    STREAM_CHUNK = "stream_chunk"
    TOOL_CALL = "tool_call"
    TOOL_RESULT = "tool_result"
    TODO_UPDATE = "todo_update"
    PERMISSION_REQUEST = "permission_request"
    STATUS = "status"
    ERROR = "error"
    COMPLETE = "complete"


@dataclass
class SSEEvent:
    """An SSE event to send to the frontend."""

    type: str
    data: Dict[str, Any]
    session_id: str
    timestamp: str = field(default_factory=lambda: datetime.utcnow().isoformat())

    def to_sse(self) -> str:
        """Convert to SSE format."""
        event_data = {
            "type": self.type,
            "data": self.data,
            "session_id": self.session_id,
            "timestamp": self.timestamp,
        }
        return f"data: {json.dumps(event_data)}\n\n"


@dataclass
class StreamingHandler:
    """
    Handles streaming LLM responses and tool execution.

    Manages the conversation loop, streaming responses to SSE,
    and executing tools as requested by the LLM.
    """

    provider: LLMProvider
    conversation: Conversation
    tool_service: ToolExecutionService
    max_tool_iterations: int = 10

    async def process_prompt(
        self,
        prompt: str,
    ) -> AsyncGenerator[SSEEvent, None]:
        """
        Process a user prompt and stream the response.

        This is the main entry point for handling user input.
        It manages the conversation loop, including tool execution.

        Args:
            prompt: The user's prompt

        Yields:
            SSEEvent objects for the frontend
        """
        session_id = self.conversation.session_id

        # Add user message
        self.conversation.add_user_message(prompt)

        yield SSEEvent(
            type=SSEEventType.MESSAGE,
            session_id=session_id,
            data={
                "role": "user",
                "content": prompt,
            },
        )

        # Start processing loop
        iteration = 0
        while iteration < self.max_tool_iterations:
            iteration += 1

            # Stream LLM response
            accumulated_text = ""
            tool_uses: List[ToolUse] = []

            yield SSEEvent(
                type=SSEEventType.STATUS,
                session_id=session_id,
                data={"status": "thinking"},
            )

            try:
                async for event in self._stream_llm_response():
                    if event.type == StreamEventType.TEXT_DELTA and event.text:
                        accumulated_text += event.text
                        yield SSEEvent(
                            type=SSEEventType.STREAM_CHUNK,
                            session_id=session_id,
                            data={
                                "content": event.text,
                                "accumulated": accumulated_text,
                            },
                        )

                    elif event.type == StreamEventType.TOOL_USE_START:
                        yield SSEEvent(
                            type=SSEEventType.TOOL_CALL,
                            session_id=session_id,
                            data={
                                "status": "started",
                                "tool_id": event.tool_use_id,
                                "tool_name": event.tool_name,
                            },
                        )

                    elif event.type == StreamEventType.TOOL_USE_END and event.tool_use:
                        tool_uses.append(event.tool_use)
                        yield SSEEvent(
                            type=SSEEventType.TOOL_CALL,
                            session_id=session_id,
                            data={
                                "status": "complete",
                                "tool_id": event.tool_use.id,
                                "tool_name": event.tool_use.name,
                                "arguments": event.tool_use.arguments,
                            },
                        )

                    elif event.type == StreamEventType.ERROR:
                        yield SSEEvent(
                            type=SSEEventType.ERROR,
                            session_id=session_id,
                            data={"error": event.error},
                        )
                        return

                    elif event.type == StreamEventType.MESSAGE_END:
                        if event.usage:
                            self.conversation.update_token_usage(
                                input_tokens=event.usage.get("input_tokens", 0),
                                output_tokens=event.usage.get("output_tokens", 0),
                            )

            except Exception as e:
                logger.error(f"Streaming error: {e}")
                yield SSEEvent(
                    type=SSEEventType.ERROR,
                    session_id=session_id,
                    data={"error": str(e)},
                )
                return

            # Add assistant message
            self.conversation.add_assistant_message(
                content=accumulated_text,
                tool_uses=tool_uses if tool_uses else None,
            )

            # If there are tool uses, execute them
            if tool_uses:
                yield SSEEvent(
                    type=SSEEventType.STATUS,
                    session_id=session_id,
                    data={"status": "executing_tools"},
                )

                tool_results = await self._execute_tools(tool_uses, session_id)

                # Check for permission requests
                has_pending = bool(self.tool_service.get_pending_permissions())
                if has_pending:
                    # Wait for permission approval (handled externally)
                    yield SSEEvent(
                        type=SSEEventType.STATUS,
                        session_id=session_id,
                        data={
                            "status": "waiting_permission",
                            "pending_count": len(self.tool_service.get_pending_permissions()),
                        },
                    )
                    return  # Exit and wait for permission response

                # Send tool results
                for result in tool_results:
                    yield SSEEvent(
                        type=SSEEventType.TOOL_RESULT,
                        session_id=session_id,
                        data={
                            "tool_use_id": result.tool_use_id,
                            "content": result.content[:1000],  # Truncate for SSE
                            "is_error": result.is_error,
                        },
                    )

                # Add tool results to conversation
                self.conversation.add_tool_results(tool_results)

                # Continue the loop to get next response
                continue
            else:
                # No tool uses, conversation complete
                break

        # Final message
        yield SSEEvent(
            type=SSEEventType.MESSAGE,
            session_id=session_id,
            data={
                "role": "assistant",
                "content": accumulated_text,
            },
        )

        yield SSEEvent(
            type=SSEEventType.COMPLETE,
            session_id=session_id,
            data={
                "total_input_tokens": self.conversation.total_input_tokens,
                "total_output_tokens": self.conversation.total_output_tokens,
            },
        )

    async def _stream_llm_response(self) -> AsyncGenerator[StreamEvent, None]:
        """Stream a response from the LLM."""
        messages = self.conversation.get_llm_messages()
        tools = self.tool_service.get_available_tools()

        async for event in self.provider.stream_complete(
            messages=messages,
            model=self.conversation.model,
            tools=tools,
            system_prompt=self.conversation.system_prompt,
        ):
            yield event

    async def _execute_tools(
        self,
        tool_uses: List[ToolUse],
        session_id: str,
    ) -> List[LLMToolResult]:
        """Execute tool uses and return results."""
        results = []

        for tool_use in tool_uses:
            result = await self.tool_service.execute_tool(tool_use)
            results.append(result)

        return results

    async def continue_after_permission(
        self,
        permission_id: str,
        approved: bool,
        always: bool = False,
    ) -> AsyncGenerator[SSEEvent, None]:
        """
        Continue processing after a permission response.

        Args:
            permission_id: The permission request ID
            approved: Whether permission was granted
            always: If approved, whether to always approve this tool

        Yields:
            SSEEvent objects
        """
        session_id = self.conversation.session_id

        # Process permission response
        self.tool_service.respond_permission(permission_id, approved, always)

        if not approved:
            # Permission denied, add error result
            pending = self.tool_service.get_pending_permissions()
            for p in pending:
                if p.id == permission_id:
                    # Create error result
                    result = LLMToolResult(
                        tool_use_id=p.id,
                        content="Permission denied by user",
                        is_error=True,
                    )
                    self.conversation.add_tool_results([result])

                    yield SSEEvent(
                        type=SSEEventType.TOOL_RESULT,
                        session_id=session_id,
                        data={
                            "tool_use_id": p.id,
                            "content": "Permission denied",
                            "is_error": True,
                        },
                    )
                    break

            yield SSEEvent(
                type=SSEEventType.STATUS,
                session_id=session_id,
                data={"status": "permission_denied"},
            )
            return

        # Permission approved, re-execute pending tool uses
        pending_tool_uses = self.conversation.get_pending_tool_uses()
        if pending_tool_uses:
            tool_results = await self.tool_service.execute_tools(
                pending_tool_uses,
                parallel=True,
            )

            # Send tool results
            for result in tool_results:
                yield SSEEvent(
                    type=SSEEventType.TOOL_RESULT,
                    session_id=session_id,
                    data={
                        "tool_use_id": result.tool_use_id,
                        "content": result.content[:1000],
                        "is_error": result.is_error,
                    },
                )

            # Add to conversation
            self.conversation.add_tool_results(tool_results)

            # Continue processing
            async for event in self._continue_conversation():
                yield event

    async def _continue_conversation(self) -> AsyncGenerator[SSEEvent, None]:
        """Continue the conversation after tool execution."""
        # This essentially re-runs the main loop
        # In practice, you'd call process_prompt without a new user message
        session_id = self.conversation.session_id

        accumulated_text = ""
        tool_uses: List[ToolUse] = []

        yield SSEEvent(
            type=SSEEventType.STATUS,
            session_id=session_id,
            data={"status": "thinking"},
        )

        async for event in self._stream_llm_response():
            if event.type == StreamEventType.TEXT_DELTA and event.text:
                accumulated_text += event.text
                yield SSEEvent(
                    type=SSEEventType.STREAM_CHUNK,
                    session_id=session_id,
                    data={
                        "content": event.text,
                        "accumulated": accumulated_text,
                    },
                )

            elif event.type == StreamEventType.TOOL_USE_END and event.tool_use:
                tool_uses.append(event.tool_use)

        # Add assistant message
        self.conversation.add_assistant_message(
            content=accumulated_text,
            tool_uses=tool_uses if tool_uses else None,
        )

        if tool_uses:
            # More tools to execute
            tool_results = await self.tool_service.execute_tools(tool_uses)
            self.conversation.add_tool_results(tool_results)

            # Continue recursively
            async for event in self._continue_conversation():
                yield event
        else:
            yield SSEEvent(
                type=SSEEventType.MESSAGE,
                session_id=session_id,
                data={
                    "role": "assistant",
                    "content": accumulated_text,
                },
            )

            yield SSEEvent(
                type=SSEEventType.COMPLETE,
                session_id=session_id,
                data={
                    "total_input_tokens": self.conversation.total_input_tokens,
                    "total_output_tokens": self.conversation.total_output_tokens,
                },
            )


def create_streaming_handler(
    session_id: str,
    workspace_path: Path,
    *,
    provider_name: Optional[str] = None,
    model: Optional[str] = None,
    system_prompt: Optional[str] = None,
) -> StreamingHandler:
    """
    Create a streaming handler for a session.

    Args:
        session_id: Session identifier
        workspace_path: Workspace path for tool execution
        provider_name: LLM provider name (default from settings)
        model: Model to use (default from settings)
        system_prompt: Optional system prompt

    Returns:
        Configured StreamingHandler
    """
    from app.services.conversation_service import conversation_service

    # Get settings
    provider_name = provider_name or ConfigService.get_default_provider()
    model = model or ConfigService.get_default_model()

    # Get API key
    api_key = ConfigService.get_api_key(provider_name)
    if not api_key:
        raise ValueError(f"No API key configured for provider: {provider_name}")

    # Create provider
    provider = get_provider(provider_name, api_key)

    # Get or create conversation
    conversation = conversation_service.get_or_create_conversation(
        session_id,
        system_prompt=system_prompt,
        model=model,
        provider=provider_name,
    )

    # Create tool service
    tool_service = ToolExecutionService(
        workspace_path=workspace_path,
        session_id=session_id,
    )

    return StreamingHandler(
        provider=provider,
        conversation=conversation,
        tool_service=tool_service,
    )
