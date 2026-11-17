"""LangChain 1.x Agent 装配。

一句话看懂这层：
  create_agent 把「模型 + 工具 + 系统提示」编成一个 LangGraph 图，
  模型自己决定直接答还是调工具，工具结果回灌后再总结；
  InMemorySaver 按 thread_id 存多轮消息，所以同一个 session_id 能接着上文聊；
  middleware 在每次调模型前清旧工具输出、必要时压缩历史，防止撑爆上下文窗口。

版本注意：
  - LangChain 1.x 的入口是 langchain.agents.create_agent（不是老教程里的 initialize_agent）；
  - .env 里的 deepseek-chat 是兼容别名，服务端实际解析为 deepseek-flash（非思考模式），
    上下文 1M / 最大输出 384K；别只改模型名换 flash——思考模式默认开启会改变行为。
"""
from __future__ import annotations

from langchain.agents import AgentState, create_agent
from langchain.agents.middleware import ModelRequest, dynamic_prompt
from langchain.chat_models import init_chat_model
from langgraph.checkpoint.memory import InMemorySaver

from app.config import Settings
from app.memory import build_memory_middleware
from app.prompts import SYSTEM_PROMPT
from app.tools import build_tools


class AgentStateWithMemory(AgentState, total=False):
    """扩展 agent 状态：随请求传入的长期记忆文本，供 dynamic_prompt 注入 system prompt。

    走 state 而不是拼进用户消息的原因：拼进消息会被 checkpointer 存进会话历史，
    每轮都带一份、逐轮膨胀；state 字段每轮覆盖，不膨胀。"""
    long_term_memory: str


@dynamic_prompt
def memory_prompt(request: ModelRequest) -> str:
    """动态 system prompt：有长期记忆就附加在基础 prompt 后面，没有就原样。"""
    state = request.state or {}
    mem = (state.get("long_term_memory") or "").strip()
    if mem:
        return f"{SYSTEM_PROMPT}\n\n{mem}"
    return SYSTEM_PROMPT


class AgentNotReady(RuntimeError):
    """密钥没配好时抛，路由层转成 503，别让服务启动就崩。"""


_AGENT = None


def build_agent(settings: Settings):
    if not settings.has_deepseek:
        raise AgentNotReady(
            "DEEPSEEK_API_KEY 未配置，Agent 不可用。把 .env.example 复制为 .env 并填 key，或先用 MOCK_MODE 测接口。"
        )

    model = init_chat_model(
        model=f"deepseek:{settings.deepseek_model}",
        api_key=settings.deepseek_api_key,
        base_url=settings.deepseek_base_url,
        temperature=0.3,
    )

    return create_agent(
        model=model,
        tools=build_tools(settings),
        system_prompt=SYSTEM_PROMPT,
        checkpointer=InMemorySaver(),
        middleware=[*build_memory_middleware(model, settings), memory_prompt],
        state_schema=AgentStateWithMemory,
    )


def get_agent(settings: Settings):
    """惰性创建：没配 key 时 /health 和 /web-search 仍然能用。"""
    global _AGENT
    if _AGENT is None:
        _AGENT = build_agent(settings)
    return _AGENT


# ---------- BYOK：用户自带 key 的 agent 复用池 ----------

# (deepseek_key, tavily_key) -> agent。key 相同就复用同一个实例，
# 会话记忆随实例隔离（用户改 key 相当于换了一个助手，历史重开）。
_USER_AGENTS: dict[tuple[str, str], object] = {}
_USER_AGENT_MAX = 32


def get_agent_for_user_keys(settings: Settings, deepseek_key: str, tavily_key: str):
    """按用户 key 组合取 agent，没有就现场建一个并缓存。"""
    cache_key = (deepseek_key, tavily_key)
    agent = _USER_AGENTS.get(cache_key)
    if agent is None:
        if len(_USER_AGENTS) >= _USER_AGENT_MAX:
            _USER_AGENTS.clear()  # 简单防膨胀：全清，之后按需重建
        user_settings = settings.model_copy(update={
            "deepseek_api_key": deepseek_key,
            "tavily_api_key": tavily_key or settings.tavily_api_key,
        })
        agent = build_agent(user_settings)
        _USER_AGENTS[cache_key] = agent
    return agent
