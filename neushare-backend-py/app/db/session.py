"""Async SQLAlchemy 2.0 engine + session factory (asyncmy driver)."""
import logging
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings

log = logging.getLogger("db")

engine = create_async_engine(
    settings.db_url,
    echo=False,
    pool_pre_ping=True,
    pool_size=10,
    max_overflow=20,
    pool_recycle=3600,
)

AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False, autoflush=False)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session


async def verify_connection() -> bool:
    try:
        async with engine.connect() as conn:
            await conn.exec_driver_sql("SELECT 1")
        log.info("mysql connection OK: %s:%s/%s", settings.mysql_host, settings.mysql_port, settings.mysql_db)
        return True
    except Exception as e:  # noqa: BLE001
        log.error("mysql connection FAILED: %s", e)
        return False
