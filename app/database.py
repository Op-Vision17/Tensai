"""Tensai — Async SQLAlchemy engine and session for Supabase PostgreSQL (asyncpg)."""

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import get_settings


class Base(DeclarativeBase):
    """Declarative base for all models."""


def _get_asyncpg_url() -> str:
    """Convert DATABASE_URL to postgresql+asyncpg:// format (Supabase PostgreSQL only)."""
    url = get_settings().database_url.strip()
    if not url:
        raise ValueError("DATABASE_URL is required (Supabase PostgreSQL connection string)")
    if url.startswith("postgres://"):
        url = "postgresql://" + url[10:]
    if not url.startswith("postgresql://"):
        raise ValueError("DATABASE_URL must be a PostgreSQL URL (postgres:// or postgresql://)")
    if "+asyncpg" not in url:
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
    return url


_async_url = _get_asyncpg_url()
_engine = create_async_engine(
    _async_url,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    echo=False,
)
AsyncSessionLocal = async_sessionmaker(
    bind=_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency: yield async session, close after request."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db() -> None:
    """Create all tables (Base.metadata.create_all)."""
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
