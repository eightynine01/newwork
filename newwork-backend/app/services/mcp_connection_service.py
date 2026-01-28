"""
MCP Connection Service.

Manages connections to MCP servers using stdio (local) or SSE (remote) transports.
"""

import asyncio
import json
import logging
import time
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any, Union
from datetime import datetime
import httpx

from app.models.mcp_protocol import (
    MCPConnectionState,
    MCPConnectionInfo,
    MCPHealthStatus,
    MCPTool,
    MCPResource,
    MCPPrompt,
    MCPCapabilities,
    MCPServerInfo,
    MCPInitializeParams,
    MCPClientInfo,
    JSONRPCRequest,
)

logger = logging.getLogger(__name__)


class MCPConnection(ABC):
    """Abstract base class for MCP connections."""

    def __init__(self, server_name: str, config: Dict[str, Any]):
        self.server_name = server_name
        self.config = config
        self.state = MCPConnectionState.DISCONNECTED
        self.server_info: Optional[MCPServerInfo] = None
        self.capabilities: Optional[MCPCapabilities] = None
        self.tools: List[MCPTool] = []
        self.resources: List[MCPResource] = []
        self.prompts: List[MCPPrompt] = []
        self.error_message: Optional[str] = None
        self.connected_at: Optional[datetime] = None
        self._request_id = 0
        self._pending_requests: Dict[Union[str, int], asyncio.Future] = {}

    def _next_request_id(self) -> int:
        """Generate the next request ID."""
        self._request_id += 1
        return self._request_id

    @abstractmethod
    async def connect(self) -> bool:
        """Establish connection to the MCP server."""
        pass

    @abstractmethod
    async def disconnect(self) -> None:
        """Close the connection to the MCP server."""
        pass

    @abstractmethod
    async def send_request(
        self, method: str, params: Optional[Dict[str, Any]] = None
    ) -> Any:
        """Send a JSON-RPC request and wait for response."""
        pass

    async def initialize(self) -> bool:
        """Initialize the MCP connection with handshake."""
        try:
            init_params = MCPInitializeParams(
                clientInfo=MCPClientInfo(name="newwork-backend", version="1.0.0")
            )

            result = await self.send_request("initialize", init_params.model_dump())

            if result:
                self.server_info = MCPServerInfo(**result.get("serverInfo", {}))
                self.capabilities = MCPCapabilities(**result.get("capabilities", {}))

                # Send initialized notification
                await self.send_request("notifications/initialized", {})

                return True
            return False
        except Exception as e:
            logger.error(f"Failed to initialize MCP connection: {e}")
            self.error_message = str(e)
            return False

    async def discover_tools(self) -> List[MCPTool]:
        """Discover available tools from the server."""
        try:
            result = await self.send_request("tools/list", {})
            if result and "tools" in result:
                self.tools = [MCPTool(**tool) for tool in result["tools"]]
            return self.tools
        except Exception as e:
            logger.error(f"Failed to discover tools: {e}")
            return []

    async def discover_resources(self) -> List[MCPResource]:
        """Discover available resources from the server."""
        try:
            result = await self.send_request("resources/list", {})
            if result and "resources" in result:
                self.resources = [MCPResource(**res) for res in result["resources"]]
            return self.resources
        except Exception as e:
            logger.error(f"Failed to discover resources: {e}")
            return []

    async def discover_prompts(self) -> List[MCPPrompt]:
        """Discover available prompts from the server."""
        try:
            result = await self.send_request("prompts/list", {})
            if result and "prompts" in result:
                self.prompts = [MCPPrompt(**prompt) for prompt in result["prompts"]]
            return self.prompts
        except Exception as e:
            logger.error(f"Failed to discover prompts: {e}")
            return []

    async def call_tool(
        self, tool_name: str, arguments: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Call a tool on the MCP server."""
        params = {"name": tool_name}
        if arguments:
            params["arguments"] = arguments

        result = await self.send_request("tools/call", params)
        return result or {}

    async def ping(self) -> float:
        """Ping the server and return latency in milliseconds."""
        start = time.time()
        try:
            await self.send_request("ping", {})
            return (time.time() - start) * 1000
        except Exception:
            return -1

    def get_connection_info(self) -> MCPConnectionInfo:
        """Get current connection information."""
        return MCPConnectionInfo(
            server_name=self.server_name,
            state=self.state,
            server_info=self.server_info,
            capabilities=self.capabilities,
            tools=self.tools,
            resources=self.resources,
            prompts=self.prompts,
            error_message=self.error_message,
            connected_at=self.connected_at.isoformat() if self.connected_at else None,
        )


class StdioMCPConnection(MCPConnection):
    """
    MCP connection using stdio transport (for local servers).

    Uses asyncio.create_subprocess_exec which does NOT use shell,
    preventing command injection vulnerabilities.
    """

    def __init__(self, server_name: str, config: Dict[str, Any]):
        super().__init__(server_name, config)
        self.process: Optional[asyncio.subprocess.Process] = None
        self._read_task: Optional[asyncio.Task] = None
        self._write_lock = asyncio.Lock()

    async def connect(self) -> bool:
        """Start the subprocess and establish connection."""
        try:
            self.state = MCPConnectionState.CONNECTING

            command = self.config.get("command", "")
            args = self.config.get("args", [])
            env = self.config.get("env", {})

            if not command:
                raise ValueError("Command is required for stdio connection")

            # Validate command - must be a simple command name, not a shell expression
            if any(c in command for c in [";", "&", "|", "$", "`", "(", ")", "{", "}"]):
                raise ValueError("Command contains invalid shell characters")

            # Prepare environment
            import os
            proc_env = os.environ.copy()
            proc_env.update(env)

            # Start subprocess using exec (not shell) - safe from injection
            self.process = await asyncio.create_subprocess_exec(
                command,
                *args,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env=proc_env,
            )

            # Start reading responses
            self._read_task = asyncio.create_task(self._read_loop())

            # Initialize connection
            if await self.initialize():
                self.state = MCPConnectionState.CONNECTED
                self.connected_at = datetime.now()

                # Discover capabilities
                await self.discover_tools()
                await self.discover_resources()
                await self.discover_prompts()

                return True
            else:
                self.state = MCPConnectionState.ERROR
                return False

        except Exception as e:
            logger.error(f"Failed to connect to {self.server_name}: {e}")
            self.state = MCPConnectionState.ERROR
            self.error_message = str(e)
            return False

    async def disconnect(self) -> None:
        """Stop the subprocess and cleanup."""
        if self._read_task:
            self._read_task.cancel()
            try:
                await self._read_task
            except asyncio.CancelledError:
                pass

        if self.process:
            self.process.terminate()
            try:
                await asyncio.wait_for(self.process.wait(), timeout=5.0)
            except asyncio.TimeoutError:
                self.process.kill()
                await self.process.wait()

        self.state = MCPConnectionState.DISCONNECTED
        self.process = None

    async def _read_loop(self) -> None:
        """Read and dispatch responses from stdout."""
        if not self.process or not self.process.stdout:
            return

        try:
            while True:
                line = await self.process.stdout.readline()
                if not line:
                    break

                try:
                    message = json.loads(line.decode())
                    await self._handle_message(message)
                except json.JSONDecodeError:
                    logger.warning(f"Invalid JSON from {self.server_name}: {line}")

        except asyncio.CancelledError:
            pass
        except Exception as e:
            logger.error(f"Read loop error for {self.server_name}: {e}")
            self.state = MCPConnectionState.ERROR
            self.error_message = str(e)

    async def _handle_message(self, message: Dict[str, Any]) -> None:
        """Handle incoming JSON-RPC message."""
        if "id" in message:
            # This is a response
            request_id = message["id"]
            if request_id in self._pending_requests:
                future = self._pending_requests.pop(request_id)
                if "error" in message:
                    future.set_exception(
                        Exception(message["error"].get("message", "Unknown error"))
                    )
                else:
                    future.set_result(message.get("result"))
        else:
            # This is a notification
            logger.debug(f"Received notification: {message.get('method')}")

    async def send_request(
        self, method: str, params: Optional[Dict[str, Any]] = None
    ) -> Any:
        """Send a JSON-RPC request and wait for response."""
        if not self.process or not self.process.stdin:
            raise RuntimeError("Not connected")

        request_id = self._next_request_id()
        request = JSONRPCRequest(id=request_id, method=method, params=params)

        future: asyncio.Future = asyncio.get_event_loop().create_future()
        self._pending_requests[request_id] = future

        async with self._write_lock:
            message = request.model_dump_json() + "\n"
            self.process.stdin.write(message.encode())
            await self.process.stdin.drain()

        try:
            return await asyncio.wait_for(future, timeout=30.0)
        except asyncio.TimeoutError:
            self._pending_requests.pop(request_id, None)
            raise TimeoutError(f"Request {method} timed out")


class SSEMCPConnection(MCPConnection):
    """MCP connection using SSE transport (for remote servers)."""

    def __init__(self, server_name: str, config: Dict[str, Any]):
        super().__init__(server_name, config)
        self._client: Optional[httpx.AsyncClient] = None
        self._sse_task: Optional[asyncio.Task] = None
        self._session_id: Optional[str] = None

    async def connect(self) -> bool:
        """Establish HTTP/SSE connection to remote server."""
        try:
            self.state = MCPConnectionState.CONNECTING

            endpoint = self.config.get("endpoint", "")
            headers = self.config.get("headers", {})

            if not endpoint:
                raise ValueError("Endpoint is required for SSE connection")

            self._client = httpx.AsyncClient(
                timeout=httpx.Timeout(30.0),
                headers=headers,
            )

            # Start SSE connection for receiving messages
            self._sse_task = asyncio.create_task(self._sse_loop(endpoint))

            # Wait a bit for SSE connection
            await asyncio.sleep(0.5)

            # Initialize connection
            if await self.initialize():
                self.state = MCPConnectionState.CONNECTED
                self.connected_at = datetime.now()

                # Discover capabilities
                await self.discover_tools()
                await self.discover_resources()
                await self.discover_prompts()

                return True
            else:
                self.state = MCPConnectionState.ERROR
                return False

        except Exception as e:
            logger.error(f"Failed to connect to {self.server_name}: {e}")
            self.state = MCPConnectionState.ERROR
            self.error_message = str(e)
            return False

    async def disconnect(self) -> None:
        """Close the HTTP connection."""
        if self._sse_task:
            self._sse_task.cancel()
            try:
                await self._sse_task
            except asyncio.CancelledError:
                pass

        if self._client:
            await self._client.aclose()

        self.state = MCPConnectionState.DISCONNECTED

    async def _sse_loop(self, endpoint: str) -> None:
        """Listen for SSE events from the server."""
        if not self._client:
            return

        try:
            async with self._client.stream("GET", f"{endpoint}/sse") as response:
                async for line in response.aiter_lines():
                    if line.startswith("data: "):
                        data = line[6:]
                        try:
                            message = json.loads(data)
                            await self._handle_message(message)
                        except json.JSONDecodeError:
                            pass

        except asyncio.CancelledError:
            pass
        except Exception as e:
            logger.error(f"SSE loop error for {self.server_name}: {e}")
            self.state = MCPConnectionState.ERROR
            self.error_message = str(e)

    async def _handle_message(self, message: Dict[str, Any]) -> None:
        """Handle incoming JSON-RPC message."""
        if "id" in message:
            request_id = message["id"]
            if request_id in self._pending_requests:
                future = self._pending_requests.pop(request_id)
                if "error" in message:
                    future.set_exception(
                        Exception(message["error"].get("message", "Unknown error"))
                    )
                else:
                    future.set_result(message.get("result"))

    async def send_request(
        self, method: str, params: Optional[Dict[str, Any]] = None
    ) -> Any:
        """Send a JSON-RPC request via HTTP POST."""
        if not self._client:
            raise RuntimeError("Not connected")

        endpoint = self.config.get("endpoint", "")
        request_id = self._next_request_id()
        request = JSONRPCRequest(id=request_id, method=method, params=params)

        future: asyncio.Future = asyncio.get_event_loop().create_future()
        self._pending_requests[request_id] = future

        try:
            response = await self._client.post(
                f"{endpoint}/message",
                json=request.model_dump(),
            )

            if response.status_code != 200:
                raise Exception(f"HTTP error: {response.status_code}")

            # For immediate responses
            content_type = response.headers.get("content-type", "")
            if content_type.startswith("application/json"):
                result = response.json()
                if "id" in result:
                    self._pending_requests.pop(request_id, None)
                    if "error" in result:
                        raise Exception(result["error"].get("message", "Unknown error"))
                    return result.get("result")

            # Wait for SSE response
            return await asyncio.wait_for(future, timeout=30.0)

        except asyncio.TimeoutError:
            self._pending_requests.pop(request_id, None)
            raise TimeoutError(f"Request {method} timed out")


class MCPConnectionManager:
    """
    Singleton manager for all MCP connections.

    Manages lifecycle of connections to multiple MCP servers.
    """

    _instance: Optional["MCPConnectionManager"] = None
    _lock = asyncio.Lock()

    def __new__(cls) -> "MCPConnectionManager":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._connections: Dict[str, MCPConnection] = {}
            cls._instance._initialized = False
        return cls._instance

    @classmethod
    def get_instance(cls) -> "MCPConnectionManager":
        """Get the singleton instance."""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    async def connect(
        self, server_name: str, config: Dict[str, Any]
    ) -> MCPConnection:
        """
        Connect to an MCP server.

        Args:
            server_name: Unique name for the server
            config: Server configuration including:
                - server_type: "stdio" or "sse"
                - command: Command to run (for stdio)
                - args: Command arguments (for stdio)
                - endpoint: HTTP endpoint (for sse)
                - env: Environment variables (for stdio)
                - headers: HTTP headers (for sse)

        Returns:
            MCPConnection instance
        """
        async with self._lock:
            # Disconnect existing connection if any
            if server_name in self._connections:
                await self._connections[server_name].disconnect()

            # Create appropriate connection type
            server_type = config.get("server_type", "stdio")

            if server_type in ("stdio", "local"):
                connection = StdioMCPConnection(server_name, config)
            elif server_type in ("sse", "remote"):
                connection = SSEMCPConnection(server_name, config)
            else:
                raise ValueError(f"Unknown server type: {server_type}")

            # Establish connection
            success = await connection.connect()

            if success:
                self._connections[server_name] = connection
                logger.info(f"Connected to MCP server: {server_name}")
            else:
                logger.error(f"Failed to connect to MCP server: {server_name}")

            return connection

    async def disconnect(self, server_name: str) -> None:
        """Disconnect from an MCP server."""
        async with self._lock:
            if server_name in self._connections:
                await self._connections[server_name].disconnect()
                del self._connections[server_name]
                logger.info(f"Disconnected from MCP server: {server_name}")

    async def disconnect_all(self) -> None:
        """Disconnect from all MCP servers."""
        async with self._lock:
            for server_name in list(self._connections.keys()):
                await self._connections[server_name].disconnect()
            self._connections.clear()
            logger.info("Disconnected from all MCP servers")

    def get_connection(self, server_name: str) -> Optional[MCPConnection]:
        """Get an existing connection by server name."""
        return self._connections.get(server_name)

    def list_connections(self) -> List[MCPConnectionInfo]:
        """List all active connections."""
        return [conn.get_connection_info() for conn in self._connections.values()]

    async def get_tools(self, server_name: str) -> List[MCPTool]:
        """Get tools from a connected server."""
        connection = self._connections.get(server_name)
        if connection and connection.state == MCPConnectionState.CONNECTED:
            return connection.tools
        return []

    async def refresh_tools(self, server_name: str) -> List[MCPTool]:
        """Refresh and return tools from a connected server."""
        connection = self._connections.get(server_name)
        if connection and connection.state == MCPConnectionState.CONNECTED:
            return await connection.discover_tools()
        return []

    async def get_health(self, server_name: str) -> MCPHealthStatus:
        """Check health of a connected server."""
        connection = self._connections.get(server_name)

        if not connection:
            return MCPHealthStatus(
                server_name=server_name,
                is_healthy=False,
                state=MCPConnectionState.DISCONNECTED,
                error="Server not connected",
            )

        latency = await connection.ping()
        is_healthy = latency >= 0 and connection.state == MCPConnectionState.CONNECTED

        return MCPHealthStatus(
            server_name=server_name,
            is_healthy=is_healthy,
            state=connection.state,
            latency_ms=latency if latency >= 0 else None,
            last_ping=datetime.now().isoformat(),
            error=connection.error_message if not is_healthy else None,
        )

    async def call_tool(
        self,
        server_name: str,
        tool_name: str,
        arguments: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Call a tool on a connected server."""
        connection = self._connections.get(server_name)
        if not connection or connection.state != MCPConnectionState.CONNECTED:
            raise RuntimeError(f"Server {server_name} is not connected")

        return await connection.call_tool(tool_name, arguments)


# Global instance getter
def get_mcp_manager() -> MCPConnectionManager:
    """Get the global MCP connection manager instance."""
    return MCPConnectionManager.get_instance()
