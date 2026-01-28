from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
import subprocess
import shutil
import platform
import logging

from app.services.file_service import FileService
from app.schemas import SkillResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/skills", tags=["skills"])


@router.get("", response_model=List[SkillResponse])
async def list_skills():
    """
    List all installed skills from .opencode/skills directory.

    Returns:
        List of skills with metadata
    """
    try:
        skills_data = FileService.list_skills_directory()

        # Convert to SkillResponse format
        skills = []
        for skill_data in skills_data:
            skill = SkillResponse(
                id=skill_data["name"],
                name=skill_data["name"],
                description=skill_data.get("description", ""),
                version=skill_data.get("version"),
                created_at=datetime.now(),
                updated_at=datetime.now(),
            )
            skills.append(skill)

        return skills
    except Exception as e:
        logger.error(f"Error listing skills: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post("/install")
async def install_skill(skill_name: str):
    """
    Install a skill from OpenPackage registry using opkg.

    Args:
        skill_name: Name of the skill to install

    Returns:
        Success message

    Raises:
        HTTPException: If installation fails
    """
    try:
        # Run opkg install command
        result = subprocess.run(
            ["opkg", "install", skill_name], capture_output=True, text=True, timeout=60
        )

        if result.returncode != 0:
            error_msg = result.stderr or result.stdout or "Unknown error"
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to install skill: {error_msg}",
            )

        return {"message": f"Skill '{skill_name}' installed successfully"}
    except subprocess.TimeoutExpired:
        raise HTTPException(
            status_code=status.HTTP_408_REQUEST_TIMEOUT,
            detail="Installation timeout - operation took too long",
        )
    except FileNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="opkg command not found. Please install OpenCode CLI.",
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error installing skill: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


class ImportSkillRequest(BaseModel):
    source_path: str
    skill_name: Optional[str] = None


@router.post("/import")
async def import_skill(request: ImportSkillRequest):
    """
    Import a skill from a local folder.

    Args:
        request: Import request with source path and optional skill name

    Returns:
        Success message

    Raises:
        HTTPException: If import fails
    """
    try:
        from pydantic import BaseModel

        source_path = request.source_path
        skill_name = request.skill_name

        source = FileService.resolve_path(source_path)
        if not source.exists() or not source.is_dir():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Source directory not found: {source_path}",
            )

        # Use directory name if skill_name not provided
        if not skill_name:
            skill_name = source.name

        # Check if SKILL.md exists
        skill_md = source / "SKILL.md"
        if not skill_md.exists():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"SKILL.md not found in source directory",
            )

        # Copy to .opencode/skills
        skills_path = FileService.get_opencode_skills_path()
        skills_path.mkdir(parents=True, exist_ok=True)
        dest_path = skills_path / skill_name

        if dest_path.exists():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Skill '{skill_name}' already exists",
            )

        shutil.copytree(source, dest_path)

        return {"message": f"Skill '{skill_name}' imported successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error importing skill: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.delete("/{skill_name}", status_code=status.HTTP_204_NO_CONTENT)
async def uninstall_skill(skill_name: str):
    """
    Uninstall/delete a skill.

    Args:
        skill_name: Name of the skill to uninstall

    Returns:
        No content on success

    Raises:
        HTTPException: If uninstall fails
    """
    try:
        FileService.delete_skill_folder(skill_name)
        return None
    except FileNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Skill '{skill_name}' not found",
        )
    except Exception as e:
        logger.error(f"Error uninstalling skill: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get("/reveal")
async def reveal_skills_folder():
    """
    Open the .opencode/skills folder in the system file explorer.

    Returns:
        Success message

    Raises:
        HTTPException: If operation fails
    """
    try:
        skills_path = FileService.get_opencode_skills_path()

        # Create directory if it doesn't exist
        skills_path.mkdir(parents=True, exist_ok=True)

        # Open in file explorer based on OS
        system = platform.system()
        if system == "Darwin":  # macOS
            subprocess.run(["open", str(skills_path)], check=True)
        elif system == "Windows":
            subprocess.run(["explorer", str(skills_path)], check=True)
        else:  # Linux
            subprocess.run(["xdg-open", str(skills_path)], check=True)

        return {"message": "Skills folder opened"}
    except subprocess.CalledProcessError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to open folder: {e}",
        )
    except Exception as e:
        logger.error(f"Error revealing skills folder: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get("/{skill_name}")
async def get_skill(skill_name: str):
    """
    Get a specific skill by name.

    Args:
        skill_name: Name of the skill

    Returns:
        Skill details

    Raises:
        HTTPException: If skill not found
    """
    try:
        skill_data = FileService.get_skill_metadata(skill_name)

        return SkillResponse(
            id=skill_data["name"],
            name=skill_data["name"],
            description=skill_data.get("description", ""),
            version=skill_data.get("version"),
            created_at=datetime.now(),
            updated_at=datetime.now(),
        )
    except FileNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Skill '{skill_name}' not found",
        )
    except Exception as e:
        logger.error(f"Error getting skill: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )
