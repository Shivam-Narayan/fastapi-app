import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI, Response, status
from fastapi.middleware.cors import CORSMiddleware
from logger import configure_logging
from routes.route_handler import all_routers
from utils.middleware import AuthMiddleware
from __init__ import __version__

load_dotenv()
logger = configure_logging(__name__)


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="fastAPI",
        description="API and routes available in backend",
        version=__version__,
    )

    app.add_middleware(AuthMiddleware)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    all_routers(app)

    @app.on_event("startup")
    async def startup_event() -> None:
        logger.info("Logger is configured.")

    @app.on_event("shutdown")
    async def shutdown_event() -> None:
        logger.info("Server is shutting down.")

    @app.get("/")
    async def root() -> dict[str, str]:
        return {"message": "App API is running"}

    @app.get("/health")
    async def health_check() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/favicon.ico")
    async def favicon() -> Response:
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    return app


app = create_app()


def start_server(host: str | None = None, port: int | None = None) -> None:
    """Start the server."""
    uvicorn.run(
        "main:app",
        host=host or "0.0.0.0",
        port=port or 8000,
        reload=True,
        timeout_keep_alive=120,
        limit_concurrency=1000,
        limit_max_requests=10000,
        h11_max_incomplete_event_size=4194304,
    )


if __name__ == "__main__":
    start_server()
