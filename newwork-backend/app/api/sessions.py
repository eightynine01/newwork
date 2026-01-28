"""
Session API endpoints.

This module provides endpoints for managing AI conversation sessions.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import PlainTextResponse, JSONResponse, StreamingResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from pathlib import Path
import json
import asyncio
import uuid
import logging

from app.db.database import get_db
from app.db.repositories import session_repository
from app.schemas import (
    SessionCreate,
    SessionResponse,
    PromptRequest,
    PromptResponse,
)
from app.services.event_service import event_service, EventType
from app.services.config_service import settings, ConfigService
from app.services.session_export_service import SessionExportService
from app.services.conversation_service import conversation_service
from app.services.streaming_handler import create_streaming_handler, SSEEvent

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.get("", response_model=List[SessionResponse])
async def list_sessions(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """
    List all sessions.

    Args:
        skip: Number of sessions to skip
        limit: Maximum number of sessions to return
        db: Database session

    Returns:
        List of sessions
    """
    try:
        sessions = session_repository.get_all(db, skip=skip, limit=limit)
        return sessions
    except Exception as e:
        logger.error(f"Error listing sessions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post("", response_model=SessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(session_data: SessionCreate, db: Session = Depends(get_db)):
    """
    Create a new session.

    Args:
        session_data: Session creation data
        db: Database session

    Returns:
        Created session
    """
    try:
        # Generate session ID
        session_id = str(uuid.uuid4())

        # Create session in database
        session_dict = {
            "id": session_id,
            "title": session_data.title,
            "path": session_data.path,
        }

        session = session_repository.create(db, session_dict)

        # Initialize conversation
        conversation_service.create_conversation(
            session_id=session_id,
            model=ConfigService.get_default_model(),
            provider=ConfigService.get_default_provider(),
        )

        return session

    except Exception as e:
        logger.error(f"Error creating session: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get("/{session_id}", response_model=SessionResponse)
async def get_session(session_id: str, db: Session = Depends(get_db)):
    """
    Get session by ID.

    Args:
        session_id: Session ID
        db: Database session

    Returns:
        Session data
    """
    session = session_repository.get(db, session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
        )

    return session


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(session_id: str, db: Session = Depends(get_db)):
    """
    Delete a session.

    Args:
        session_id: Session ID
        db: Database session

    Returns:
        No content on success
    """
    session = session_repository.delete(db, session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
        )

    # Clean up conversation
    conversation_service.delete_conversation(session_id)

    return None


@router.post("/{session_id}/prompt", response_model=PromptResponse)
async def send_prompt(
    session_id: str, prompt_data: PromptRequest, db: Session = Depends(get_db)
):
    """
    Send a prompt to a session (non-streaming).

    For streaming responses, use the /events endpoint with SSE.

    Args:
        session_id: Session ID
        prompt_data: Prompt data
        db: Database session

    Returns:
        Prompt response
    """
    session = session_repository.get(db, session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
        )

    try:
        # Get workspace path
        workspace_path = Path(session.path) if session.path else Path.cwd()

        # Create streaming handler
        handler = create_streaming_handler(
            session_id=session_id,
            workspace_path=workspace_path,
            model=prompt_data.model,
        )

        # Process prompt (collect all events)
        last_message = None
        async for event in handler.process_prompt(prompt_data.prompt):
            if event.type == "message" and event.data.get("role") == "assistant":
                last_message = event.data.get("content", "")
            elif event.type == "error":
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=event.data.get("error", "Unknown error"),
                )

        # Broadcast event
        await event_service.broadcast(
            {
                "type": EventType.MESSAGE,
                "session_id": session_id,
                "data": {
                    "role": "user",
                    "content": prompt_data.prompt,
                },
            }
        )

        return {
            "session_id": session_id,
            "message": "Prompt processed successfully",
            "status": "success",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error sending prompt: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post("/{session_id}/prompt/stream")
async def send_prompt_stream(
    session_id: str, prompt_data: PromptRequest, db: Session = Depends(get_db)
):
    """
    Send a prompt to a session with streaming response.

    Args:
        session_id: Session ID
        prompt_data: Prompt data
        db: Database session

    Returns:
        SSE stream of events
    """
    session = session_repository.get(db, session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
        )

    # Get workspace path
    workspace_path = Path(session.path) if session.path else Path.cwd()

    async def event_stream():
        """Generate SSE events."""
        try:
            handler = create_streaming_handler(
                session_id=session_id,
                workspace_path=workspace_path,
                model=prompt_data.model,
            )

            async for event in handler.process_prompt(prompt_data.prompt):
                yield event.to_sse()

        except asyncio.CancelledError:
            logger.info(f"Stream cancelled for session {session_id}")
        except Exception as e:
            logger.error(f"Error in stream: {e}")
            error_event = SSEEvent(
                type="error",
                session_id=session_id,
                data={"error": str(e)},
            )
            yield error_event.to_sse()

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/{session_id}/events")
async def get_session_events(session_id: str, db: Session = Depends(get_db)):
    """
    SSE endpoint for real-time session events.

    This endpoint provides a persistent connection for receiving
    session events (messages, tool calls, etc.).

    Args:
        session_id: Session ID

    Returns:
        SSE stream of events
    """
    session = session_repository.get(db, session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
        )

    # Generate unique listener ID for this client connection
    listener_id = f"session_{session_id}_{uuid.uuid4().hex[:8]}"

    async def event_stream():
        """Generate SSE events."""
        try:
            async for event in event_service.event_generator(listener_id, timeout=30):
                # Only send events for this session
                if "session_id" in event and event["session_id"] != session_id:
                    continue

                yield f"data: {json.dumps(event)}\n\n"

        except asyncio.CancelledError:
            logger.info(f"Event stream cancelled for session {session_id}")
        except Exception as e:
            logger.error(f"Error in event stream: {e}")

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        },
    )


@router.get("/{session_id}/messages")
async def get_session_messages(session_id: str, db: Session = Depends(get_db)):
    """
    Get all messages for a session.

    Args:
        session_id: Session ID

    Returns:
        List of messages
    """
    session = session_repository.get(db, session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
        )

    # Get conversation
    conversation = conversation_service.get_conversation(session_id)
    if not conversation:
        return []

    return [msg.to_dict() for msg in conversation.messages]


@router.get("/{session_id}/todos")
async def get_session_todos(session_id: str, db: Session = Depends(get_db)):
    """
    Get todos for a session.

    Note: Todo tracking is managed through conversation context.

    Args:
        session_id: Session ID

    Returns:
        Todo data
    """
    session = session_repository.get(db, session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
        )

    # Get conversation metadata for todos
    conversation = conversation_service.get_conversation(session_id)
    if not conversation:
        return {"todos": []}

    return {"todos": conversation.metadata.get("todos", [])}


@router.get("/{session_id}/export/json")
async def export_session_json(
    session_id: str,
    pretty: bool = Query(True, description="Format with indentation"),
    db: Session = Depends(get_db),
):
    """
    Export session as JSON.

    Args:
        session_id: Session ID
        pretty: Whether to format JSON with indentation
        db: Database session

    Returns:
        JSON export of the session
    """
    session = session_repository.get(db, session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
        )

    try:
        # Get conversation data
        conversation = conversation_service.get_conversation(session_id)

        session_data = {
            "id": session.id,
            "title": session.title,
            "path": session.path,
            "created_at": session.created_at.isoformat() if session.created_at else None,
            "updated_at": session.updated_at.isoformat() if session.updated_at else None,
            "messages": [],
            "todos": [],
            "artifacts": [],
            "tags": [],
        }

        if conversation:
            session_data["messages"] = [msg.to_dict() for msg in conversation.messages]
            session_data["todos"] = conversation.metadata.get("todos", [])
            session_data["model"] = conversation.model
            session_data["provider"] = conversation.provider
            session_data["total_tokens"] = {
                "input": conversation.total_input_tokens,
                "output": conversation.total_output_tokens,
            }

        json_content = SessionExportService.to_json(session_data, pretty=pretty)
        filename = SessionExportService.get_export_filename(session_data, "json")

        return JSONResponse(
            content=json.loads(json_content),
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
                "X-Export-Filename": filename,
            },
        )

    except Exception as e:
        logger.error(f"Error exporting session as JSON: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get("/{session_id}/export/markdown")
async def export_session_markdown(
    session_id: str,
    include_todos: bool = Query(True, description="Include todos section"),
    include_artifacts: bool = Query(True, description="Include artifacts section"),
    db: Session = Depends(get_db),
):
    """
    Export session as Markdown.

    Args:
        session_id: Session ID
        include_todos: Whether to include todos section
        include_artifacts: Whether to include artifacts section
        db: Database session

    Returns:
        Markdown export of the session
    """
    session = session_repository.get(db, session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Session not found"
        )

    try:
        # Get conversation data
        conversation = conversation_service.get_conversation(session_id)

        session_data = {
            "id": session.id,
            "title": session.title,
            "path": session.path,
            "created_at": session.created_at.isoformat() if session.created_at else None,
            "updated_at": session.updated_at.isoformat() if session.updated_at else None,
            "messages": [],
            "todos": [],
            "artifacts": [],
            "tags": [],
        }

        if conversation:
            # Convert messages for markdown export
            messages = []
            for msg in conversation.messages:
                messages.append({
                    "role": msg.role.value,
                    "content": msg.content,
                })
            session_data["messages"] = messages
            session_data["todos"] = conversation.metadata.get("todos", [])

        markdown_content = SessionExportService.to_markdown(
            session_data,
            include_todos=include_todos,
            include_artifacts=include_artifacts,
        )
        filename = SessionExportService.get_export_filename(session_data, "markdown")

        return PlainTextResponse(
            content=markdown_content,
            media_type="text/markdown",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
                "X-Export-Filename": filename,
            },
        )

    except Exception as e:
        logger.error(f"Error exporting session as Markdown: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )
