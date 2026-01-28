"""
Web operation tools.

This module provides tools for fetching web content
and performing web searches.
"""

import re
from typing import Any, Dict, Optional
from urllib.parse import urlparse

import httpx

from .base import Tool, ToolCategory, ToolContext, ToolResult, register_tool


class WebFetchTool(Tool):
    """Fetch content from a URL."""

    name = "web_fetch"
    description = (
        "Fetch content from a URL and return the text. "
        "HTML is converted to plain text."
    )
    category = ToolCategory.WEB
    requires_permission = False

    @property
    def input_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "url": {
                    "type": "string",
                    "description": "The URL to fetch content from",
                },
                "prompt": {
                    "type": "string",
                    "description": "What to extract or focus on from the page",
                },
                "timeout": {
                    "type": "integer",
                    "description": "Request timeout in seconds (default: 30)",
                },
            },
            "required": ["url"],
        }

    def _is_url_safe(self, url: str) -> Optional[str]:
        """
        Check if a URL is safe to fetch.

        Args:
            url: URL to check

        Returns:
            Error message if unsafe, None if safe
        """
        try:
            parsed = urlparse(url)
        except Exception:
            return "Invalid URL format"

        # Only allow http and https
        if parsed.scheme not in ("http", "https"):
            return f"Unsupported URL scheme: {parsed.scheme}"

        # Block localhost and private IPs
        host = parsed.hostname or ""
        if host in ("localhost", "127.0.0.1", "0.0.0.0"):
            return "Cannot fetch from localhost"

        # Block private IP ranges
        if host.startswith("192.168.") or host.startswith("10.") or host.startswith("172."):
            return "Cannot fetch from private IP addresses"

        return None

    def _html_to_text(self, html: str) -> str:
        """
        Convert HTML to plain text.

        Args:
            html: HTML content

        Returns:
            Plain text content
        """
        # Remove script and style elements
        html = re.sub(r"<script[^>]*>[\s\S]*?</script>", "", html, flags=re.IGNORECASE)
        html = re.sub(r"<style[^>]*>[\s\S]*?</style>", "", html, flags=re.IGNORECASE)

        # Convert common block elements to newlines
        html = re.sub(r"<(p|div|br|h[1-6]|li|tr)[^>]*>", "\n", html, flags=re.IGNORECASE)

        # Remove remaining tags
        html = re.sub(r"<[^>]+>", "", html)

        # Decode HTML entities
        html = html.replace("&nbsp;", " ")
        html = html.replace("&amp;", "&")
        html = html.replace("&lt;", "<")
        html = html.replace("&gt;", ">")
        html = html.replace("&quot;", '"')
        html = html.replace("&#39;", "'")

        # Normalize whitespace
        html = re.sub(r"\n\s*\n", "\n\n", html)
        html = re.sub(r" +", " ", html)

        return html.strip()

    async def execute(
        self,
        arguments: Dict[str, Any],
        context: ToolContext,
    ) -> ToolResult:
        url = arguments["url"]
        prompt = arguments.get("prompt", "")
        timeout = arguments.get("timeout", 30)

        # Validate URL
        safety_error = self._is_url_safe(url)
        if safety_error:
            return ToolResult.error_result(f"URL blocked: {safety_error}")

        try:
            async with httpx.AsyncClient(
                timeout=timeout,
                follow_redirects=True,
                headers={
                    "User-Agent": "Mozilla/5.0 (compatible; NewWork/1.0)"
                },
            ) as client:
                response = await client.get(url)
                response.raise_for_status()

                content_type = response.headers.get("content-type", "")

                if "text/html" in content_type:
                    text = self._html_to_text(response.text)
                elif "text/" in content_type or "application/json" in content_type:
                    text = response.text
                else:
                    return ToolResult.error_result(
                        f"Unsupported content type: {content_type}"
                    )

                # Truncate if too long
                max_length = 50000
                if len(text) > max_length:
                    text = text[:max_length] + f"\n... (truncated, total {len(text)} chars)"

                output = f"Content from {url}:\n\n{text}"

                if prompt:
                    output = f"[Query: {prompt}]\n\n{output}"

                return ToolResult.success_result(
                    output,
                    url=url,
                    content_type=content_type,
                    content_length=len(text),
                )

        except httpx.TimeoutException:
            return ToolResult.error_result(f"Request timed out after {timeout} seconds")
        except httpx.HTTPStatusError as e:
            return ToolResult.error_result(f"HTTP error: {e.response.status_code}")
        except Exception as e:
            return ToolResult.error_result(f"Error fetching URL: {str(e)}")


class WebSearchTool(Tool):
    """Search the web using a search engine API."""

    name = "web_search"
    description = (
        "Search the web for information. "
        "Returns search results with titles and snippets."
    )
    category = ToolCategory.WEB
    requires_permission = False

    @property
    def input_schema(self) -> Dict[str, Any]:
        return {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "The search query",
                },
                "max_results": {
                    "type": "integer",
                    "description": "Maximum number of results (default: 10)",
                },
            },
            "required": ["query"],
        }

    async def execute(
        self,
        arguments: Dict[str, Any],
        context: ToolContext,
    ) -> ToolResult:
        query = arguments["query"]
        max_results = arguments.get("max_results", 10)

        # Note: In a real implementation, this would use a search API
        # (e.g., Google Custom Search, Bing Search, DuckDuckGo)
        # For now, return a placeholder indicating the feature needs API setup

        return ToolResult(
            success=True,
            output=(
                f"Web search for: '{query}'\n\n"
                "Note: Web search requires configuration of a search API. "
                "Please configure SEARCH_API_KEY in your environment to enable this feature.\n\n"
                "Supported search providers:\n"
                "- Google Custom Search API\n"
                "- Bing Search API\n"
                "- DuckDuckGo (via API)\n"
            ),
            metadata={
                "query": query,
                "status": "not_configured",
            },
        )


# Register web tools
def register_web_tools() -> None:
    """Register web operation tools."""
    register_tool(WebFetchTool())
    register_tool(WebSearchTool())
