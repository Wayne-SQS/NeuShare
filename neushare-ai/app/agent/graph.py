"""LangGraph agent: tool-calling RAG assistant."""
from langchain_core.tools import tool
from langgraph.prebuilt import create_react_agent
from app.agent.llm import get_llm
from app.agent.tools import retrieve_notes, search_resources
from app.agent.guardrails import SYSTEM_PROMPT, web_search, format_tool_result


@tool
def web_search_tool(query: str) -> str:
    """联网检索公开网页。涉及时效性问题（最新/今年/官网/招生简章/考试时间/政策/版本更新）时使用。
    返回 mode=tavily|unavailable|mock；不可用时必须如实告知用户，绝不编造网页结果。"""
    return format_tool_result(web_search(query))

_agent = None


def get_agent():
    global _agent
    if _agent is None:
        _agent = create_react_agent(
            get_llm(),
            [retrieve_notes, search_resources, web_search_tool],
            prompt=SYSTEM_PROMPT,
        )
    return _agent
