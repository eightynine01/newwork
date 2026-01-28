from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import uuid

from app.db.database import get_db
from app.db.repositories import workspace_repository
from app.schemas import (
    WorkspaceCreate,
    WorkspaceUpdate,
    WorkspaceResponse,
    WorkspaceAuthorizeRequest,
    WorkspaceAuthorizeResponse,
)
from app.services.file_service import FileService
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/workspaces", tags=["workspaces"])


@router.get("", response_model=List[WorkspaceResponse])
async def list_workspaces(
    skip: int = 0, limit: int = 100, db: Session = Depends(get_db)
):
    """
    List all workspaces.

    Args:
        skip: Number of workspaces to skip
        limit: Maximum number of workspaces to return
        db: Database session

    Returns:
        List of workspaces
    """
    try:
        workspaces = workspace_repository.get_all(db, skip=skip, limit=limit)
        return workspaces
    except Exception as e:
        logger.error(f"Error listing workspaces: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post("", response_model=WorkspaceResponse, status_code=status.HTTP_201_CREATED)
async def create_workspace(
    workspace_data: WorkspaceCreate, db: Session = Depends(get_db)
):
    """
    Create a new workspace.

    Args:
        workspace_data: Workspace creation data
        db: Database session

    Returns:
        Created workspace
    """
    try:
        # Check if workspace with same path exists
        existing = workspace_repository.get_by_path(db, workspace_data.path)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Workspace with path '{workspace_data.path}' already exists",
            )

        # Check if path exists and is a directory
        if not FileService.directory_exists(workspace_data.path):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Path '{workspace_data.path}' is not a valid directory",
            )

        # Create workspace
        workspace_dict = {
            "id": str(uuid.uuid4()),
            "name": workspace_data.name,
            "path": workspace_data.path,
            "description": workspace_data.description,
            "is_active": False,  # Don't auto-activate new workspaces
        }

        workspace = workspace_repository.create(db, workspace_dict)
        return workspace

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating workspace: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get("/{workspace_id}", response_model=WorkspaceResponse)
async def get_workspace(workspace_id: str, db: Session = Depends(get_db)):
    """
    Get workspace by ID.

    Args:
        workspace_id: Workspace ID
        db: Database session

    Returns:
        Workspace data
    """
    workspace = workspace_repository.get(db, workspace_id)
    if not workspace:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Workspace not found"
        )

    return workspace


@router.delete("/{workspace_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_workspace(workspace_id: str, db: Session = Depends(get_db)):
    """
    Delete a workspace.

    Args:
        workspace_id: Workspace ID
        db: Database session

    Returns:
        No content on success
    """
    workspace = workspace_repository.delete(db, workspace_id)
    if not workspace:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Workspace not found"
        )

    return None


@router.put("/{workspace_id}", response_model=WorkspaceResponse)
async def update_workspace(
    workspace_id: str, workspace_data: WorkspaceUpdate, db: Session = Depends(get_db)
):
    """
    Update a workspace.

    Args:
        workspace_id: Workspace ID
        workspace_data: Workspace update data
        db: Database session

    Returns:
        Updated workspace
    """
    workspace = workspace_repository.get(db, workspace_id)
    if not workspace:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Workspace not found"
        )

    # Check if new path conflicts with existing workspace
    if workspace_data.path and workspace_data.path != workspace.path:
        existing = workspace_repository.get_by_path(db, workspace_data.path)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Workspace with path '{workspace_data.path}' already exists",
            )

    # Update workspace
    update_dict = workspace_data.model_dump(exclude_unset=True)
    workspace = workspace_repository.update(db, workspace, update_dict or {})
    return workspace


@router.post("/authorize", response_model=WorkspaceAuthorizeResponse)
async def authorize_workspace(
    auth_data: WorkspaceAuthorizeRequest, db: Session = Depends(get_db)
):
    """
    Authorize a directory as a workspace.

    Args:
        auth_data: Authorization data with path
        db: Database session

    Returns:
        Authorization response
    """
    try:
        # Check if path exists and is a directory
        if not FileService.directory_exists(auth_data.path):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Path '{auth_data.path}' is not a valid directory",
            )

        # Check if workspace already exists
        existing = workspace_repository.get_by_path(db, auth_data.path)
        if existing:
            # Set as active
            workspace_repository.set_active(db, existing.id)
            return {
                "workspace_id": existing.id,
                "authorized": True,
                "message": f"Workspace '{existing.name}' authorized and set as active",
            }

        # Create new workspace
        workspace_dict = {
            "id": str(uuid.uuid4()),
            "name": FileService.resolve_path(auth_data.path).name,
            "path": auth_data.path,
            "description": f"Workspace for {auth_data.path}",
            "is_active": True,
        }

        workspace = workspace_repository.create(db, workspace_dict)

        return {
            "workspace_id": workspace.id,
            "authorized": True,
            "message": f"Workspace '{workspace.name}' created and authorized",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error authorizing workspace: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get("/active", response_model=WorkspaceResponse)
async def get_active_workspace(db: Session = Depends(get_db)):
    """
    Get the active workspace.

    Args:
        db: Database session

    Returns:
        Active workspace data
    """
    workspace = workspace_repository.get_active(db)
    if not workspace:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="No active workspace found"
        )

    return workspace
