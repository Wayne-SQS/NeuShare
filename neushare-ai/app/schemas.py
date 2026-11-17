"""请求 / 响应数据模型。

Pydantic 会替我们做参数校验：字段类型不对、超长、缺字段，FastAPI 直接返回 422，
不用在每个接口里手写 if。这也是"工具参数不可信"的第一道护栏。
"""
from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    question: str = Field(min_length=1, max_length=2000, description="用户问题")
    session_id: str = Field(default="default", max_length=64, description="会话 ID，同一 ID 共享多轮记忆")
    stream: bool = Field(default=True, description="true 走 SSE 流式，false 一次性返回")
    access_token: str = Field(
        default="",
        max_length=2048,
        description="用户 JWT。带上后优先用该用户自己配置的 AI key（BYOK），无效或缺省走平台 key",
    )


class Source(BaseModel):
    type: Literal["web", "platform"] = "web"
    title: str
    url: str = ""
    ref_id: str = ""


class ChatResponse(BaseModel):
    session_id: str
    answer: str
    sources: list[Source] = Field(default_factory=list)


class SearchHit(BaseModel):
    title: str
    url: str = ""
    content: str = ""
    score: float | None = None


class WebSearchResponse(BaseModel):
    query: str
    mode: Literal["tavily", "mock", "unavailable"]
    answer: str = ""
    results: list[SearchHit] = Field(default_factory=list)
    note: str = ""


class HealthResponse(BaseModel):
    status: str
    deepseek_configured: bool
    tavily_configured: bool
    web_search_mode: str
    backend: str
    mock_mode: bool
    memory_policy: str = ""
    long_term_memory: str = ""
