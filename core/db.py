"""
core/db.py — Database connection and session handling.

Rule (LD-03 §2): every service imports the session factory from here.
No service creates its own engine or connection pool.

Expects DATABASE_URL in environment (postgres:// or postgresql+asyncpg://).
"""
import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Shared declarative base for all ORM models."""


def _build_url() -> str:
    url = os.environ.get("DATABASE_URL", "")
    if not url:
        raise RuntimeError(
            "DATABASE_URL is not set. "
            "Set it to your Supabase connection string, e.g.:\n"
            "  postgresql+asyncpg://user:pass@host:5432/postgres"
        )
    # Supabase connection strings often start with postgres:// — SQLAlchemy
    # async driver needs postgresql+asyncpg://
    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+asyncpg://", 1)
    elif url.startswith("postgresql://") and "+asyncpg" not in url:
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
    return url


engine = None
_SessionFactory: async_sessionmaker[AsyncSession] | None = None


def init_db() -> None:
    """Call once at application startup (in FastAPI lifespan)."""
    global engine, _SessionFactory
    engine = create_async_engine(
        _build_url(),
        pool_size=5,
        max_overflow=10,
        pool_pre_ping=True,
        echo=os.environ.get("DB_ECHO", "").lower() == "true",
    )
    _SessionFactory = async_sessionmaker(
        engine,
        expire_on_commit=False,
        class_=AsyncSession,
    )


@asynccontextmanager
async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """Async context manager for a database session.

    Usage:
        async with get_session() as session:
            result = await session.execute(...)
    """
    if _SessionFactory is None:
        raise RuntimeError("Database not initialised — call init_db() first.")
    async with _SessionFactory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
