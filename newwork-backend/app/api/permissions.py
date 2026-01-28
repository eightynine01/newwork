"""
Permission API endpoints.

This module provides endpoints for managing tool execution permissions.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from app.db.database import get_db
from app.db.repositories import permission_repository
from app.schemas import (
    PermissionResponse,
    PermissionRespondRequest,
    PermissionRespondResponse,
)
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/permissions", tags=["permissions"])


@router.get("/pending", response_model=List[PermissionResponse])
async def get_pending_permissions(db: Session = Depends(get_db)):
    """
    Get all pending permission requests.

    Args:
        db: Database session

    Returns:
        List of pending permissions
    """
    try:
        permissions = permission_repository.get_pending(db)
        return permissions

    except Exception as e:
        logger.error(f"Error getting pending permissions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post("/{permission_id}/respond", response_model=PermissionRespondResponse)
async def respond_permission(
    permission_id: str,
    respond_data: PermissionRespondRequest,
    db: Session = Depends(get_db),
):
    """
    Respond to a permission request.

    Args:
        permission_id: Permission ID
        respond_data: Response data
        db: Database session

    Returns:
        Response confirmation
    """
    permission = permission_repository.get(db, permission_id)
    if not permission:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Permission not found"
        )

    # Validate response
    valid_responses = ["allow_once", "allow_always", "deny"]
    if respond_data.reply not in valid_responses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid response. Must be one of: {valid_responses}",
        )

    try:
        # Update permission in database
        status_map = {
            "allow_once": "approved",
            "allow_always": "approved",
            "deny": "denied",
        }

        permission.status = status_map.get(respond_data.reply, "denied")
        permission.response = respond_data.reply
        permission.updated_at = datetime.utcnow()

        db.commit()
        db.refresh(permission)

        return {
            "permission_id": permission_id,
            "status": permission.status,
            "message": f"Permission {respond_data.reply} successfully",
        }

    except Exception as e:
        logger.error(f"Error responding to permission: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get("/history", response_model=List[PermissionResponse])
async def get_permission_history(
    skip: int = 0, limit: int = 100, db: Session = Depends(get_db)
):
    """
    Get permission history (non-pending permissions).

    Args:
        skip: Number of permissions to skip
        limit: Maximum number of permissions to return
        db: Database session

    Returns:
        List of historical permissions
    """
    try:
        permissions = permission_repository.get_history(db, skip=skip, limit=limit)
        return permissions

    except Exception as e:
        logger.error(f"Error getting permission history: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get("/session/{session_id}", response_model=List[PermissionResponse])
async def get_session_permissions(session_id: str, db: Session = Depends(get_db)):
    """
    Get permissions for a specific session.

    Args:
        session_id: Session ID
        db: Database session

    Returns:
        List of permissions for the session
    """
    try:
        permissions = permission_repository.get_by_session_id(db, session_id)
        return permissions

    except Exception as e:
        logger.error(f"Error getting session permissions: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )
