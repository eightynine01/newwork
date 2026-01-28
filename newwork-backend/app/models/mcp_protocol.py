"""
MCP Protocol Models.

Defines JSON-RPC message types for Model Context Protocol communication.
"""

from typing import Dict, List, Any, Optional, Union
from pydantic import BaseModel, Field
from enum import Enum


class MCPProtocolVersion(str, Enum):
    """Supported MCP protocol versions."""
    V1 = "2024-11-05"


class JSONRPCMessage(BaseModel):
    """Base JSON-RPC 2.0 message."""
    jsonrpc: str = "2.0"


class JSONRPCRequest(JSONRPCMessage):
    """JSON-RPC 2.0 request message."""
    id: Union[str, int]
    method: str
    params: Optional[Dict[str, Any]] = None


class JSONRPCResponse(JSONRPCMessage):
    """JSON-RPC 2.0 response message."""
    id: Union[str, int]
    result: Optional[Any] = None
    error: Optional[Dict[str, Any]] = None


class JSONRPCNotification(JSONRPCMessage):
    """JSON-RPC 2.0 notification (no id, no response expected)."""
    method: str
    params: Optional[Dict[str, Any]] = None


# MCP Capability Models

class MCPCapabilities(BaseModel):
    """MCP server/client capabilities."""
    tools: Optional[Dict[str, Any]] = None
    resources: Optional[Dict[str, Any]] = None
    prompts: Optional[Dict[str, Any]] = None
    logging: Optional[Dict[str, Any]] = None
    experimental: Optional[Dict[str, Any]] = None


class MCPClientInfo(BaseModel):
    """Information about the MCP client."""
    name: str = "newwork-backend"
    version: str = "1.0.0"


class MCPServerInfo(BaseModel):
    """Information about the MCP server."""
    name: str
    version: str


class MCPInitializeParams(BaseModel):
    """Parameters for initialize request."""
    protocolVersion: str = MCPProtocolVersion.V1.value
    capabilities: MCPCapabilities = Field(default_factory=MCPCapabilities)
    clientInfo: MCPClientInfo = Field(default_factory=MCPClientInfo)


class MCPInitializeResult(BaseModel):
    """Result of initialize request."""
    protocolVersion: str
    capabilities: MCPCapabilities
    serverInfo: MCPServerInfo


# Tool Models

class MCPToolInputSchema(BaseModel):
    """JSON Schema for tool input."""
    type: str = "object"
    properties: Dict[str, Any] = Field(default_factory=dict)
    required: List[str] = Field(default_factory=list)


class MCPTool(BaseModel):
    """An MCP tool definition."""
    name: str
    description: Optional[str] = None
    inputSchema: MCPToolInputSchema = Field(default_factory=MCPToolInputSchema)


class MCPToolsListResult(BaseModel):
    """Result of tools/list request."""
    tools: List[MCPTool]


class MCPToolCallParams(BaseModel):
    """Parameters for tools/call request."""
    name: str
    arguments: Optional[Dict[str, Any]] = None


class MCPToolCallResult(BaseModel):
    """Result of tools/call request."""
    content: List[Dict[str, Any]]
    isError: bool = False


# Resource Models

class MCPResource(BaseModel):
    """An MCP resource definition."""
    uri: str
    name: str
    description: Optional[str] = None
    mimeType: Optional[str] = None


class MCPResourcesListResult(BaseModel):
    """Result of resources/list request."""
    resources: List[MCPResource]


class MCPResourceReadParams(BaseModel):
    """Parameters for resources/read request."""
    uri: str


class MCPResourceContent(BaseModel):
    """Content of a resource."""
    uri: str
    mimeType: Optional[str] = None
    text: Optional[str] = None
    blob: Optional[str] = None  # base64 encoded


class MCPResourceReadResult(BaseModel):
    """Result of resources/read request."""
    contents: List[MCPResourceContent]


# Prompt Models

class MCPPromptArgument(BaseModel):
    """An argument for a prompt template."""
    name: str
    description: Optional[str] = None
    required: bool = False


class MCPPrompt(BaseModel):
    """An MCP prompt template."""
    name: str
    description: Optional[str] = None
    arguments: List[MCPPromptArgument] = Field(default_factory=list)


class MCPPromptsListResult(BaseModel):
    """Result of prompts/list request."""
    prompts: List[MCPPrompt]


class MCPPromptMessage(BaseModel):
    """A message in a prompt."""
    role: str  # "user" or "assistant"
    content: Dict[str, Any]


class MCPPromptGetParams(BaseModel):
    """Parameters for prompts/get request."""
    name: str
    arguments: Optional[Dict[str, str]] = None


class MCPPromptGetResult(BaseModel):
    """Result of prompts/get request."""
    description: Optional[str] = None
    messages: List[MCPPromptMessage]


# Connection State

class MCPConnectionState(str, Enum):
    """Connection state for MCP servers."""
    DISCONNECTED = "disconnected"
    CONNECTING = "connecting"
    CONNECTED = "connected"
    ERROR = "error"


class MCPConnectionInfo(BaseModel):
    """Information about an active MCP connection."""
    server_name: str
    state: MCPConnectionState
    server_info: Optional[MCPServerInfo] = None
    capabilities: Optional[MCPCapabilities] = None
    tools: List[MCPTool] = Field(default_factory=list)
    resources: List[MCPResource] = Field(default_factory=list)
    prompts: List[MCPPrompt] = Field(default_factory=list)
    error_message: Optional[str] = None
    connected_at: Optional[str] = None


# Health Check Models

class MCPHealthStatus(BaseModel):
    """Health status of an MCP connection."""
    server_name: str
    is_healthy: bool
    state: MCPConnectionState
    latency_ms: Optional[float] = None
    last_ping: Optional[str] = None
    error: Optional[str] = None
