"""FastAPI application factory."""

from fastapi import FastAPI

from .routes import router


def create_app() -> FastAPI:
    """Create and configure the FastAPI application.

    Returns:
        Configured FastAPI application instance.
    """
    app = FastAPI(
        title="Example API",
        description="A minimal FastAPI example",
        version="1.0.0",
    )

    app.include_router(router)

    return app


# Application instance for uvicorn
app = create_app()
