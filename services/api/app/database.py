from collections.abc import AsyncIterator, Awaitable, Callable

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine

from app.config import get_settings

DatabaseProbe = Callable[[], Awaitable[None]]

_engine: AsyncEngine | None = None


def get_engine() -> AsyncEngine:
    global _engine
    if _engine is None:
        _engine = create_async_engine(get_settings().database_url, pool_pre_ping=True)
    return _engine


async def check_database() -> None:
    async with get_engine().connect() as connection:
        await connection.execute(text("SELECT 1"))


def get_database_probe() -> DatabaseProbe:
    return check_database


async def dispose_engine() -> None:
    global _engine
    if _engine is not None:
        await _engine.dispose()
        _engine = None


async def database_lifespan() -> AsyncIterator[None]:
    try:
        yield
    finally:
        await dispose_engine()
