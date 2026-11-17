"""Tavily 联网搜索工具（本次新增能力）。

三种状态，前端和模型都能从返回的 mode 字段看出来：
  tavily      —— 有 key 且非演示模式，真的联网。优先用 langchain_tavily.TavilySearch
                 （LangChain 官方集成）；这个包没装就用 httpx 直调同一个 REST 接口。
  mock        —— MOCK_MODE=true，固定占位数据，跑通全链路做演示/测试，不发外网。
  unavailable —— 没配 key 或调用失败，返回明确提示，**不返回任何伪造的网页**。

对外统一吐 JSON 字符串，字段固定：mode / query / answer / results[] / note。
好处：模型能读、前端 /api/ai/web-search 能直接渲染「来源」卡片，两边不用各写一套解析。
"""
from __future__ import annotations

import json
import os
from typing import Any

import httpx
from langchain_core.tools import tool
from pydantic import BaseModel, Field

from app.config import Settings

TAVILY_ENDPOINT = "https://api.tavily.com/search"

# 演示数据：URL 用 example.com，明摆着是占位，绝不冒充真实网页
MOCK_RESULTS = [
    {
        "title": "[演示] Tavily 联网结果占位",
        "url": "https://example.com/tavily-demo",
        "content": "这是 MOCK_MODE 下的示例条目，不是真实检索结果。填入 TAVILY_API_KEY 并关闭 MOCK_MODE 后会替换为真实网页。",
        "score": None,
    }
]


class WebSearchInput(BaseModel):
    query: str = Field(
        min_length=2,
        max_length=300,
        description="要联网搜索的问题或关键词，尽量写成完整的中文短句",
    )


def _normalize(raw: Any, query: str, mode: str) -> dict:
    """把两种调用方式（LangChain 封装 / 原生 REST）的返回整理成同一结构。"""
    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except json.JSONDecodeError:
            raw = {"answer": raw}
    if not isinstance(raw, dict):
        raw = {}

    hits: list[dict] = []
    for item in (raw.get("results") or [])[:10]:
        if not isinstance(item, dict):
            continue
        hits.append(
            {
                "title": str(item.get("title") or "(无标题)"),
                "url": str(item.get("url") or ""),
                "content": str(item.get("content") or "")[:800],
                "score": item.get("score"),
            }
        )
    return {
        "mode": mode,
        "query": query,
        "answer": str(raw.get("answer") or ""),
        "results": hits,
        "note": "",
    }


def _via_langchain(query: str, settings: Settings) -> dict | None:
    """主路径：用 LangChain 官方的 TavilySearch。包没装就返回 None，交给 REST 兜底。"""
    try:
        from langchain_tavily import TavilySearch
    except ImportError:
        return None

    # langchain-tavily 默认从环境变量取 key，而我们的 key 可能只在 .env 里
    os.environ.setdefault("TAVILY_API_KEY", settings.tavily_api_key)
    search = TavilySearch(
        max_results=settings.tavily_max_results,
        topic="general",
        include_answer=True,
    )
    return _normalize(search.invoke({"query": query}), query, "tavily")


def _via_http(query: str, settings: Settings) -> dict:
    """兜底路径：不依赖 langchain-tavily，直接调 Tavily REST API。"""
    payload = {
        "api_key": settings.tavily_api_key,
        "query": query,
        "topic": "general",
        "search_depth": "basic",
        "max_results": settings.tavily_max_results,
        "include_answer": True,
    }
    kwargs: dict[str, Any] = {"timeout": 15.0}
    if settings.tavily_proxy:
        kwargs["proxy"] = settings.tavily_proxy
        kwargs["trust_env"] = False  # 指定代理时别再叠加系统代理
    with httpx.Client(**kwargs) as client:
        resp = client.post(TAVILY_ENDPOINT, json=payload)
        resp.raise_for_status()
        return _normalize(resp.json(), query, "tavily")


def build_web_search_tool(settings: Settings):
    @tool(
        "web_search",
        args_schema=WebSearchInput,
        description=(
            "联网搜索公开网页（Tavily）。用于平台资料覆盖不到的时效性问题：最新政策、"
            "招生简章、官网通知、考试安排、软件新版本、外部教程等。"
            "返回标题、URL、摘要；回答时必须标注 URL。"
        ),
    )
    def web_search(query: str) -> str:
        if settings.mock_mode:
            data = {
                "mode": "mock",
                "query": query,
                "answer": "",
                "results": MOCK_RESULTS,
                "note": "演示模式：以下是占位数据，不是真实网页。配置 TAVILY_API_KEY 并关闭 MOCK_MODE 后才会联网。",
            }
            return json.dumps(data, ensure_ascii=False)

        if not settings.has_tavily:
            data = {
                "mode": "unavailable",
                "query": query,
                "answer": "",
                "results": [],
                "note": "联网检索未配置：服务端缺少 TAVILY_API_KEY。请如实告知用户当前无法联网，不要编造网页结果。",
            }
            return json.dumps(data, ensure_ascii=False)

        try:
            data = _via_langchain(query, settings)
            if data is None:
                data = _via_http(query, settings)
        except Exception as exc:  # 工具内部异常必须转成模型可读文本，不能炸掉整个 Agent 循环
            data = {
                "mode": "unavailable",
                "query": query,
                "answer": "",
                "results": [],
                "note": f"联网检索调用失败：{type(exc).__name__}: {exc}。请如实告知用户，不要编造结果。",
            }
        return json.dumps(data, ensure_ascii=False)

    return web_search


def parse_sources(payload: str | list | dict) -> list[dict]:
    """从工具返回里抽出「来源卡片」数据，给 SSE 的 event: source 用。"""
    if isinstance(payload, list):
        parts = payload
    else:
        parts = [payload]
    sources: list[dict] = []
    for part in parts:
        text = part if isinstance(part, str) else (part.get("content", "") if isinstance(part, dict) else "")
        if not isinstance(text, str) or not text.strip().startswith("{"):
            continue
        try:
            data = json.loads(text)
        except json.JSONDecodeError:
            continue
        if not isinstance(data, dict):
            continue
        if data.get("mode") == "platform" or "items" in data or "item" in data:  # 站内工具
            items = data.get("items") or ([data["item"]] if data.get("item") else [])
            for item in items:
                sources.append(
                    {
                        "type": "platform",
                        "title": str(item.get("title", "")),
                        "url": "",
                        "ref_id": str(item.get("id", "")),
                    }
                )
        for hit in data.get("results", []):  # 联网工具
            sources.append(
                {
                    "type": "web",
                    "title": str(hit.get("title", "")),
                    "url": str(hit.get("url", "")),
                    "ref_id": "",
                }
            )
    return sources
