"""上下文窗口保护的单测：只验证装配与配置，不发任何模型请求。"""
from __future__ import annotations

from langchain.agents.middleware import ContextEditingMiddleware, SummarizationMiddleware
from langchain_core.language_models.fake_chat_models import FakeListChatModel

from app.config import Settings
from app.memory import SUMMARY_PROMPT, build_memory_middleware

# 传模型对象而不是 "deepseek:xxx" 字符串：字符串会让中间件再解析一次模型并去找 API key。
# 假模型只用于验证装配，不发任何请求。
MODEL = FakeListChatModel(responses=["summary", "answer"])


def test_default_policy_is_enabled_and_readable():
    s = Settings(_env_file=None)
    assert s.memory_enabled is True
    assert s.memory_max_messages > s.memory_keep_recent  # 触发阈值必须大于保留条数
    assert "summary@" in s.memory_policy


def test_can_be_disabled():
    s = Settings(_env_file=None, memory_enabled=False)
    assert build_memory_middleware(MODEL, s) == []
    assert s.memory_policy == "disabled"


def test_default_only_summarization_no_destructive_edit():
    """默认策略：只有归纳式压缩，不开直接删原文的可选层（信息保真优先）。"""
    s = Settings(_env_file=None)
    assert s.memory_clear_tool_enabled is False
    mws = build_memory_middleware(MODEL, s)
    assert len(mws) == 1
    assert isinstance(mws[0], SummarizationMiddleware)


def test_clear_tool_layer_only_when_opted_in():
    """显式开启后才有清旧工具输出层，且在摘要之前。"""
    s = Settings(_env_file=None, memory_clear_tool_enabled=True)
    mws = build_memory_middleware(MODEL, s)
    assert len(mws) == 2
    assert isinstance(mws[0], ContextEditingMiddleware)
    assert isinstance(mws[1], SummarizationMiddleware)


def test_summary_prompt_keeps_placeholder_and_no_fabrication_rule():
    assert "{messages}" in SUMMARY_PROMPT
    assert "不许" in SUMMARY_PROMPT and "来源" in SUMMARY_PROMPT
    # 用户要求强制保留的三类内容必须在归纳清单里
    for keyword in ("任务目标", "产物", "新要求", "归纳"):
        assert keyword in SUMMARY_PROMPT, f"摘要 prompt 缺少关键词：{keyword}"


def test_health_exposes_memory_policy():
    from fastapi.testclient import TestClient

    from app.main import app

    body = TestClient(app).get("/api/ai/health").json()
    assert "memory_policy" in body
    assert body["memory_policy"]
