"""
MCP Server API endpoints.

Provides endpoints for managing Model Context Protocol (MCP) servers.
"""

from fastapi import APIRouter, HTTPException, Request
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from app.models.mcp_server import (
    MCPServerResponse,
    MCPServerCreate,
    MCPServerUpdate,
    MCPServer,
)
from app.models.mcp_protocol import (
    MCPTool,
    MCPHealthStatus,
    MCPConnectionState,
)
from app.services.config_service import ConfigService
from app.services.mcp_connection_service import get_mcp_manager
from app.services.oauth_service import get_oauth_service
import httpx
import logging
import urllib.parse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/mcp", tags=["mcp"])


# Response models for new endpoints
class MCPToolResponse(BaseModel):
    """Response model for MCP tools."""
    name: str
    description: Optional[str] = None
    input_schema: Dict[str, Any] = {}


class MCPToolsListResponse(BaseModel):
    """Response model for tools list."""
    server_name: str
    tools: List[MCPToolResponse]
    total: int


class MCPHealthResponse(BaseModel):
    """Response model for health check."""
    server_name: str
    is_healthy: bool
    state: str
    latency_ms: Optional[float] = None
    last_ping: Optional[str] = None
    error: Optional[str] = None


@router.get("/servers", response_model=List[MCPServerResponse])
async def list_mcp_servers(
    scope: str = "global",
    workspace_path: Optional[str] = None,
):
    """
    List all configured MCP servers.

    Args:
        scope: Either 'project' or 'global' (default: 'global')
        workspace_path: Required for project scope

    Returns:
        List of MCP servers
    """
    try:
        servers_data = ConfigService.list_mcp_servers(workspace_path, scope)
        return [MCPServerResponse(**server) for server in servers_data]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/servers", response_model=MCPServerResponse, status_code=201)
async def add_mcp_server(
    server_data: MCPServerCreate,
    scope: str = "global",
    workspace_path: Optional[str] = None,
):
    """
    Add a new MCP server.

    Args:
        server_data: Server configuration data
        scope: Either 'project' or 'global' (default: 'global')
        workspace_path: Required for project scope

    Returns:
        Created MCP server
    """
    try:
        # Determine endpoint based on server type
        endpoint = server_data.endpoint
        if server_data.server_type == "local":
            endpoint = server_data.endpoint  # For local servers, this is a path/command

        ConfigService.add_mcp_server(
            name=server_data.name,
            server_type=server_data.server_type,
            endpoint=endpoint,
            workspace_path=workspace_path,
            scope=scope,
            config=server_data.config,
            description=server_data.description,
        )

        # Get the created server
        servers = ConfigService.list_mcp_servers(workspace_path, scope)
        server = next((s for s in servers if s["id"] == server_data.name), None)

        if not server:
            raise HTTPException(
                status_code=500, detail="Failed to retrieve created server"
            )

        return MCPServerResponse(**server)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/servers/{server_name}", status_code=204)
async def remove_mcp_server(
    server_name: str,
    scope: str = "global",
    workspace_path: Optional[str] = None,
):
    """
    Remove an MCP server.

    Args:
        server_name: Name of server to remove
        scope: Either 'project' or 'global' (default: 'global')
        workspace_path: Required for project scope

    Returns:
        204 No Content on success
    """
    try:
        ConfigService.remove_mcp_server(server_name, workspace_path, scope)
    except KeyError:
        raise HTTPException(
            status_code=404, detail=f"MCP server '{server_name}' not found"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/servers/{server_name}", response_model=MCPServerResponse)
async def get_mcp_server(
    server_name: str,
    scope: str = "global",
    workspace_path: Optional[str] = None,
):
    """
    Get a specific MCP server configuration.

    Args:
        server_name: Name of server to retrieve
        scope: Either 'project' or 'global' (default: 'global')
        workspace_path: Required for project scope

    Returns:
        MCP server details
    """
    try:
        server_data = ConfigService.get_mcp_server(server_name, workspace_path, scope)
        return MCPServerResponse(**server_data)
    except KeyError:
        raise HTTPException(
            status_code=404, detail=f"MCP server '{server_name}' not found"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/servers/{server_name}/status", response_model=MCPServerResponse)
async def get_server_status(
    server_name: str,
    scope: str = "global",
    workspace_path: Optional[str] = None,
):
    """
    Get the status of an MCP server.

    Args:
        server_name: Name of server
        scope: Either 'project' or 'global' (default: 'global')
        workspace_path: Required for project scope

    Returns:
        MCP server with current status
    """
    try:
        server_data = ConfigService.get_mcp_server(server_name, workspace_path, scope)
        return MCPServerResponse(**server_data)
    except KeyError:
        raise HTTPException(
            status_code=404, detail=f"MCP server '{server_name}' not found"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/servers/{server_name}/connect", status_code=200)
async def connect_server(
    server_name: str,
    scope: str = "global",
    workspace_path: Optional[str] = None,
):
    """
    Connect to an MCP server.

    For OAuth-enabled servers, this returns an OAuth URL that the user must visit
    to authorize. For non-OAuth servers, this establishes a direct connection.

    Args:
        server_name: Name of server to connect to
        scope: Either 'project' or 'global' (default: 'global')
        workspace_path: Required for project scope

    Returns:
        Connection status or OAuth URL
    """
    try:
        # Get server configuration
        server_data = ConfigService.get_mcp_server(server_name, workspace_path, scope)

        # Update status to connecting
        ConfigService.update_mcp_server_status(
            name=server_name,
            status="connecting",
            workspace_path=workspace_path,
            scope=scope,
        )

        # Check if server requires OAuth
        config = server_data.get("config", {})
        requires_oauth = config.get("oauth_enabled", False)

        if requires_oauth:
            # Return OAuth URL for user to authorize
            oauth_url = config.get("oauth_url", "")
            if not oauth_url:
                raise HTTPException(
                    status_code=400,
                    detail="OAuth enabled but no OAuth URL configured",
                )

            return {
                "status": "oauth_required",
                "oauth_url": oauth_url,
                "message": "Visit the OAuth URL to authorize the connection",
            }

        # For non-OAuth servers, establish actual MCP connection
        mcp_manager = get_mcp_manager()

        # Prepare connection config based on server type
        server_type = server_data.get("server_type", "local")
        endpoint = server_data.get("endpoint", "")

        connection_config = {
            "server_type": server_type,
            **config,  # Include any additional config
        }

        if server_type == "local":
            # For local servers, endpoint is the command
            connection_config["command"] = endpoint
            connection_config["args"] = config.get("args", [])
            connection_config["env"] = config.get("env", {})
        else:
            # For remote servers
            connection_config["endpoint"] = endpoint
            connection_config["headers"] = config.get("headers", {})

        # Attempt to connect
        connection = await mcp_manager.connect(server_name, connection_config)

        if connection.state == MCPConnectionState.CONNECTED:
            # Update config with discovered capabilities
            capabilities = {
                "resources": connection.capabilities.resources is not None
                if connection.capabilities
                else False,
                "tools": connection.capabilities.tools is not None
                if connection.capabilities
                else False,
                "prompts": connection.capabilities.prompts is not None
                if connection.capabilities
                else False,
            }

            available_tools = [tool.name for tool in connection.tools]

            ConfigService.update_mcp_server_status(
                name=server_name,
                status="connected",
                workspace_path=workspace_path,
                scope=scope,
                capabilities=capabilities,
                available_tools=available_tools,
            )

            return {
                "status": "connected",
                "message": f"Successfully connected to '{server_name}'",
                "tools_count": len(connection.tools),
                "resources_count": len(connection.resources),
                "prompts_count": len(connection.prompts),
            }
        else:
            ConfigService.update_mcp_server_status(
                name=server_name,
                status="error",
                workspace_path=workspace_path,
                scope=scope,
            )

            return {
                "status": "error",
                "message": connection.error_message or "Failed to connect",
            }

    except KeyError:
        raise HTTPException(
            status_code=404, detail=f"MCP server '{server_name}' not found"
        )
    except Exception as e:
        logger.error(f"Error connecting to MCP server {server_name}: {e}")
        # Update status to error
        try:
            ConfigService.update_mcp_server_status(
                name=server_name,
                status="error",
                workspace_path=workspace_path,
                scope=scope,
            )
        except Exception:
            pass

        raise HTTPException(status_code=500, detail=str(e))


@router.post("/servers/{server_name}/disconnect", status_code=200)
async def disconnect_server(
    server_name: str,
    scope: str = "global",
    workspace_path: Optional[str] = None,
):
    """
    Disconnect from an MCP server.

    Args:
        server_name: Name of server to disconnect from
        scope: Either 'project' or 'global' (default: 'global')
        workspace_path: Required for project scope

    Returns:
        Disconnect confirmation
    """
    try:
        # Disconnect from MCP manager
        mcp_manager = get_mcp_manager()
        await mcp_manager.disconnect(server_name)

        # Update status to disconnected
        ConfigService.update_mcp_server_status(
            name=server_name,
            status="disconnected",
            workspace_path=workspace_path,
            scope=scope,
        )

        return {
            "status": "disconnected",
            "message": f"Successfully disconnected from '{server_name}'",
        }
    except KeyError:
        raise HTTPException(
            status_code=404, detail=f"MCP server '{server_name}' not found"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/servers/{server_name}/tools", response_model=MCPToolsListResponse)
async def get_server_tools(
    server_name: str,
    refresh: bool = False,
):
    """
    Get discovered tools from a connected MCP server.

    Args:
        server_name: Name of the server
        refresh: If True, re-discover tools from the server

    Returns:
        List of available tools
    """
    try:
        mcp_manager = get_mcp_manager()

        if refresh:
            tools = await mcp_manager.refresh_tools(server_name)
        else:
            tools = await mcp_manager.get_tools(server_name)

        tool_responses = [
            MCPToolResponse(
                name=tool.name,
                description=tool.description,
                input_schema=tool.inputSchema.model_dump() if tool.inputSchema else {},
            )
            for tool in tools
        ]

        return MCPToolsListResponse(
            server_name=server_name,
            tools=tool_responses,
            total=len(tool_responses),
        )

    except Exception as e:
        logger.error(f"Error getting tools for {server_name}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/servers/{server_name}/health", response_model=MCPHealthResponse)
async def get_server_health(
    server_name: str,
):
    """
    Check the health of a connected MCP server.

    Args:
        server_name: Name of the server

    Returns:
        Health status including latency
    """
    try:
        mcp_manager = get_mcp_manager()
        health = await mcp_manager.get_health(server_name)

        return MCPHealthResponse(
            server_name=health.server_name,
            is_healthy=health.is_healthy,
            state=health.state.value,
            latency_ms=health.latency_ms,
            last_ping=health.last_ping,
            error=health.error,
        )

    except Exception as e:
        logger.error(f"Error checking health for {server_name}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/servers/{server_name}", response_model=MCPServerResponse)
async def update_server(
    server_name: str,
    server_data: MCPServerUpdate,
    scope: str = "global",
    workspace_path: Optional[str] = None,
):
    """
    Update an MCP server configuration.

    Args:
        server_name: Name of server to update
        server_data: Updated server data
        scope: Either 'project' or 'global' (default: 'global')
        workspace_path: Required for project scope

    Returns:
        Updated MCP server
    """
    try:
        # Get current server data
        current_servers = ConfigService.list_mcp_servers(workspace_path, scope)
        current_server = next(
            (s for s in current_servers if s["id"] == server_name), None
        )

        if not current_server:
            raise HTTPException(
                status_code=404, detail=f"MCP server '{server_name}' not found"
            )

        # Prepare updated configuration
        updated_config = current_server.get("config", {})
        if server_data.config:
            updated_config.update(server_data.config)

        # Update server (remove old and add new)
        ConfigService.remove_mcp_server(server_name, workspace_path, scope)

        new_endpoint = server_data.endpoint or current_server.get("endpoint", "")

        # Determine server type based on endpoint or use existing
        if server_data.endpoint:
            new_type = (
                "remote"
                if server_data.endpoint.startswith(("http://", "https://"))
                else "local"
            )
        else:
            new_type = current_server.get("server_type", "remote")

        ConfigService.add_mcp_server(
            name=server_data.name or server_name,
            server_type=new_type,
            endpoint=new_endpoint,
            workspace_path=workspace_path,
            scope=scope,
            config=updated_config,
            description=server_data.description or current_server.get("description"),
        )

        # Get the updated server
        servers = ConfigService.list_mcp_servers(workspace_path, scope)
        server = next(
            (s for s in servers if s["id"] == (server_data.name or server_name)), None
        )

        if not server:
            raise HTTPException(
                status_code=500, detail="Failed to retrieve updated server"
            )

        return MCPServerResponse(**server)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


class OAuthCallbackRequest(BaseModel):
    """Request model for OAuth callback."""
    server_name: Optional[str] = None
    code: Optional[str] = None
    state: Optional[str] = None
    tokens: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    error_description: Optional[str] = None


@router.post("/oauth/callback", status_code=200)
async def oauth_callback(request: Request):
    """
    Handle OAuth callback from MCP servers.

    This endpoint receives OAuth authorization codes/tokens from MCP servers
    and updates the server configuration with the received tokens.

    Supports both:
    - Direct token response (tokens in body)
    - Authorization code flow (code + state for exchange)

    Args:
        request: HTTP request with OAuth callback data

    Returns:
        OAuth result
    """
    try:
        oauth_service = get_oauth_service()

        # Parse callback data
        callback_data = await request.json()

        code = callback_data.get("code")
        state = callback_data.get("state")
        tokens = callback_data.get("tokens")
        error = callback_data.get("error")
        error_description = callback_data.get("error_description")

        # Handle OAuth error response
        if error:
            logger.error(f"OAuth error: {error} - {error_description}")
            raise HTTPException(
                status_code=400,
                detail=f"OAuth error: {error_description or error}",
            )

        # Validate state parameter (CSRF protection)
        if state:
            is_valid, state_data = oauth_service.validate_state(state)
            if not is_valid:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid or expired OAuth state",
                )
            server_name = state_data.get("server_name")
        else:
            server_name = callback_data.get("server_name")

        if not server_name:
            raise HTTPException(
                status_code=400,
                detail="server_name is required (either in state or body)",
            )

        # Get server configuration
        try:
            server_data = ConfigService.get_mcp_server(server_name)
        except KeyError:
            raise HTTPException(
                status_code=404,
                detail=f"MCP server '{server_name}' not found",
            )

        # Handle authorization code exchange if needed
        if code and not tokens:
            config = server_data.get("config", {})
            token_url = config.get("oauth_token_url")

            if token_url:
                # Exchange code for tokens
                async with httpx.AsyncClient() as client:
                    token_response = await client.post(
                        token_url,
                        data={
                            "grant_type": "authorization_code",
                            "code": code,
                            "client_id": config.get("oauth_client_id"),
                            "client_secret": config.get("oauth_client_secret"),
                            "redirect_uri": config.get("oauth_redirect_uri"),
                        },
                    )

                    if token_response.status_code != 200:
                        raise HTTPException(
                            status_code=400,
                            detail="Failed to exchange authorization code",
                        )

                    tokens = token_response.json()

        if not tokens:
            raise HTTPException(
                status_code=400,
                detail="No tokens received",
            )

        # Store tokens securely
        oauth_service.store_tokens(server_name, tokens)

        # Update server status to connected
        ConfigService.update_mcp_server_status(
            name=server_name,
            status="connected",
            scope="global",
            oauth_tokens={"has_tokens": True},  # Don't store actual tokens in config
        )

        return {
            "status": "success",
            "message": f"OAuth authorization completed for '{server_name}'",
            "server_name": server_name,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"OAuth callback error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


class OAuthUrlRequest(BaseModel):
    """Request model for generating OAuth URL."""
    server_name: str
    redirect_uri: Optional[str] = None
    scopes: Optional[List[str]] = None


@router.post("/oauth/url", status_code=200)
async def generate_oauth_url(request: Request):
    """
    Generate OAuth URL for an MCP server.

    Generates a proper OAuth authorization URL with:
    - State parameter for CSRF protection
    - Requested scopes
    - Proper redirect URI

    Args:
        request: HTTP request with server details

    Returns:
        OAuth URL and instructions
    """
    try:
        oauth_service = get_oauth_service()

        data = await request.json()
        server_name = data.get("server_name")
        redirect_uri = data.get("redirect_uri")
        scopes = data.get("scopes", [])

        if not server_name:
            raise HTTPException(status_code=400, detail="server_name is required")

        # Get server configuration
        try:
            server_data = ConfigService.get_mcp_server(server_name)
        except KeyError:
            raise HTTPException(
                status_code=404, detail=f"MCP server '{server_name}' not found"
            )

        config = server_data.get("config", {})

        # Get OAuth configuration
        oauth_authorize_url = config.get("oauth_authorize_url") or config.get("oauth_url")
        client_id = config.get("oauth_client_id")
        default_redirect_uri = config.get("oauth_redirect_uri")
        default_scopes = config.get("oauth_scopes", [])

        if not oauth_authorize_url:
            raise HTTPException(
                status_code=400,
                detail="OAuth is not configured for this server",
            )

        if not client_id:
            raise HTTPException(
                status_code=400,
                detail="OAuth client_id is not configured",
            )

        # Generate state for CSRF protection
        state = oauth_service.generate_state(
            server_name=server_name,
            redirect_uri=redirect_uri or default_redirect_uri,
        )

        # Build authorization URL
        final_redirect_uri = redirect_uri or default_redirect_uri
        final_scopes = scopes or default_scopes

        params = {
            "response_type": "code",
            "client_id": client_id,
            "state": state,
        }

        if final_redirect_uri:
            params["redirect_uri"] = final_redirect_uri

        if final_scopes:
            params["scope"] = " ".join(final_scopes)

        # Construct full URL
        full_url = f"{oauth_authorize_url}?{urllib.parse.urlencode(params)}"

        return {
            "oauth_url": full_url,
            "state": state,
            "server_name": server_name,
            "expires_in_minutes": oauth_service.STATE_TTL_MINUTES,
            "message": "Visit the OAuth URL to authorize the connection",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating OAuth URL: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/oauth/refresh", status_code=200)
async def refresh_oauth_token(request: Request):
    """
    Refresh OAuth token for an MCP server.

    Args:
        request: HTTP request with server name

    Returns:
        Refresh result
    """
    try:
        oauth_service = get_oauth_service()

        data = await request.json()
        server_name = data.get("server_name")

        if not server_name:
            raise HTTPException(status_code=400, detail="server_name is required")

        # Get refresh token
        refresh_token = oauth_service.get_refresh_token(server_name)
        if not refresh_token:
            raise HTTPException(
                status_code=400,
                detail="No refresh token available",
            )

        # Get server configuration
        try:
            server_data = ConfigService.get_mcp_server(server_name)
        except KeyError:
            raise HTTPException(
                status_code=404, detail=f"MCP server '{server_name}' not found"
            )

        config = server_data.get("config", {})
        token_url = config.get("oauth_token_url")
        client_id = config.get("oauth_client_id")
        client_secret = config.get("oauth_client_secret")

        if not token_url:
            raise HTTPException(
                status_code=400,
                detail="Token URL not configured",
            )

        # Request new tokens
        async with httpx.AsyncClient() as client:
            response = await client.post(
                token_url,
                data={
                    "grant_type": "refresh_token",
                    "refresh_token": refresh_token,
                    "client_id": client_id,
                    "client_secret": client_secret,
                },
            )

            if response.status_code != 200:
                # Refresh failed - tokens are invalid
                oauth_service.delete_tokens(server_name)

                ConfigService.update_mcp_server_status(
                    name=server_name,
                    status="disconnected",
                    scope="global",
                )

                raise HTTPException(
                    status_code=401,
                    detail="Token refresh failed - re-authorization required",
                )

            new_tokens = response.json()

        # Store new tokens
        oauth_service.store_tokens(server_name, new_tokens)

        return {
            "status": "success",
            "message": f"Token refreshed for '{server_name}'",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error refreshing token: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/oauth/tokens/{server_name}", status_code=200)
async def revoke_oauth_tokens(server_name: str):
    """
    Revoke OAuth tokens for an MCP server.

    Args:
        server_name: Name of the server

    Returns:
        Revocation result
    """
    try:
        oauth_service = get_oauth_service()

        deleted = oauth_service.delete_tokens(server_name)

        if deleted:
            # Update server status
            try:
                ConfigService.update_mcp_server_status(
                    name=server_name,
                    status="disconnected",
                    scope="global",
                )
            except KeyError:
                pass

            return {
                "status": "success",
                "message": f"OAuth tokens revoked for '{server_name}'",
            }

        return {
            "status": "not_found",
            "message": f"No tokens found for '{server_name}'",
        }

    except Exception as e:
        logger.error(f"Error revoking tokens: {e}")
        raise HTTPException(status_code=500, detail=str(e))
