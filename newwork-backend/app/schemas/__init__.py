from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime


class SessionBase(BaseModel):
    """Base schema for Session."""

    title: str = Field(..., description="Session title")
    path: Optional[str] = Field(None, description="Workspace path")
    provider: Optional[str] = Field(None, description="AI provider name")
    model: Optional[str] = Field(None, description="Model identifier")
    system_prompt: Optional[str] = Field(None, description="Custom system prompt")


class SessionCreate(SessionBase):
    """Schema for creating a Session."""

    pass


class SessionUpdate(BaseModel):
    """Schema for updating a Session."""

    title: Optional[str] = None
    path: Optional[str] = None
    provider: Optional[str] = None
    model: Optional[str] = None
    system_prompt: Optional[str] = None


class SessionResponse(SessionBase):
    """Schema for Session response."""

    id: str
    provider: str = Field(default="anthropic")
    model: str = Field(default="claude-sonnet-4-20250514")
    total_input_tokens: int = Field(default=0)
    total_output_tokens: int = Field(default=0)
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PromptRequest(BaseModel):
    """Schema for sending a prompt."""

    prompt: str = Field(..., description="Prompt text")
    model: Optional[str] = Field(None, description="Model identifier")
    provider: Optional[str] = Field(None, description="AI provider name")
    stream: bool = Field(default=True, description="Stream the response")


class PromptResponse(BaseModel):
    """Schema for prompt response."""

    session_id: str
    message: str
    status: str


# Template schemas
class TemplateBase(BaseModel):
    """Base schema for Template."""

    name: str = Field(..., description="Template name")
    description: Optional[str] = Field(None, description="Template description")
    content: str = Field(..., description="Template content/system prompt")
    scope: Optional[str] = Field(
        "workspace", description="Template scope: 'workspace' or 'global'"
    )
    skills: Optional[List[str]] = Field(
        default_factory=list, description="List of skill names"
    )
    parameters: Optional[Dict[str, Any]] = Field(
        None, description="Optional parameters"
    )


class TemplateCreate(TemplateBase):
    """Schema for creating a Template."""

    pass


class TemplateUpdate(BaseModel):
    """Schema for updating a Template."""

    name: Optional[str] = None
    description: Optional[str] = None
    content: Optional[str] = None
    scope: Optional[str] = None
    skills: Optional[List[str]] = None
    parameters: Optional[Dict[str, Any]] = None


class TemplateResponse(TemplateBase):
    """Schema for Template response."""

    id: str
    usage_count: int = Field(
        default=0, description="Number of times template has been used"
    )
    is_public: bool = Field(
        default=False, description="Whether template is public (global scope)"
    )
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TemplateRunRequest(BaseModel):
    """Schema for running a template."""

    variables: Optional[Dict[str, Any]] = Field(
        default={}, description="Variables for template substitution"
    )


class TemplateRunResponse(BaseModel):
    """Schema for template run response."""

    prompt: str
    status: str
    template_id: str


# Workspace schemas
class WorkspaceBase(BaseModel):
    """Base schema for Workspace."""

    name: str = Field(..., description="Workspace name")
    path: str = Field(..., description="Workspace path")
    description: Optional[str] = Field(None, description="Workspace description")


class WorkspaceCreate(WorkspaceBase):
    """Schema for creating a Workspace."""

    pass


class WorkspaceUpdate(BaseModel):
    """Schema for updating a Workspace."""

    name: Optional[str] = None
    path: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None


class WorkspaceResponse(WorkspaceBase):
    """Schema for Workspace response."""

    id: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class WorkspaceAuthorizeRequest(BaseModel):
    """Schema for authorizing a workspace."""

    path: str = Field(..., description="Directory path to authorize")


class WorkspaceAuthorizeResponse(BaseModel):
    """Schema for workspace authorization response."""

    workspace_id: str
    authorized: bool
    message: str


# Permission schemas
class PermissionResponse(BaseModel):
    """Schema for Permission response."""

    id: str
    session_id: str
    tool_name: str
    description: Optional[str]
    status: str
    response: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PermissionRespondRequest(BaseModel):
    """Schema for responding to a permission request."""

    reply: str = Field(
        ...,
        description="Response: 'allow_once', 'allow_always', or 'deny'",
    )


class PermissionRespondResponse(BaseModel):
    """Schema for permission respond response."""

    permission_id: str
    status: str
    message: str


# Model schemas
class ModelCapabilities(BaseModel):
    """Schema for model capabilities."""

    reasoning: bool = Field(
        default=False, description="Model has extended thinking capability"
    )
    vision: bool = Field(default=False, description="Model can process images")
    tools: bool = Field(default=False, description="Model supports function calling")
    multimodal: bool = Field(
        default=False, description="Model supports multiple modalities"
    )


class ModelCost(BaseModel):
    """Schema for model cost information."""

    input: float = Field(default=0.0, description="Cost per 1M input tokens")
    output: float = Field(default=0.0, description="Cost per 1M output tokens")
    free: bool = Field(default=False, description="Model is free to use")


class ModelInfo(BaseModel):
    """Schema for model information."""

    id: str
    name: str
    provider: Optional[str] = None
    provider_id: Optional[str] = None
    provider_name: Optional[str] = None
    description: Optional[str] = None
    capabilities: Optional[ModelCapabilities] = None
    cost: Optional[ModelCost] = None
    is_default: bool = Field(
        default=False, description="Whether this is the default model"
    )


class ProviderInfo(BaseModel):
    """Schema for provider information."""

    id: str
    name: str
    description: Optional[str] = None
    icon_url: Optional[str] = None
    is_available: bool = Field(default=True)
    models: List[ModelInfo] = Field(default_factory=list)


# Event schemas
class EventMessage(BaseModel):
    """Schema for SSE event message."""

    type: str
    data: Optional[Dict[str, Any]] = None
    session_id: Optional[str] = None
    timestamp: Optional[str] = None


# Health check schema
class HealthResponse(BaseModel):
    """Schema for health check response."""

    status: str
    app: str
    version: str


# API response wrapper
class APIResponse(BaseModel):
    """Generic API response wrapper."""

    success: bool
    message: str
    data: Optional[Any] = None


# Skill schemas
class SkillBase(BaseModel):
    """Base schema for Skill."""

    name: str = Field(..., description="Skill name")
    description: Optional[str] = Field(None, description="Skill description")
    config: Optional[Dict[str, Any]] = Field(
        None, description="Skill configuration (JSON)"
    )


class SkillCreate(SkillBase):
    """Schema for creating a Skill."""

    pass


class SkillUpdate(BaseModel):
    """Schema for updating a Skill."""

    name: Optional[str] = None
    description: Optional[str] = None
    config: Optional[Dict[str, Any]] = None


class SkillResponse(BaseModel):
    """Schema for Skill response."""

    id: str
    name: str
    description: Optional[str] = None
    version: Optional[str] = None
    config: Optional[str] = None  # JSON string in database
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# File schemas
class FileInfo(BaseModel):
    """Schema for file information."""

    path: str = Field(..., description="Relative path from workspace root")
    name: str = Field(..., description="File or directory name")
    type: str = Field(..., description="Type: 'file' or 'directory'")
    size: Optional[int] = Field(None, description="File size in bytes (None for directories)")
    modified: Optional[float] = Field(None, description="Last modified timestamp")
    created: Optional[float] = Field(None, description="Creation timestamp")
    is_file: bool = Field(default=True, description="Whether this is a file")
    is_dir: bool = Field(default=False, description="Whether this is a directory")


class FileListResponse(BaseModel):
    """Schema for file list response."""

    workspace_id: str
    path: str
    files: List[FileInfo]
    total: int = Field(..., description="Total number of files")


class FileContentResponse(BaseModel):
    """Schema for file content response."""

    path: str
    name: str
    content: str
    size: int
    modified: Optional[float] = None


class FileCreateRequest(BaseModel):
    """Schema for creating a file."""

    path: str = Field(..., description="File path relative to workspace root")
    content: str = Field(default="", description="File content")


class FileUpdateRequest(BaseModel):
    """Schema for updating a file."""

    content: str = Field(..., description="New file content")


class FileOperationResponse(BaseModel):
    """Schema for file operation response."""

    success: bool
    message: str
    path: Optional[str] = None
