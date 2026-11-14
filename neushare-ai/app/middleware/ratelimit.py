"""In-memory sliding-window rate limiter keyed by user id (per minute)."""
import time
from collections import defaultdict, deque
from app.config import settings

_buckets: dict[int, deque] = defaultdict(deque)
_WINDOW = 60.0


def is_allowed(user_id: int) -> bool:
    now = time.time()
    q = _buckets[user_id]
    while q and q[0] <= now - _WINDOW:
        q.popleft()
    if len(q) >= settings.rate_limit_per_minute:
        return False
    q.append(now)
    return True
