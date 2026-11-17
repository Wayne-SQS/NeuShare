"""BYOK（用户自带 key）测试：只测不需要真调模型的降级与缓存行为。

跑法（在 neushare-ai/ 目录下）：pytest -q tests/test_byok.py
"""
from __future__ import annotations

import os

os.environ["MOCK_MODE"] = "true"  # 必须在 import app 之前设置

from app.config import get_settings  # noqa: E402
from app.user_keys import get_user_keys  # noqa: E402


def test_empty_token_returns_none():
    """没带 token = 普通请求，直接走平台 key，不打后端。"""
    s = get_settings()
    assert get_user_keys(s, "") is None
    assert get_user_keys(s, "   ") is None


def test_backend_down_degrades_to_none():
    """token 非空但 Java 后端没起：返回 None 降级平台 key，绝不抛异常。"""
    keys = get_user_keys(get_settings(), "not-a-real-token-backend-down")
    assert keys is None


def test_cache_avoids_refetch(monkeypatch):
    """同一 token 60 秒内复用结果，不重复打后端。"""
    import app.user_keys as uk

    calls = {"n": 0}

    def fake_fetch(settings, token):
        calls["n"] += 1
        return {"user_id": 7, "deepseek_key": "sk-test", "tavily_key": ""}

    monkeypatch.setattr(uk, "_fetch", fake_fetch)
    s = get_settings()
    first = uk.get_user_keys(s, "tok-cache-test")
    second = uk.get_user_keys(s, "tok-cache-test")
    assert first == second == {"user_id": 7, "deepseek_key": "sk-test", "tavily_key": ""}
    assert calls["n"] == 1
