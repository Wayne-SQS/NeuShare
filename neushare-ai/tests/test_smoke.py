"""无 key 冒烟测试：只测不依赖外网的部分。

跑法（在 neushare-ai/ 目录下）：
    pytest -q
"""
from __future__ import annotations

import json
import os

os.environ["MOCK_MODE"] = "true"  # 必须在 import app 之前设置

from fastapi.testclient import TestClient  # noqa: E402

from app.config import Settings, get_settings  # noqa: E402
from app.main import app  # noqa: E402
from app.tools.web_search import build_web_search_tool  # noqa: E402

client = TestClient(app)


def test_health_reports_config_without_leaking_keys():
    r = client.get("/api/ai/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert "deepseek_configured" in body and "web_search_mode" in body
    assert "api_key" not in json.dumps(body).lower()


def test_web_search_mock_returns_placeholder_not_fake_links():
    r = client.get("/api/ai/web-search", params={"q": "2027 考研 408 考试大纲"})
    assert r.status_code == 200
    body = r.json()
    assert body["query"] == "2027 考研 408 考试大纲"
    assert body["mode"] in ("mock", "unavailable")
    if body["mode"] == "mock":
        assert all("example.com" in hit["url"] for hit in body["results"])


def test_unconfigured_search_never_invents_results():
    s = Settings(tavily_api_key="", mock_mode=False)
    out = json.loads(build_web_search_tool(s).invoke({"query": "东北大学软件学院 招生简章"}))
    assert out["mode"] == "unavailable"
    assert out["results"] == []
    assert "不要编造" in out["note"]


def test_rate_limit_rejects_burst():
    # 单独用一个极小限额验证 429 分支，不动全局配置
    import app.routers.chat as chat_mod

    assert chat_mod._allow("smoke-burst", 1) is True
    assert chat_mod._allow("smoke-burst", 1) is False


def test_settings_defaults_are_safe():
    s = get_settings()
    assert s.deepseek_model == "deepseek-chat"
    assert s.tavily_max_results >= 1
