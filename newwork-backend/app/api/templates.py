from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid

from app.db.database import get_db
from app.db.repositories import template_repository
from app.schemas import (
    TemplateCreate,
    TemplateUpdate,
    TemplateResponse,
    TemplateRunRequest,
    TemplateRunResponse,
)
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/templates", tags=["templates"])


@router.get("", response_model=List[TemplateResponse])
async def list_templates(
    skip: int = 0,
    limit: int = 100,
    scope: Optional[str] = Query(
        None, description="Filter by scope: 'workspace' or 'global'"
    ),
    db: Session = Depends(get_db),
):
    """
    List all templates.

    Args:
        skip: Number of templates to skip
        limit: Maximum number of templates to return
        scope: Filter by scope ('workspace' or 'global')
        db: Database session

    Returns:
        List of templates
    """
    try:
        templates = template_repository.get_all(db, skip=skip, limit=limit)
        if scope:
            templates = [t for t in templates if t.scope == scope]
        return templates
    except Exception as e:
        logger.error(f"Error listing templates: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post("", response_model=TemplateResponse, status_code=status.HTTP_201_CREATED)
async def create_template(template_data: TemplateCreate, db: Session = Depends(get_db)):
    """
    Create a new template.

    Args:
        template_data: Template creation data
        db: Database session

    Returns:
        Created template
    """
    try:
        # Check if template with same name exists
        existing = template_repository.get_by_name(db, template_data.name)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Template with name '{template_data.name}' already exists",
            )

        # Create template
        template_dict = {
            "id": str(uuid.uuid4()),
            "name": template_data.name,
            "description": template_data.description,
            "content": template_data.content,
            "scope": template_data.scope or "workspace",
            "skills": template_data.skills or [],
            "parameters": template_data.parameters,
            "is_public": template_data.scope == "global",
        }

        template = template_repository.create(db, template_dict)
        return template

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating template: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get("/{template_id}", response_model=TemplateResponse)
async def get_template(template_id: str, db: Session = Depends(get_db)):
    """
    Get template by ID.

    Args:
        template_id: Template ID
        db: Database session

    Returns:
        Template data
    """
    template = template_repository.get(db, template_id)
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Template not found"
        )

    return template


@router.delete("/{template_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_template(template_id: str, db: Session = Depends(get_db)):
    """
    Delete a template.

    Args:
        template_id: Template ID
        db: Database session

    Returns:
        No content on success
    """
    template = template_repository.delete(db, template_id)
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Template not found"
        )

    return None


@router.put("/{template_id}", response_model=TemplateResponse)
async def update_template(
    template_id: str, template_data: TemplateUpdate, db: Session = Depends(get_db)
):
    """
    Update a template.

    Args:
        template_id: Template ID
        template_data: Template update data
        db: Database session

    Returns:
        Updated template
    """
    template = template_repository.get(db, template_id)
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Template not found"
        )

    # Check if new name conflicts with existing template
    if template_data.name and template_data.name != template.name:
        existing = template_repository.get_by_name(db, template_data.name)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Template with name '{template_data.name}' already exists",
            )

    # Update template
    update_dict = template_data.model_dump(exclude_unset=True)
    template = template_repository.update(db, template, update_dict or {})
    return template


@router.post("/{template_id}/run", response_model=TemplateRunResponse)
async def run_template(
    template_id: str, run_data: TemplateRunRequest, db: Session = Depends(get_db)
):
    """
    Run a template with variable substitution.

    Args:
        template_id: Template ID
        run_data: Template run data with variables
        db: Database session

    Returns:
        Generated prompt
    """
    template = template_repository.get(db, template_id)
    if not template:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Template not found"
        )

    try:
        # Substitute variables in template content
        prompt = template.content
        if run_data.variables:
            for key, value in run_data.variables.items():
                prompt = prompt.replace(f"{{{key}}}", str(value))

        # Increment usage count
        template.usage_count = (template.usage_count or 0) + 1
        db.commit()

        return {
            "prompt": prompt,
            "status": "success",
            "template_id": template_id,
        }

    except Exception as e:
        logger.error(f"Error running template: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )
