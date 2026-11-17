"""用户自带 key（BYOK）：从 Java 后端取当前用户配置的 AI key。

数据流：
  前端把用户 JWT 放进 ChatRequest.access_token
  → 这里带着同一个 Authorization 头调 Java 后端 GET /api/ai/config/internal
  → Java 侧 JwtInterceptor 校验 token，返回该用户解密后的 key（未配置为 ""）
  → 拿不到 / 没填 / 后端没起：一律返回 None，调用方降级平台 key。

缓存：同一 token 60 秒内复用结果，避免每条消息都打一次后端。
失败策略：永远不抛异常出去——BYOK 只是增强，坏了也不能影响基本对话。
"""
from __future__ import annotations

import time

import httpx

from app.config import Settings

_TTL_SECONDS = 60.0
_CACHE_MAX = 256

# token -> (取到时间, keys 或 None)
_CACHE: dict[str, tuple[float, dict | None]] = {}


def get_user_keys(settings: Settings, access_token: str) -> dict | None:
    """返回 {"user_id", "deepseek_key", "tavily_key"}；拿不到返回 None。"""
    token = access_token.strip()
    if not token:
        return None

    now = time.monotonic()
    hit = _CACHE.get(token)
    if hit and now - hit[0] < _TTL_SECONDS:
        return hit[1]

    keys = _fetch(settings, token)
    if len(_CACHE) >= _CACHE_MAX:
        _CACHE.clear()  # 简单防膨胀：全清，下轮重新拉
    _CACHE[token] = (now, keys)
    return keys


def _fetch(settings: Settings, token: str) -> dict | None:
    url = settings.neushare_api_base.rstrip("/") + "/api/ai/config/internal"
    try:
        with httpx.Client(timeout=5.0, trust_env=False) as client:
            resp = client.get(url, headers={"Authorization": f"Bearer {token}"})
    except Exception:
        return None  # 后端没起 / 超时：降级平台 key

    if resp.status_code != 200:
        return None  # 401 = token 过期，让用户重新登录后自然恢复
    try:
        body = resp.json()
    except Exception:
        return None
    if body.get("code") != 200 or not body.get("data"):
        return None

    data = body["data"]
    return {
        "user_id": data.get("userId"),
        "deepseek_key": data.get("deepseekKey") or "",
        "tavily_key": data.get("tavilyKey") or "",
    }
