"""Async Redis client with graceful degradation.

When REDIS_URL is empty or Redis is unreachable, the client stays None and all
cache helpers become no-ops so the backend keeps serving requests (cache-degraded).
This keeps the API fully functional without Redis; performance caching activates
automatically once Redis is available.
"""
import logging
from typing import Optional

from app.core.config import settings

log = logging.getLogger("redis")

_redis: Optional[object] = None


async def init_redis():
    global _redis
    if not settings.redis_url:
        log.info("REDIS_URL empty — running in cache-degraded mode (no caching).")
        return None
    try:
        import redis.asyncio as aioredis
        client = aioredis.from_url(settings.redis_url, decode_responses=True,
                                   socket_connect_timeout=2, socket_timeout=2)
        await client.ping()
        _redis = client
        log.info("redis connected: %s", settings.redis_url)
        return client
    except Exception as e:  # noqa: BLE001
        log.warning("redis unavailable, running cache-degraded: %s", e)
        _redis = None
        return None


async def close_redis():
    global _redis
    if _redis is not None:
        try:
            await _redis.close()
        except Exception:  # noqa: BLE001
            pass
        _redis = None


def get_redis():
    return _redis


async def cache_get(key: str):
    r = _redis
    if r is None:
        return None
    try:
        return await r.get(key)
    except Exception:  # noqa: BLE001
        return None


async def cache_set(key: str, value, ttl: int = 300) -> bool:
    r = _redis
    if r is None:
        return False
    try:
        await r.setex(key, ttl, value if isinstance(value, str) else str(value))
        return True
    except Exception:  # noqa: BLE001
        return False


async def cache_delete(key: str) -> bool:
    r = _redis
    if r is None:
        return False
    try:
        await r.delete(key)
        return True
    except Exception:  # noqa: BLE001
        return False
