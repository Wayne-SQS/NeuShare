"""AI 接口。

POST /api/ai/chat        —— 对话。stream=true 走 SSE，false 一次性返回
GET  /api/ai/web-search  —— 单独调 Tavily，给前端「联网搜索」tab / 调试用
GET  /api/ai/health      —— 看当前到底有没有 key、联网是真是假

SSE 事件：
  event: token   data: {"text":"..."}          逐段正文
  event: tool    data: {"name":"...","status":"done"}   工具调用完成
  event: source  data: {"type":"web|platform", ...}     来源卡片
  event: error   data: {"message":"..."}
  event: done    data: {"session_id":"..."}
"""
from __future__ import annotations

import json
import time
from collections import defaultdict, deque
from typing import Iterator

from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import StreamingResponse
from langchain_core.messages import AIMessageChunk, ToolMessage

from app.agent import AgentNotReady, get_agent, get_agent_for_user_keys
from app.config import Settings, get_settings
from app.long_memory import extract_in_background, recall
from app.schemas import ChatRequest, ChatResponse, HealthResponse, WebSearchResponse
from app.tools.web_search import build_web_search_tool, parse_sources
from app.user_keys import get_user_keys

router = APIRouter(prefix="/api/ai", tags=["ai"])

# 内存滑动窗口限流。单进程够用；多副本部署要换成 Redis，别把这个当分布式方案讲。
_windows: dict[str, deque] = defaultdict(deque)


def _allow(key: str, limit: int) -> bool:
    now = time.monotonic()
    q = _windows[key]
    while q and q[0] < now - 60:
        q.popleft()
    if len(q) >= limit:
        return False
    q.append(now)
    return True


def _sse(event: str, data: dict) -> str:
    return f"event: {event}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"


def _stream(
    agent,
    payload: dict,
    raw_question: str,
    thread_id: str,
    user_id: str | None,
    settings: Settings,
    session_id: str,
) -> Iterator[str]:
    cfg = {"configurable": {"thread_id": thread_id}}
    collected: list[str] = []
    try:
        for event in agent.stream(payload, config=cfg, stream_mode="messages"):
            # LangGraph 1.x 给的是 (message_chunk, metadata)；兼容直接给 message 的情况
            chunk = event[0] if isinstance(event, tuple) and event else event
            if isinstance(chunk, AIMessageChunk):
                content = chunk.content
                if isinstance(content, str) and content:
                    collected.append(content)
                    yield _sse("token", {"text": content})
                elif isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "text" and block.get("text"):
                            collected.append(block["text"])
                            yield _sse("token", {"text": block["text"]})
            elif isinstance(chunk, ToolMessage):
                yield _sse("tool", {"name": chunk.name, "status": "done"})
                for source in parse_sources(chunk.content):
                    yield _sse("source", source)
    except Exception as exc:  # 流已经开了，不能抛异常，只能发 error 事件
        yield _sse("error", {"message": f"{type(exc).__name__}: {exc}"})
    finally:
        # 响应已经全部发出，现在才在后台提取长期记忆——读在请求路径，写在后台
        answer = "".join(collected)
        if user_id and answer:
            extract_in_background(user_id, raw_question, answer, settings)
        yield _sse("done", {"session_id": session_id})


@router.post("/chat")
def chat(req: ChatRequest, request: Request):
    settings = get_settings()
    if not _allow(req.session_id or request.client.host, settings.rate_limit_per_minute):
        raise HTTPException(status_code=429, detail="请求过于频繁，请稍后再试")

    # BYOK：带 token 且用户配了自己的 DeepSeek key 就用他的，否则降级平台 key。
    keys = get_user_keys(settings, req.access_token)
    using_byok = bool(keys and keys["deepseek_key"])
    try:
        if using_byok:
            agent = get_agent_for_user_keys(
                settings, keys["deepseek_key"], keys["tavily_key"] or settings.tavily_api_key
            )
        else:
            agent = get_agent(settings)
    except AgentNotReady as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    thread_id = f"u{keys['user_id']}:{req.session_id}" if using_byok else req.session_id

    # 长期记忆：只有登录用户启用。随 state 传给 agent，由 dynamic_prompt 拼进
    # system prompt——不进消息历史，不会逐轮膨胀。提取写在响应发出之后（后台线程）。
    long_term = ""
    if user_id and settings.memory_long_term_enabled:
        long_term = recall(user_id, settings.memory_long_term_max_inject)

    cfg = {"configurable": {"thread_id": thread_id}}
    payload: dict = {"messages": [{"role": "user", "content": req.question}]}
    if long_term:
        payload["long_term_memory"] = long_term

    if req.stream:
        return StreamingResponse(
            _stream(agent, payload, req.question, thread_id, user_id, settings, req.session_id),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    result = agent.invoke(payload, config=cfg)
    messages = result.get("messages", [])
    answer = ""
    if messages:
        last = messages[-1].content
        answer = last if isinstance(last, str) else json.dumps(last, ensure_ascii=False)
    if user_id and answer:
        extract_in_background(user_id, req.question, answer, settings)
    sources = []
    for msg in messages:
        if isinstance(msg, ToolMessage):
            sources.extend(parse_sources(msg.content))
    return ChatResponse(session_id=req.session_id, answer=answer, sources=sources)


@router.get("/web-search", response_model=WebSearchResponse)
def web_search(q: str = Query(min_length=2, max_length=300, description="要联网搜索的关键词")):
    """不经过大模型，直接看 Tavily 返回什么 —— 调参和答辩演示都靠它。"""
    settings = get_settings()
    raw = build_web_search_tool(settings).invoke({"query": q})
    data = json.loads(raw)
    return WebSearchResponse(
        query=q,
        mode=data["mode"],
        answer=data.get("answer", ""),
        results=data.get("results", []),
        note=data.get("note", ""),
    )


@router.get("/health", response_model=HealthResponse)
def health():
    s = get_settings()
    return HealthResponse(
        status="ok",
        deepseek_configured=s.has_deepseek,
        tavily_configured=s.has_tavily,
        web_search_mode=s.web_search_mode,
        backend=s.neushare_api_base,
        mock_mode=s.mock_mode,
        memory_policy=s.memory_policy,
        long_term_memory=(
            f"on(max_inject={s.memory_long_term_max_inject}, login-only)"
            if s.memory_long_term_enabled
            else "off"
        ),
    )
