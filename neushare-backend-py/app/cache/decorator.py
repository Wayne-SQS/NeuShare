"""@cached decorator — Redis-backed read cache with graceful degradation.

When Redis is unavailable, every cache_get returns None and cache_set is a no-op,
so decorated functions behave exactly as if uncached. This lets the backend run
cache-degraded without Redis while speeding up automatically once Redis is present.

Values are JSON-serialized; decorate functions that already return JSON-safe VO
dicts (with datetimes pre-formatted to strings).
"""
import functools
import json
import logging

from app.db import redis as redis_db

log = logging.getLogger("cache")


def cached(key, ttl: int = 300):
    """key: either a string or a callable(*args, **kwargs) -> str."""
    def decorator(fn):
        @functools.wraps(fn)
        async def wrapper(*args, **kwargs):
            cache_key = key(*args, **kwargs) if callable(key) else key
            try:
                raw = await redis_db.cache_get(cache_key)
                if raw is not None:
                    return json.loads(raw)
            except Exception:  # noqa: BLE001
                pass
            result = await fn(*args, **kwargs)
            try:
                await redis_db.cache_set(cache_key, json.dumps(result, ensure_ascii=False, default=str), ttl)
            except Exception:  # noqa: BLE001
                pass
            return result
        return wrapper
    return decorator
