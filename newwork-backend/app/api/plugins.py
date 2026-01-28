from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from pydantic import BaseModel
from ..services.config_service import ConfigService

router = APIRouter(prefix="/plugins", tags=["plugins"])


# Models
class PluginRequest(BaseModel):
    name: str
    scope: Optional[str] = "global"
    config: Optional[dict] = None


class PluginUpdateRequest(BaseModel):
    is_enabled: Optional[bool] = None
    config: Optional[dict] = None


# Endpoints


@router.get("")
async def get_plugins(
    scope: Optional[str] = Query(
        "global", description="Filter by scope: 'project' or 'global'"
    ),
    workspace_path: Optional[str] = Query(
        None, description="Workspace path for project scope"
    ),
):
    """
    Get all configured plugins.

    Args:
        scope: Filter by scope ('project' or 'global')
        workspace_path: Required for project scope

    Returns:
        List of plugins
    """
    try:
        if not scope:
            scope = "global"
        plugins = ConfigService.list_plugins(workspace_path, scope)
        return plugins
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("")
async def add_plugin(
    request: PluginRequest,
    workspace_path: Optional[str] = Query(
        None, description="Workspace path for project scope"
    ),
):
    """
    Add a new plugin to the configuration.

    Args:
        request: Plugin request containing name, scope, and config
        workspace_path: Required for project scope

    Returns:
        Created plugin details
    """
    try:
        scope = request.scope or "global"

        if scope not in ["project", "global"]:
            raise HTTPException(
                status_code=400, detail="Invalid scope. Must be 'project' or 'global'"
            )

        # Validate workspace_path for project scope
        if scope == "project" and not workspace_path:
            raise HTTPException(
                status_code=400, detail="workspace_path is required for project scope"
            )

        updated_config = ConfigService.add_plugin_to_config(
            plugin_name=request.name,
            workspace_path=workspace_path,
            config=request.config,
            scope=scope,
        )

        # Return the created plugin
        plugins = ConfigService.list_plugins(workspace_path, scope)
        created_plugin = [p for p in plugins if p["name"] == request.name]

        if created_plugin:
            return created_plugin[0]
        else:
            return {"name": request.name, "scope": scope, "is_enabled": True}

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/{plugin_name}")
async def remove_plugin(
    plugin_name: str,
    scope: Optional[str] = Query(
        "global", description="Filter by scope: 'project' or 'global'"
    ),
    workspace_path: Optional[str] = Query(
        None, description="Workspace path for project scope"
    ),
):
    """
    Remove a plugin from the configuration.

    Args:
        plugin_name: Name of the plugin to remove
        scope: Scope to remove from ('project' or 'global')
        workspace_path: Required for project scope

    Returns:
        Success message
    """
    try:
        actual_scope = scope or "global"
        ConfigService.remove_plugin_from_config(
            plugin_name, workspace_path, actual_scope
        )
        return {"message": f"Plugin '{plugin_name}' removed successfully"}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch("/{plugin_name}")
async def update_plugin(
    plugin_name: str,
    request: PluginUpdateRequest,
    scope: Optional[str] = Query(
        "global", description="Filter by scope: 'project' or 'global'"
    ),
    workspace_path: Optional[str] = Query(
        None, description="Workspace path for project scope"
    ),
):
    """
    Update a plugin's configuration.

    Args:
        plugin_name: Name of the plugin to update
        request: Update request with is_enabled or config
        scope: Scope of the plugin
        workspace_path: Required for project scope

    Returns:
        Updated plugin details
    """
    try:
        actual_scope = scope or "global"
        current_config = ConfigService.read_opencode_json(workspace_path, actual_scope)

        # Update is_enabled in mcp config
        if request.is_enabled is not None:
            if "mcp" not in current_config:
                current_config["mcp"] = {}
            if plugin_name not in current_config["mcp"]:
                current_config["mcp"][plugin_name] = {}
            current_config["mcp"][plugin_name]["enabled"] = request.is_enabled

        # Update config if provided
        if request.config is not None:
            if "mcp" not in current_config:
                current_config["mcp"] = {}
            current_config["mcp"][plugin_name] = request.config

        ConfigService.write_opencode_json(current_config, workspace_path, actual_scope)

        # Return updated plugin
        plugins = ConfigService.list_plugins(workspace_path, actual_scope)
        updated_plugin = [p for p in plugins if p["name"] == plugin_name]

        if updated_plugin:
            return updated_plugin[0]
        else:
            raise HTTPException(status_code=404, detail="Plugin not found")

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/scope")
async def get_config_path(
    scope: Optional[str] = Query(
        "global", description="Filter by scope: 'project' or 'global'"
    ),
    workspace_path: Optional[str] = Query(
        None, description="Workspace path for project scope"
    ),
):
    """
    Get the path to the opencode.json file.

    Args:
        scope: Scope to get path for ('project' or 'global')
        workspace_path: Required for project scope

    Returns:
        Path to the config file
    """
    try:
        actual_scope = scope or "global"
        path = ConfigService.get_config_file_path(workspace_path, actual_scope)
        return {"path": path, "scope": actual_scope}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/schema")
async def get_schema():
    """
    Get the plugin configuration schema.

    Returns:
        Schema definition
    """
    return ConfigService.get_plugin_schema()
