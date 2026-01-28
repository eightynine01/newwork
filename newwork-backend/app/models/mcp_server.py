"""
MCP Server model.

Represents a Model Context Protocol server configuration.
"""

from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class MCPServerStatus(str, Enum):
    """MCP server connection status."""

    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    CONNECTING = "connecting"
    ERROR = "error"


class MCPServer(BaseModel):
    """MCP server configuration model."""

    id: str
    name: str
    description: Optional[str] = None
    endpoint: str
    server_type: str = "remote"  # "remote" or "local"
    status: MCPServerStatus = MCPServerStatus.DISCONNECTED
    available_tools: List[str] = Field(default_factory=list)
    capabilities: Optional[Dict[str, Any]] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_connected_at: Optional[datetime] = None
    config: Optional[Dict[str, Any]] = None  # Additional config (env vars, oauth, etc.)

    class Config:
        use_enum_values = True


class MCPServerCreate(BaseModel):
    """Schema for creating a new MCP server."""

    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    endpoint: str = Field(..., min_length=1)
    server_type: str = "remote"  # "remote" or "local"
    config: Optional[Dict[str, Any]] = None


class MCPServerUpdate(BaseModel):
    """Schema for updating an MCP server."""

    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    endpoint: Optional[str] = Field(None, min_length=1)
    config: Optional[Dict[str, Any]] = None


class MCPServerResponse(BaseModel):
    """Schema for MCP server API responses."""

    id: str
    name: str
    description: Optional[str] = None
    endpoint: str
    server_type: str
    status: MCPServerStatus
    available_tools: List[str]
    capabilities: Optional[Dict[str, Any]]
    created_at: datetime
    last_connected_at: Optional[datetime]
    config: Optional[Dict[str, Any]]
