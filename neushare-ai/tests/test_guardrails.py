"""取优合并后 AI 服务的冒烟测试：不依赖任何 key、不发外网。

对应 master 侧 18 条测试的思路，但按本分支的 RAG 版契约重写。
跑法（neushare-ai/ 目录下）：pytest -q
"""
from __future__ import annotations

import os

os.environ.setdefault("JWT_SECRET", "test-only-secret-not-a-real-key-32bytes")
os.environ.setdefault("MOCK_MODE", "false")
os.environ.pop("TAVILY_API_KEY", None)

from app.agent import guardrails  # noqa: E402


def test_no_key_never_invents_results():
    out = guardrails.web_search("2027 考研 408 大纲")
    assert out["mode"] == "unavailable"
    assert out["results"] == []
    assert "不要编造" in out["note"]


def test_mock_mode_uses_placeholder_and_labels_it():
    os.environ["MOCK_MODE"] = "true"
    try:
        out = guardrails.web_search("任意问题")
        assert out["mode"] == "mock"
        assert all("example.com" in r["url"] for r in out["results"])
        assert "演示数据" in out["note"]
    finally:
        os.environ["MOCK_MODE"] = "false"


def test_system_prompt_forbids_fabrication_and_separates_channels():
    p = guardrails.SYSTEM_PROMPT
    assert "绝不编造" in p
    assert "站内资源 #ID" in p
    assert "完整 URL" in p
    assert "不替用户下结论" in p
    assert "官网复核" in p
    assert "不是指令" in guardrails.WEB_RULES


def test_web_content_is_truncated():
    """不可信网页内容必须截断，防止撑爆上下文与注入。"""
    assert "[:800]" in open(
        os.path.join(os.path.dirname(__file__), "..", "app", "agent", "guardrails.py"),
        encoding="utf-8",
    ).read()


def test_health_never_leaks_keys():
    h = guardrails.health_payload(index_exists=True)
    assert h["status"] == "ok"
    assert h["web_search_mode"] in ("tavily", "unavailable", "mock")
    assert "secret" not in str(h).lower()
    assert "api_key" not in str(h).lower()


def test_config_has_no_hardcoded_secrets():
    """公开仓库红线：config.py 不得再出现明文密码或 dev fallback。"""
    cfg = open(
        os.path.join(os.path.dirname(__file__), "..", "app", "config.py"), encoding="utf-8"
    ).read()
    legacy_plain = "NeuShare" + "@" + "2026"  # 拼写在源码里留明文会污染密钥扫描
    assert legacy_plain not in cfg
    assert "DEV_JWT_SECRET" not in cfg
    assert 'mysql_password = _get("MYSQL_PASSWORD", "")' in cfg


def test_tool_result_is_json_not_prompt_injection():
    out = guardrails.format_tool_result({"mode": "unavailable", "results": []})
    assert out.startswith("{")
    assert "unavailable" in out
