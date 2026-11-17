"""长期记忆（跨会话）：谁在用这个助手，下次记得。

与短期记忆（checkpointer 存会话内消息）不同，这里存的是**关于用户本人的稳定事实**：
备考方向、提问偏好、复习进度。按 userId 用 namespace 隔离，跨会话、跨重启语义
（开发后端 InMemoryStore 例外——它重启会丢，换 PostgresStore 才是真持久）。

设计要点：
  - 读（召回）：每次对话开始，把该用户最近几条记忆拼进用户消息头部，
    用明确标记防止模型当成用户自己说的话。将来可升级 dynamic_prompt 注入 system prompt。
  - 写（提取）：**响应发出之后**在后台线程跑——把本轮问答发给模型提取值得长期记的
    事实，同步做的话用户每轮都要多等一次模型调用的延迟。
  - 克制：模型被要求只输出「新信息、不重复、不矛盾」的条目，没有就返回 []，
    记忆库膨胀或新旧打架会让检索质量越来越差。
  - 边界：只有登录用户（access_token 能解析出 userId）才启用；匿名会话完全不记忆。
"""
from __future__ import annotations

import json
import threading
import time
import uuid

import httpx
from langgraph.store.memory import InMemoryStore

from app.config import Settings

# 模块级单例。开发期 InMemoryStore；将来换 langgraph.store.postgres.PostgresStore，
# 本文件之外的代码一行不用改——这正是官方把 store 做成独立抽象的意义。
_STORE = InMemoryStore()

_NS_PREFIX = "users"

# 长期记忆条目允许的类别，提取 prompt 与前端展示共用
CATEGORIES = ("goal", "preference", "progress")

_EXTRACT_SYSTEM = """你是记忆提取器。从这轮问答里挑出「值得跨会话长期记住的用户稳定信息」。
只允许三类：goal（学习目标/备考方向）、preference（回答偏好/习惯）、progress（复习进度/已掌握内容）。
规则：
- 只提取用户明确表达或问答中确凿反映的信息，不许推测；
- 太琐碎的、一次性的（比如某个具体知识点的小问题）不要记；
- 与常识重复或互相矛盾的旧信息不要记；
- 没有值得记的就输出空数组。
输出 JSON 数组，每项 {"category": "goal|preference|progress", "text": "一句话"}，不要输出别的。"""


def _ns(user_id: str):
    return (_NS_PREFIX, str(user_id), "study")


def recall(user_id: str | None, limit: int = 5) -> str:
    """召回某用户的长期记忆，拼成可注入的文本块；没有记忆返回空串。"""
    if not user_id:
        return ""
    try:
        items = list(_STORE.search(_ns(user_id)))
    except Exception:
        return ""
    if not items:
        return ""
    # 按我们自己写入的 ts 倒序，取最近 limit 条
    entries = sorted(
        (it.value for it in items if isinstance(it.value, dict) and it.value.get("text")),
        key=lambda v: v.get("ts", 0),
        reverse=True,
    )[:limit]
    if not entries:
        return ""
    lines = [f"- [{e.get('category', 'note')}] {e['text']}" for e in entries]
    return (
        "[系统提示：以下是该用户此前的长期记忆，供你参考上下文，"
        "不要主动复述，也不要当成用户本轮说的话]\n" + "\n".join(lines) + "\n[记忆结束]"
    )


def remember(user_id: str | None, entries: list[dict]) -> int:
    """写入若干条长期记忆，返回成功条数。非法条目直接丢弃。"""
    if not user_id or not entries:
        return 0
    written = 0
    for e in entries:
        if not isinstance(e, dict):
            continue
        text = str(e.get("text") or "").strip()
        category = str(e.get("category") or "note")
        if not text or category not in CATEGORIES:
            continue
        _STORE.put(
            _ns(user_id),
            key=uuid.uuid4().hex,
            value={"text": text, "category": category, "ts": time.time()},
        )
        written += 1
    return written


def parse_facts(raw: str) -> list[dict]:
    """把模型的 JSON 输出解析成条目列表；输出不合法就返回空列表，绝不抛异常。"""
    text = (raw or "").strip()
    # 模型偶尔包一层 ```json 代码块，剥掉
    if text.startswith("```"):
        text = text.strip("`")
        if text.startswith("json"):
            text = text[4:]
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return []
    return data if isinstance(data, list) else []


def _call_model(question: str, answer: str, settings: Settings) -> str:
    payload = {
        "model": settings.deepseek_model,
        "messages": [
            {"role": "system", "content": _EXTRACT_SYSTEM},
            {
                "role": "user",
                "content": f"【本轮用户提问】\n{question[:1000]}\n\n【助手回答】\n{answer[:2000]}",
            },
        ],
        "stream": False,
    }
    kwargs: dict = {"timeout": 20.0, "trust_env": False}
    # 提取器固定用平台 key，不走用户 key：用户 key 可能失效，不能因此中断记忆
    headers = {"Authorization": f"Bearer {settings.deepseek_api_key}"}
    with httpx.Client(**kwargs) as client:
        resp = client.post(
            settings.deepseek_base_url.rstrip("/") + "/chat/completions",
            json=payload,
            headers=headers,
        )
        resp.raise_for_status()
        return resp.json()["choices"][0]["message"]["content"]


def extract_and_remember(
    user_id: str | None, question: str, answer: str, settings: Settings
) -> None:
    """后台任务入口：提取本轮值得记的事实并写回。任何失败都静默吞掉。"""
    if not user_id or not settings.memory_long_term_enabled:
        return
    if not settings.has_deepseek:
        return
    try:
        raw = _call_model(question, answer, settings)
        written = remember(user_id, parse_facts(raw))
        if written:
            print(f"[long_memory] user={user_id} wrote {written} facts")
    except Exception as exc:  # 记忆写失败不能影响下一次对话
        print(f"[long_memory] extract failed: {type(exc).__name__}: {exc}")


def extract_in_background(
    user_id: str | None, question: str, answer: str, settings: Settings
) -> None:
    """在 daemon 线程里跑提取——响应已经发出去了，这里慢一点无所谓。"""
    threading.Thread(
        target=extract_and_remember,
        args=(user_id, question, answer, settings),
        daemon=True,
    ).start()
