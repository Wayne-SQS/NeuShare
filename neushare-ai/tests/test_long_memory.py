"""长期记忆测试：召回格式、写入、JSON 解析，全部不依赖真模型调用。

跑法（在 neushare-ai/ 目录下）：pytest -q tests/test_long_memory.py
"""
from __future__ import annotations

import os

os.environ["MOCK_MODE"] = "true"  # 必须在 import app 之前设置

import pytest  # noqa: E402

from app.config import get_settings  # noqa: E402
from app.long_memory import parse_facts, recall, remember  # noqa: E402


@pytest.fixture(autouse=True)
def _unique_user(monkeypatch):
    """每个测试用独立的 userId，避免相互看到对方的记忆。"""
    import app.long_memory as lm

    user_id = f"test-user-{os.urandom(4).hex()}"
    yield user_id


def test_recall_without_user_id_returns_empty():
    assert recall(None) == ""
    assert recall("") == ""


def test_remember_then_recall_roundtrip():
    import app.long_memory as lm

    user = f"roundtrip-{os.urandom(4).hex()}"
    written = remember(user, [
        {"category": "goal", "text": "备考 2027 考研 408 与数学一"},
        {"category": "preference", "text": "回答偏好简短要点式"},
    ])
    assert written == 2
    text = recall(user, limit=5)
    assert "备考 2027 考研 408" in text
    assert "简短要点式" in text
    # 注入块带明确的边界标记，防止模型当成用户说的话
    assert text.startswith("[系统提示")
    assert text.endswith("[记忆结束]")


def test_remember_rejects_bad_entries():
    import app.long_memory as lm

    user = f"bad-{os.urandom(4).hex()}"
    assert remember(user, [
        {"category": "hacker", "text": "非法类别被拒"},
        {"category": "goal", "text": ""},
        "not-a-dict",
    ]) == 0
    assert recall(user) == ""


def test_parse_facts_handles_model_outputs():
    # 正常 JSON
    assert parse_facts('[{"category":"goal","text":"考研"}]') == [
        {"category": "goal", "text": "考研"}
    ]
    # 包了 ```json 代码块
    assert parse_facts('```json\n[{"category":"progress","text":"第6章"}]\n```') == [
        {"category": "progress", "text": "第6章"}
    ]
    # 非法输出一律空列表，不抛异常
    assert parse_facts("模型说了一段话没有 JSON") == []
    assert parse_facts("") == []
    assert parse_facts("[]") == []


def test_extract_disabled_without_key(monkeypatch):
    """没配 DeepSeek key 时后台提取直接返回，绝不发请求。"""
    import app.long_memory as lm

    called = {"n": 0}
    monkeypatch.setattr(lm, "_call_model", lambda q, a, s: called.__setitem__("n", called["n"] + 1))

    settings = get_settings().model_copy(update={"deepseek_api_key": ""})
    lm.extract_and_remember("some-user", "问", "答", settings)
    assert called["n"] == 0
