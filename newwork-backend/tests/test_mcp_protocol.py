"""
Tests for MCP Protocol Models.
"""

import pytest
from app.models.mcp_protocol import (
    JSONRPCRequest,
    JSONRPCResponse,
    JSONRPCNotification,
    MCPCapabilities,
    MCPTool,
    MCPToolInputSchema,
    MCPToolCallParams,
    MCPResource,
    MCPPrompt,
    MCPPromptArgument,
    MCPConnectionState,
    MCPConnectionInfo,
    MCPHealthStatus,
    MCPServerInfo,
    MCPClientInfo,
)


class TestJSONRPCModels:
    """Test JSON-RPC message models."""

    def test_jsonrpc_request_creation(self):
        """Should create valid JSON-RPC request."""
        request = JSONRPCRequest(
            id=1,
            method="tools/list",
            params={"cursor": None},
        )

        assert request.jsonrpc == "2.0"
        assert request.id == 1
        assert request.method == "tools/list"
        assert request.params == {"cursor": None}

    def test_jsonrpc_request_without_params(self):
        """Should create request without params."""
        request = JSONRPCRequest(
            id="abc-123",
            method="ping",
        )

        assert request.id == "abc-123"
        assert request.method == "ping"
        assert request.params is None

    def test_jsonrpc_response_success(self):
        """Should create success response."""
        response = JSONRPCResponse(
            id=1,
            result={"tools": []},
        )

        assert response.id == 1
        assert response.result == {"tools": []}
        assert response.error is None

    def test_jsonrpc_response_error(self):
        """Should create error response."""
        response = JSONRPCResponse(
            id=1,
            error={
                "code": -32600,
                "message": "Invalid Request",
                "data": {"details": "Missing method"},
            },
        )

        assert response.result is None
        assert response.error["code"] == -32600
        assert response.error["message"] == "Invalid Request"

    def test_jsonrpc_notification(self):
        """Should create notification (no id)."""
        notification = JSONRPCNotification(
            method="notifications/message",
            params={"level": "info", "message": "Connected"},
        )

        assert notification.jsonrpc == "2.0"
        assert notification.method == "notifications/message"
        assert not hasattr(notification, "id") or notification.model_fields.get("id") is None


class TestMCPCapabilities:
    """Test MCP capability models."""

    def test_capabilities_default(self):
        """Should have None defaults."""
        caps = MCPCapabilities()

        assert caps.tools is None
        assert caps.resources is None
        assert caps.prompts is None
        assert caps.logging is None

    def test_capabilities_with_tools(self):
        """Should accept tools capability config."""
        caps = MCPCapabilities(
            tools={"listChanged": True},
            resources={"subscribe": True},
        )

        assert caps.tools == {"listChanged": True}
        assert caps.resources == {"subscribe": True}


class TestMCPTool:
    """Test MCP tool models."""

    def test_tool_creation(self):
        """Should create valid tool."""
        schema = MCPToolInputSchema(
            type="object",
            properties={
                "path": {"type": "string"},
            },
            required=["path"],
        )
        tool = MCPTool(
            name="read_file",
            description="Read contents of a file",
            inputSchema=schema,
        )

        assert tool.name == "read_file"
        assert tool.description == "Read contents of a file"
        assert "path" in tool.inputSchema.properties

    def test_tool_call_params(self):
        """Should create tool call params."""
        params = MCPToolCallParams(
            name="write_file",
            arguments={
                "path": "/tmp/test.txt",
                "content": "Hello, World!",
            },
        )

        assert params.name == "write_file"
        assert params.arguments["path"] == "/tmp/test.txt"


class TestMCPResource:
    """Test MCP resource models."""

    def test_resource_creation(self):
        """Should create valid resource."""
        resource = MCPResource(
            uri="file:///workspace/main.py",
            name="main.py",
            description="Main application file",
            mimeType="text/x-python",
        )

        assert resource.uri == "file:///workspace/main.py"
        assert resource.name == "main.py"
        assert resource.mimeType == "text/x-python"


class TestMCPPrompt:
    """Test MCP prompt models."""

    def test_prompt_creation(self):
        """Should create valid prompt."""
        prompt = MCPPrompt(
            name="code_review",
            description="Review code for issues",
            arguments=[
                MCPPromptArgument(name="code", required=True),
                MCPPromptArgument(name="language", required=False),
            ],
        )

        assert prompt.name == "code_review"
        assert len(prompt.arguments) == 2
        assert prompt.arguments[0].name == "code"
        assert prompt.arguments[0].required is True


class TestMCPConnectionState:
    """Test connection state enum."""

    def test_connection_states(self):
        """Should have expected states."""
        assert MCPConnectionState.DISCONNECTED.value == "disconnected"
        assert MCPConnectionState.CONNECTING.value == "connecting"
        assert MCPConnectionState.CONNECTED.value == "connected"
        assert MCPConnectionState.ERROR.value == "error"


class TestMCPConnectionInfo:
    """Test connection info model."""

    def test_connection_info_creation(self):
        """Should create connection info."""
        info = MCPConnectionInfo(
            server_name="my-server",
            state=MCPConnectionState.CONNECTED,
            capabilities=MCPCapabilities(tools={"listChanged": True}),
            connected_at="2024-01-15T10:00:00",
        )

        assert info.server_name == "my-server"
        assert info.state == MCPConnectionState.CONNECTED
        assert info.capabilities.tools == {"listChanged": True}

    def test_connection_info_with_error(self):
        """Should include error message."""
        info = MCPConnectionInfo(
            server_name="failed-server",
            state=MCPConnectionState.ERROR,
            error_message="Connection refused",
        )

        assert info.state == MCPConnectionState.ERROR
        assert info.error_message == "Connection refused"

    def test_connection_info_with_tools(self):
        """Should include discovered tools."""
        tool = MCPTool(name="test_tool", description="A test tool")
        info = MCPConnectionInfo(
            server_name="tool-server",
            state=MCPConnectionState.CONNECTED,
            tools=[tool],
        )

        assert len(info.tools) == 1
        assert info.tools[0].name == "test_tool"


class TestMCPHealthStatus:
    """Test health status model."""

    def test_health_status_healthy(self):
        """Should represent healthy status."""
        health = MCPHealthStatus(
            server_name="healthy-server",
            is_healthy=True,
            state=MCPConnectionState.CONNECTED,
            latency_ms=15.5,
            last_ping="2024-01-15T10:00:00",
        )

        assert health.is_healthy is True
        assert health.latency_ms == 15.5
        assert health.error is None

    def test_health_status_unhealthy(self):
        """Should represent unhealthy status."""
        health = MCPHealthStatus(
            server_name="unhealthy-server",
            is_healthy=False,
            state=MCPConnectionState.ERROR,
            error="Connection timeout",
        )

        assert health.is_healthy is False
        assert health.error == "Connection timeout"


class TestMCPInfoModels:
    """Test client and server info models."""

    def test_client_info_defaults(self):
        """Should have default values."""
        info = MCPClientInfo()

        assert info.name == "newwork-backend"
        assert info.version == "1.0.0"

    def test_server_info(self):
        """Should create server info."""
        info = MCPServerInfo(
            name="my-mcp-server",
            version="2.0.0",
        )

        assert info.name == "my-mcp-server"
        assert info.version == "2.0.0"
