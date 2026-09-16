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

# Serverless mode: pool_size=1, no overflow, pgbouncer-compatible statement cache=0.
# Set SERVERLESS=1 in Vercel env vars; long-running servers leave it unset.
_IS_SERVERLESS = os.environ.get("SERVERLESS", "0") == "1"


def init_db() -> None:
    """Call once at application startup (in FastAPI lifespan for long-running servers).

    In serverless mode (SERVERLESS=1) this is called lazily inside get_session()
    on the first request — Vercel has no persistent process to run a lifespan hook.
    """
    global engine, _SessionFactory
    if _SessionFactory is not None:
        return   # already initialised (idempotent for lazy callers)

    connect_args: dict = {}
    if _IS_SERVERLESS:
        # Required for Supabase transaction pooler (pgbouncer in transaction mode):
        # prepared statements are not supported across connections.
        connect_args["statement_cache_size"] = 0

    engine = create_async_engine(
        _build_url(),
        pool_size=1 if _IS_SERVERLESS else 5,
        max_overflow=0 if _IS_SERVERLESS else 10,
        pool_pre_ping=True,
        connect_args=connect_args,
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

    Initialises the DB lazily when SERVERLESS=1 (Vercel) so callers don't
    need to call init_db() separately. Long-running servers still call init_db()
    at startup via the FastAPI lifespan hook.
    """
    if _SessionFactory is None:
        init_db()   # lazy init for serverless
    async with _SessionFactory() as session:  # type: ignore[union-attr]
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
