from typing import Callable, Dict, Any, Optional
from enum import Enum
import asyncio
from datetime import datetime


class EventType(str, Enum):
    """
    Event types for OpenCode events.
    """

    MESSAGE = "message"
    TOOL_CALL = "tool_call"
    TODO_UPDATE = "todo_update"
    PERMISSION_REQUEST = "permission_request"
    ERROR = "error"
    STATUS = "status"
    STREAM_CHUNK = "stream_chunk"


class EventService:
    """
    Service for managing and broadcasting events.

    Handles SSE streaming and event distribution to clients.
    """

    def __init__(self):
        """Initialize the event service."""
        self._listeners: Dict[str, asyncio.Queue] = {}

    def register_listener(self, listener_id: str) -> asyncio.Queue:
        """
        Register a new event listener.

        Args:
            listener_id: Unique identifier for the listener

        Returns:
            Queue for receiving events
        """
        queue: asyncio.Queue = asyncio.Queue()
        self._listeners[listener_id] = queue
        return queue

    def unregister_listener(self, listener_id: str) -> None:
        """
        Unregister an event listener.

        Args:
            listener_id: The listener ID to unregister
        """
        if listener_id in self._listeners:
            del self._listeners[listener_id]

    async def broadcast(self, event: Dict[str, Any]) -> None:
        """
        Broadcast an event to all listeners.

        Args:
            event: Event data to broadcast
        """
        # Add timestamp to event
        event["timestamp"] = datetime.utcnow().isoformat()

        # Send to all listeners
        for queue in self._listeners.values():
            try:
                await queue.put(event)
            except Exception:
                pass  # Listener might have been removed

    async def send_to_listener(self, listener_id: str, event: Dict[str, Any]) -> bool:
        """
        Send an event to a specific listener.

        Args:
            listener_id: The listener ID
            event: Event data to send

        Returns:
            True if sent successfully, False otherwise
        """
        if listener_id not in self._listeners:
            return False

        event["timestamp"] = datetime.utcnow().isoformat()

        try:
            await self._listeners[listener_id].put(event)
            return True
        except Exception:
            return False

    async def event_generator(self, listener_id: str, timeout: Optional[float] = None):
        """
        Generator for SSE events.

        Args:
            listener_id: The listener ID
            timeout: Optional timeout in seconds

        Yields:
            Event data for SSE streaming
        """
        queue = self.register_listener(listener_id)

        try:
            while True:
                try:
                    # Wait for event with timeout
                    event = await asyncio.wait_for(queue.get(), timeout=timeout)
                    yield event
                except asyncio.TimeoutError:
                    yield {"type": EventType.STATUS, "data": {"status": "keepalive"}}
                except Exception:
                    break
        finally:
            self.unregister_listener(listener_id)

    def create_message_event(
        self, session_id: str, role: str, content: str
    ) -> Dict[str, Any]:
        """
        Create a message event.

        Args:
            session_id: Session ID
            role: Message role (user/assistant)
            content: Message content

        Returns:
            Event dictionary
        """
        return {
            "type": EventType.MESSAGE,
            "session_id": session_id,
            "data": {"role": role, "content": content},
        }

    def create_tool_call_event(
        self,
        session_id: str,
        tool_name: str,
        tool_args: Dict[str, Any],
        result: Optional[Any] = None,
    ) -> Dict[str, Any]:
        """
        Create a tool call event.

        Args:
            session_id: Session ID
            tool_name: Name of the tool
            tool_args: Arguments passed to the tool
            result: Optional tool result

        Returns:
            Event dictionary
        """
        data = {"tool_name": tool_name, "tool_args": tool_args}
        if result is not None:
            data["result"] = result

        return {"type": EventType.TOOL_CALL, "session_id": session_id, "data": data}

    def create_todo_update_event(self, session_id: str, todos: Any) -> Dict[str, Any]:
        """
        Create a todo update event.

        Args:
            session_id: Session ID
            todos: Todo list data

        Returns:
            Event dictionary
        """
        return {
            "type": EventType.TODO_UPDATE,
            "session_id": session_id,
            "data": {"todos": todos},
        }

    def create_permission_request_event(
        self, session_id: str, permission_id: str, description: str
    ) -> Dict[str, Any]:
        """
        Create a permission request event.

        Args:
            session_id: Session ID
            permission_id: Permission ID
            description: Permission description

        Returns:
            Event dictionary
        """
        return {
            "type": EventType.PERMISSION_REQUEST,
            "session_id": session_id,
            "data": {"permission_id": permission_id, "description": description},
        }

    def create_error_event(
        self, session_id: str, error_message: str, error_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create an error event.

        Args:
            session_id: Session ID
            error_message: Error message
            error_type: Optional error type

        Returns:
            Event dictionary
        """
        data = {"error_message": error_message}
        if error_type:
            data["error_type"] = error_type

        return {"type": EventType.ERROR, "session_id": session_id, "data": data}

    def create_stream_chunk_event(self, session_id: str, chunk: str) -> Dict[str, Any]:
        """
        Create a stream chunk event.

        Args:
            session_id: Session ID
            chunk: Text chunk

        Returns:
            Event dictionary
        """
        return {
            "type": EventType.STREAM_CHUNK,
            "session_id": session_id,
            "data": {"chunk": chunk},
        }


# Global event service instance
event_service = EventService()
