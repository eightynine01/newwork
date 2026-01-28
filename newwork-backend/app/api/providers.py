"""
AI Provider API endpoints.

This module provides endpoints for listing available AI providers and models.
"""

from fastapi import APIRouter, HTTPException, status, Query
from typing import List, Optional
from pydantic import BaseModel
import logging

from app.schemas import ProviderInfo, ModelInfo, ModelCapabilities
from app.services.config_service import ConfigService, settings
from app.services.llm import get_provider, get_available_providers

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/providers", tags=["providers"])


class SetDefaultModelRequest(BaseModel):
    """Request schema for setting default model."""

    model_id: str
    provider_id: Optional[str] = None


# Static provider definitions
PROVIDER_DEFINITIONS = {
    "anthropic": {
        "id": "anthropic",
        "name": "Anthropic",
        "description": "Claude AI models from Anthropic",
        "icon_url": "/icons/anthropic.svg",
    },
    "openai": {
        "id": "openai",
        "name": "OpenAI",
        "description": "GPT models from OpenAI",
        "icon_url": "/icons/openai.svg",
    },
    "deepseek": {
        "id": "deepseek",
        "name": "DeepSeek",
        "description": "DeepSeek AI models",
        "icon_url": "/icons/deepseek.svg",
    },
    "minimax": {
        "id": "minimax",
        "name": "Minimax",
        "description": "Minimax AI models",
        "icon_url": "/icons/minimax.svg",
    },
    "zai": {
        "id": "zai",
        "name": "ZAI",
        "description": "ZAI AI models",
        "icon_url": "/icons/zai.svg",
    },
}


@router.get("", response_model=List[ProviderInfo])
async def list_providers():
    """
    List available AI providers.

    Returns providers that have API keys configured.
    """
    try:
        available = ConfigService.get_available_providers()
        providers = []

        for provider_name in available:
            provider_def = PROVIDER_DEFINITIONS.get(provider_name)
            if not provider_def:
                continue

            # Get models for this provider
            models = []
            try:
                api_key = ConfigService.get_api_key(provider_name)
                if api_key:
                    provider = get_provider(provider_name, api_key)
                    model_infos = provider.get_available_models()
                    for m in model_infos:
                        models.append(
                            ModelInfo(
                                id=m.id,
                                name=m.name,
                                provider=m.provider,
                                provider_id=provider_name,
                                provider_name=provider_def["name"],
                                description=m.description,
                                capabilities=ModelCapabilities(
                                    tools=m.supports_tools,
                                    vision=m.supports_vision,
                                ),
                                is_default=(
                                    m.id == settings.DEFAULT_MODEL
                                    and provider_name == settings.DEFAULT_PROVIDER
                                ),
                            )
                        )
            except Exception as e:
                logger.warning(f"Error getting models for {provider_name}: {e}")

            providers.append(
                ProviderInfo(
                    id=provider_def["id"],
                    name=provider_def["name"],
                    description=provider_def.get("description"),
                    icon_url=provider_def.get("icon_url"),
                    is_available=True,
                    models=models,
                )
            )

        return providers

    except Exception as e:
        logger.error(f"Error listing providers: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )


@router.get("/models", response_model=List[ModelInfo])
async def list_models(
    provider: Optional[str] = Query(None, description="Filter by provider"),
):
    """
    List available AI models.

    Args:
        provider: Optional provider to filter by
    """
    try:
        models = []
        available_providers = ConfigService.get_available_providers()

        # Filter by specific provider if requested
        if provider:
            if provider not in available_providers:
                return []
            available_providers = [provider]

        for provider_name in available_providers:
            try:
                api_key = ConfigService.get_api_key(provider_name)
                if not api_key:
                    continue

                provider_instance = get_provider(provider_name, api_key)
                model_infos = provider_instance.get_available_models()
                provider_def = PROVIDER_DEFINITIONS.get(provider_name, {})

                for m in model_infos:
                    models.append(
                        ModelInfo(
                            id=m.id,
                            name=m.name,
                            provider=m.provider,
                            provider_id=provider_name,
                            provider_name=provider_def.get("name", provider_name),
                            description=m.description,
                            capabilities=ModelCapabilities(
                                tools=m.supports_tools,
                                vision=m.supports_vision,
                            ),
                            is_default=(
                                m.id == settings.DEFAULT_MODEL
                                and provider_name == settings.DEFAULT_PROVIDER
                            ),
                        )
                    )
            except Exception as e:
                logger.warning(f"Error getting models for {provider_name}: {e}")
                continue

        return models

    except Exception as e:
        logger.error(f"Error listing models: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )


@router.get("/health")
async def check_providers_health():
    """
    Check health of provider connections.

    Tests connectivity to each configured provider.
    """
    try:
        available = ConfigService.get_available_providers()
        provider_status = {}

        for provider_name in available:
            try:
                api_key = ConfigService.get_api_key(provider_name)
                if api_key:
                    # Just verify we can create the provider
                    get_provider(provider_name, api_key)
                    provider_status[provider_name] = "available"
                else:
                    provider_status[provider_name] = "no_api_key"
            except Exception as e:
                provider_status[provider_name] = f"error: {str(e)}"

        is_healthy = any(
            status == "available" for status in provider_status.values()
        )

        return {
            "status": "healthy" if is_healthy else "unhealthy",
            "providers": provider_status,
            "default_provider": settings.DEFAULT_PROVIDER,
            "default_model": settings.DEFAULT_MODEL,
        }

    except Exception as e:
        logger.error(f"Error checking providers health: {e}")
        return {
            "status": "unhealthy",
            "error": str(e),
        }


@router.get("/default", response_model=dict)
async def get_default_model():
    """
    Get the default model configuration.
    """
    try:
        provider_name = settings.DEFAULT_PROVIDER
        model_id = settings.DEFAULT_MODEL
        provider_def = PROVIDER_DEFINITIONS.get(provider_name, {})

        # Try to get model details
        model_name = model_id
        try:
            api_key = ConfigService.get_api_key(provider_name)
            if api_key:
                provider = get_provider(provider_name, api_key)
                for m in provider.get_available_models():
                    if m.id == model_id:
                        model_name = m.name
                        break
        except Exception:
            pass

        return {
            "model_id": model_id,
            "model_name": model_name,
            "provider_id": provider_name,
            "provider_name": provider_def.get("name", provider_name),
        }
    except Exception as e:
        logger.error(f"Error getting default model: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )


@router.post("/default")
async def set_default_model(request: SetDefaultModelRequest):
    """
    Set the default model.

    Note: This currently only logs the request. To persist settings,
    implement storage in config file or database.
    """
    try:
        logger.info(f"Setting default model to: {request.model_id}")

        # TODO: Persist to config file or database
        # For now, just return success
        return {
            "success": True,
            "message": f"Default model set to {request.model_id}",
            "note": "This setting is not persisted. Set DEFAULT_MODEL in .env for persistence.",
        }
    except Exception as e:
        logger.error(f"Error setting default model: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )
