"""
NewWork API main application.

This is the entry point for the FastAPI backend that provides
AI-powered coding assistance through multiple LLM providers.
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging

from app.services.config_service import settings, ConfigService
from app.db.database import init_db
from app.tools import initialize_tools
from app.services.llm import close_all_providers

# Import routers
from app.api import (
    sessions,
    templates,
    skills,
    plugins,
    mcp,
    workspaces,
    permissions,
    providers,
    files,
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="FastAPI backend for NewWork - AI-powered coding assistant with multi-provider support",
    debug=settings.DEBUG,
)

# Configure CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize services on application startup."""
    logger.info("Starting NewWork API...")

    # Initialize database
    init_db()
    logger.info("Database initialized successfully")

    # Initialize tools
    initialize_tools()
    logger.info("Tool system initialized")

    # Check configured providers
    available_providers = ConfigService.get_available_providers()
    if available_providers:
        logger.info(f"Available LLM providers: {', '.join(available_providers)}")
        logger.info(f"Default provider: {ConfigService.get_default_provider()}")
        logger.info(f"Default model: {ConfigService.get_default_model()}")
    else:
        logger.warning("No LLM providers configured. Set API keys in environment.")

    logger.info("NewWork API started successfully")


# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on application shutdown."""
    logger.info("Shutting down NewWork API...")

    # Close LLM provider connections
    await close_all_providers()
    logger.info("LLM providers closed")

    logger.info("NewWork API shutdown complete")


# Health check endpoint
@app.get("/health")
async def health_check():
    """
    Health check endpoint.

    Returns:
        JSON response with health status and provider info
    """
    available_providers = ConfigService.get_available_providers()

    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "providers": {
            "available": available_providers,
            "default": ConfigService.get_default_provider(),
        },
    }


# Root endpoint
@app.get("/")
async def root():
    """
    Root endpoint with API information.

    Returns:
        JSON response with API info
    """
    return {
        "message": "NewWork API",
        "version": settings.APP_VERSION,
        "description": "AI-powered coding assistant with multi-provider support",
        "docs": "/docs",
        "health": "/health",
        "providers": ConfigService.get_available_providers(),
    }


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle unhandled exceptions."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "error": str(exc) if settings.DEBUG else "An unexpected error occurred",
        },
    )


# Include routers with /api/v1 prefix
API_V1_PREFIX = "/api/v1"
app.include_router(sessions.router, prefix=API_V1_PREFIX)
app.include_router(templates.router, prefix=API_V1_PREFIX)
app.include_router(skills.router, prefix=API_V1_PREFIX)
app.include_router(plugins.router, prefix=API_V1_PREFIX)
app.include_router(mcp.router, prefix=API_V1_PREFIX)
app.include_router(workspaces.router, prefix=API_V1_PREFIX)
app.include_router(permissions.router, prefix=API_V1_PREFIX)
app.include_router(providers.router, prefix=API_V1_PREFIX)
app.include_router(files.router, prefix=API_V1_PREFIX)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app", host=settings.HOST, port=settings.PORT, reload=settings.DEBUG
    )
