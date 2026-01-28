from fastapi import APIRouter, Depends, HTTPException, status, Query
from fastapi.responses import FileResponse, StreamingResponse
from sqlalchemy.orm import Session
from typing import Optional
from pathlib import Path
import logging
import urllib.parse

from app.db.database import get_db
from app.db.repositories import workspace_repository
from app.schemas import (
    FileListResponse,
    FileContentResponse,
    FileCreateRequest,
    FileUpdateRequest,
    FileOperationResponse,
    FileInfo,
)
from app.services.file_service import FileService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/files", tags=["files"])


def validate_workspace_path(workspace_id: str, file_path: str, db: Session) -> Path:
    """
    Validate that a file path is within the workspace directory.

    Args:
        workspace_id: Workspace ID
        file_path: Relative file path
        db: Database session

    Returns:
        Resolved absolute Path object

    Raises:
        HTTPException: If workspace not found or path is invalid
    """
    # Get workspace
    workspace = workspace_repository.get(db, workspace_id)
    if not workspace:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Workspace not found: {workspace_id}"
        )

    # Resolve workspace path
    workspace_path = FileService.resolve_path(workspace.path)
    if not workspace_path.is_dir():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Workspace path is not a directory: {workspace.path}"
        )

    # Resolve target file path
    target_path = (workspace_path / file_path).resolve()

    # Security: Ensure target path is within workspace
    try:
        target_path.relative_to(workspace_path)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access denied: path outside workspace: {file_path}"
        )

    return target_path


@router.get("", response_model=FileListResponse)
async def list_files(
    workspace_id: str = Query(..., description="Workspace ID"),
    path: str = Query(".", description="Directory path relative to workspace"),
    recursive: bool = Query(False, description="List recursively"),
    db: Session = Depends(get_db)
):
    """
    List files in a workspace directory.

    Args:
        workspace_id: Workspace ID
        path: Directory path (relative to workspace root)
        recursive: Whether to list recursively
        db: Database session

    Returns:
        List of files with metadata
    """
    try:
        # Validate and resolve path
        target_path = validate_workspace_path(workspace_id, path, db)

        if not target_path.is_dir():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Path is not a directory: {path}"
            )

        # List directory
        files_data = FileService.list_directory(str(target_path), recursive=recursive)

        # Convert to FileInfo objects
        files = [
            FileInfo(
                path=f["path"],
                name=f["name"],
                type=f["type"],
                size=f.get("size"),
                is_file=f["type"] == "file",
                is_dir=f["type"] == "directory"
            )
            for f in files_data
        ]

        return FileListResponse(
            workspace_id=workspace_id,
            path=path,
            files=files,
            total=len(files)
        )

    except HTTPException:
        raise
    except FileNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error listing files: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/download")
async def download_file(
    workspace_id: str = Query(..., description="Workspace ID"),
    path: str = Query(..., description="File path relative to workspace"),
    db: Session = Depends(get_db)
):
    """
    Download a file as binary stream.

    Args:
        workspace_id: Workspace ID
        path: File path (relative to workspace root)
        db: Database session

    Returns:
        File as streaming binary response with appropriate content type
    """
    try:
        # Validate and resolve path
        target_path = validate_workspace_path(workspace_id, path, db)

        if not target_path.is_file():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"File not found: {path}"
            )

        # Get file info
        file_name = target_path.name
        mime_type = FileService.get_mime_type(str(target_path))
        file_size = target_path.stat().st_size

        # Encode filename for Content-Disposition header (RFC 5987)
        encoded_filename = urllib.parse.quote(file_name)

        return FileResponse(
            path=str(target_path),
            media_type=mime_type,
            filename=file_name,
            headers={
                "Content-Disposition": f"attachment; filename*=UTF-8''{encoded_filename}",
                "Content-Length": str(file_size),
                "X-File-Name": file_name,
                "X-File-Size": str(file_size),
                "X-Mime-Type": mime_type,
            }
        )

    except HTTPException:
        raise
    except FileNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"File not found: {path}"
        )
    except Exception as e:
        logger.error(f"Error downloading file: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.get("/content", response_model=FileContentResponse)
async def get_file_content(
    workspace_id: str = Query(..., description="Workspace ID"),
    path: str = Query(..., description="File path relative to workspace"),
    db: Session = Depends(get_db)
):
    """
    Read file content.

    Args:
        workspace_id: Workspace ID
        path: File path (relative to workspace root)
        db: Database session

    Returns:
        File content and metadata
    """
    try:
        # Validate and resolve path
        target_path = validate_workspace_path(workspace_id, path, db)

        if not target_path.is_file():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Path is not a file: {path}"
            )

        # Read file
        content = FileService.read_file(str(target_path))
        stat = target_path.stat()

        return FileContentResponse(
            path=path,
            name=target_path.name,
            content=content,
            size=stat.st_size,
            modified=stat.st_mtime
        )

    except HTTPException:
        raise
    except FileNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"File not found: {path}"
        )
    except UnicodeDecodeError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File is not a text file: {path}"
        )
    except Exception as e:
        logger.error(f"Error reading file: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.post("", response_model=FileOperationResponse, status_code=status.HTTP_201_CREATED)
async def create_file(
    workspace_id: str = Query(..., description="Workspace ID"),
    file_data: FileCreateRequest = ...,
    db: Session = Depends(get_db)
):
    """
    Create a new file.

    Args:
        workspace_id: Workspace ID
        file_data: File creation data
        db: Database session

    Returns:
        Operation result
    """
    try:
        # Validate and resolve path
        target_path = validate_workspace_path(workspace_id, file_data.path, db)

        # Check if file already exists
        if target_path.exists():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"File already exists: {file_data.path}"
            )

        # Create parent directories if needed
        target_path.parent.mkdir(parents=True, exist_ok=True)

        # Write file
        FileService.write_file(str(target_path), file_data.content)

        return FileOperationResponse(
            success=True,
            message=f"File created: {file_data.path}",
            path=file_data.path
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating file: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.put("", response_model=FileOperationResponse)
async def update_file(
    workspace_id: str = Query(..., description="Workspace ID"),
    path: str = Query(..., description="File path relative to workspace"),
    file_data: FileUpdateRequest = ...,
    db: Session = Depends(get_db)
):
    """
    Update file content.

    Args:
        workspace_id: Workspace ID
        path: File path (relative to workspace root)
        file_data: File update data
        db: Database session

    Returns:
        Operation result
    """
    try:
        # Validate and resolve path
        target_path = validate_workspace_path(workspace_id, path, db)

        if not target_path.is_file():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"File not found: {path}"
            )

        # Write file
        FileService.write_file(str(target_path), file_data.content)

        return FileOperationResponse(
            success=True,
            message=f"File updated: {path}",
            path=path
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating file: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.delete("", response_model=FileOperationResponse)
async def delete_file(
    workspace_id: str = Query(..., description="Workspace ID"),
    path: str = Query(..., description="File path relative to workspace"),
    db: Session = Depends(get_db)
):
    """
    Delete a file.

    Args:
        workspace_id: Workspace ID
        path: File path (relative to workspace root)
        db: Database session

    Returns:
        Operation result
    """
    try:
        # Validate and resolve path
        target_path = validate_workspace_path(workspace_id, path, db)

        if not target_path.is_file():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"File not found: {path}"
            )

        # Delete file
        FileService.delete_file(str(target_path))

        return FileOperationResponse(
            success=True,
            message=f"File deleted: {path}",
            path=path
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting file: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
