"""站内工具：只读调 Java 业务后端，**绝不写库**。

设计上刻意让 AI 服务不碰数据库：
  - 权限、审核状态（status=1 才可见）由 Java 后端统一把守，AI 侧绕不过去；
  - AI 服务挂了不影响主站，主站挂了 AI 只是检索降级；
  - 面试能讲清「为什么模型不直接连库」。

后端统一响应是 {"code":200,"message":"...","data":{...}}，
列表数据在 data.records，详情在 data。
"""
from __future__ import annotations

import json

import httpx
from langchain_core.tools import tool
from pydantic import BaseModel, Field

from app.config import Settings

ALLOWED_PAGES = ("Home", "ResourceList", "ResourceDetail", "Upload", "Profile")


class SearchInput(BaseModel):
    keyword: str = Field(min_length=1, max_length=100, description="资料关键词，如『操作系统 进程调度』")
    limit: int = Field(default=5, ge=1, le=20, description="返回条数")


class DetailInput(BaseModel):
    resource_id: int = Field(ge=1, description="站内资源 ID")


class NavigateInput(BaseModel):
    page: str = Field(description="目标页面：Home / ResourceList / ResourceDetail / Upload / Profile")
    params: dict[str, str] = Field(default_factory=dict, description="页面参数，如 {'id': '42'}")


def _get(settings: Settings, path: str, params: dict) -> dict:
    # trust_env=False：localhost 必须直连，否则会被本机常驻的 HTTP_PROXY 劫持
    with httpx.Client(timeout=8.0, trust_env=False) as client:
        resp = client.get(settings.neushare_api_base.rstrip("/") + path, params=params)
        resp.raise_for_status()
        body = resp.json()
    if body.get("code") not in (200, None):
        raise RuntimeError(f"业务后端返回 code={body.get('code')}: {body.get('message')}")
    return body.get("data") or {}


def _brief(item: dict) -> dict:
    """只挑模型用得上的字段，别把整个 VO 塞进 prompt（省 token）。"""
    return {
        "id": item.get("id"),
        "title": item.get("title") or "",
        "description": (item.get("description") or "")[:200],
        "categoryName": item.get("categoryName") or "",
        "courseName": item.get("courseName") or "",
        "teacher": item.get("teacher") or "",
        "type": item.get("type") or "",
        "tags": item.get("tags") or "",
    }


def build_platform_tools(settings: Settings) -> list:
    @tool("search_platform_resources", args_schema=SearchInput, description=(
        "按关键词搜索 NeuShare 平台收录的学习资料（课件、笔记、网课、考研资料），"
        "返回资源 ID、标题、简介、课程与教师。找站内资料时优先用这个工具。"
    ))
    def search_platform_resources(keyword: str, limit: int = 5) -> str:
        try:
            data = _get(settings, "/api/resource/list", {"keyword": keyword, "pageSize": limit, "pageNum": 1})
            records = data.get("records") or data.get("list") or data.get("items") or []
            items = [_brief(x) for x in records if isinstance(x, dict)][:limit]
            return json.dumps({"mode": "platform", "ok": True, "items": items, "note": ""}, ensure_ascii=False)
        except Exception as exc:
            return json.dumps(
                {"mode": "platform", "ok": False, "items": [],
                 "note": f"站内检索暂不可用：{type(exc).__name__}: {exc}。请如实告知用户，不要编造站内资源。"},
                ensure_ascii=False,
            )

    @tool("get_resource_detail", args_schema=DetailInput, description="按 ID 取一条站内资料的详情")
    def get_resource_detail(resource_id: int) -> str:
        try:
            detail = _get(settings, f"/api/resource/detail/{resource_id}", {})
            return json.dumps({"mode": "platform", "ok": True, "item": _brief(detail), "note": ""}, ensure_ascii=False)
        except Exception as exc:
            return json.dumps(
                {"mode": "platform", "ok": False, "item": {},
                 "note": f"资源详情暂不可用：{type(exc).__name__}: {exc}。不要编造内容。"},
                ensure_ascii=False,
            )

    @tool("navigate", args_schema=NavigateInput, description=(
        "返回一条结构化跳转指令，让客户端跳到指定页面。用户说『打开这个资料』『去上传』时用它，"
        "不要自己拼 URL。"
    ))
    def navigate(page: str, params: dict[str, str] | None = None) -> str:
        if page not in ALLOWED_PAGES:
            return json.dumps(
                {"action": "none", "note": f"不允许跳转到页面 {page}，只允许 {', '.join(ALLOWED_PAGES)}"},
                ensure_ascii=False,
            )
        return json.dumps(
            {"action": "navigate", "page": page, "params": params or {}},
            ensure_ascii=False,
        )

    return [search_platform_resources, get_resource_detail, navigate]
