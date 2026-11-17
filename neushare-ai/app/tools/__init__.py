"""工具集：工具白名单只在这里注册，Agent 拿不到清单外的任何能力。"""
from __future__ import annotations

from app.config import Settings
from app.tools.platform import build_platform_tools
from app.tools.web_search import build_web_search_tool


def build_tools(settings: Settings) -> list:
    return [
        build_web_search_tool(settings),  # 联网（Tavily）
        *build_platform_tools(settings),  # 站内检索 / 详情 / 跳页
    ]
