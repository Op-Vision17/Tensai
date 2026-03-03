"""Tensai — FastAPI application entrypoint."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse

from app import retrieval
from app.config import get_settings
from app.database import init_db
from app.routers import ask, auth, history, ingest


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup: connect Pinecone index, ensure DB tables exist. Shutdown: log."""
    retrieval.get_index()
    await init_db()
    print("[tensai] Ready 🚀")
    yield
    print("[tensai] Shutting down")


app = FastAPI(
    title="Tensai — AI Study Copilot",
    description="Production-grade study assistant powered by GPT-4o and Pinecone",
    version="1.0.0",
    lifespan=lifespan,
)

app.include_router(auth.router)
app.include_router(history.router)
app.include_router(ask.router)
app.include_router(ingest.router)

app.add_middleware(CORSMiddleware, allow_origins=["*"])


@app.get("/", include_in_schema=False)
def root() -> RedirectResponse:
    """Redirect root to API docs."""
    return RedirectResponse(url="/docs")


@app.get("/health")
async def health() -> dict:
    """Health check with service name and configured chat model."""
    settings = get_settings()
    return {
        "status": "ok",
        "service": "tensai",
        "model": settings.chat_model,
    }


def start() -> None:
    """Run the app with uvicorn (entry point for poetry run start)."""
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=False)
