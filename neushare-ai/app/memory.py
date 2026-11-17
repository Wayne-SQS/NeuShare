"""上下文窗口保护。

模型有输入上限，超了会直接 400；就算没超，历史越滚越长也会让首 token 延迟、
成本上升，早期信息还容易被稀释（lost in the middle）。这里的核心手段是
**历史会话压缩（归纳式）**：被压缩的内容必须先归纳进摘要，绝不直接删除。

主层：SummarizationMiddleware（历史会话压缩）
    条数或估算 token 任一超过阈值时，把更早的历史交给模型归纳成一段摘要，
    只保留「摘要 + 最近 N 条完整消息」。摘要 prompt 强制保留：本次会话任务目标、
    中间完成的重要产物（关键数据/资源 #ID/URL 原样）、用户的新要求、
    已确认事实及其来源、查过的工具与结论、未解决的问题。
    这一步会额外调一次模型，是唯一的信息出口——不归纳的内容一个字都不会丢进摘要。

可选层（默认关闭）：ContextEditingMiddleware + ClearToolUsesEdit
    把较早的工具输出原文直接替换成占位符。**不可逆、无归纳，会丢信息**，
    默认 memory_clear_tool_enabled=False；确有省钱需求时再打开。

两个中间件都是 LangChain 1.x 官方实现，它们通过 RemoveMessage 改写图状态，
所以改动会一起写回 checkpointer —— 重启前/换持久化 checkpointer 后行为一致。
"""
from __future__ import annotations

from langchain.agents.middleware import ContextEditingMiddleware, SummarizationMiddleware
from langchain.agents.middleware.context_editing import ClearToolUsesEdit

from app.config import Settings

# 覆盖官方英文模板：摘要必须先归纳后压缩，来源与产物一个都不能丢，不许编造。
# {messages} 由中间件填入，不能改名字。
SUMMARY_PROMPT = """你是 NeuShare 校园学习助手的上下文整理器。会话即将触及上下文窗口上限，请把下面的历史**归纳总结**成一段可继续使用的摘要——是归纳，不是删减：下列六类内容一条都不许丢。

严格要求：
- 只保留历史里真实出现过的信息，不许补充、推测或编造任何资源标题、链接、分数线、考试时间。
- 必须完整保留六类内容：
  1) 本次会话的任务目标——用户从头到尾想做成什么；
  2) 中间完成的重要产物——得出的关键结论、具体数据、站内资源 #ID、文件/链接等，URL 和 ID 原样照抄；
  3) 用户的新要求与最新指令——中途改方向、加需求、纠正过的点，以最新口径为准；
  4) 已经确认的事实及其来源，明确区分「平台内资料」与「联网网页」两类来源，不要混为一谈；
  5) 已经调用过的工具、查到过什么、得出过什么结论；
  6) 还没解决、需要继续跟进的问题。
- 不要罗列寒暄，不要写成对话流水账，不要加任何前后缀说明。
- 直接输出摘要正文。

待压缩的会话历史：
{messages}
"""


def build_memory_middleware(model, settings: Settings) -> list:
    """返回按顺序生效的中间件列表；关掉开关就返回空列表。

    注意 model 必须传 BaseChatModel 实例。传 "deepseek:xxx" 字符串时中间件会
    自己再 init_chat_model 一次，若进程环境里没有 DEEPSEEK_API_KEY 会直接报错
    （key 只写在 .env 里、没进 os.environ 时尤其容易踩）。
    """
    if not settings.memory_enabled:
        return []

    middlewares: list = []
    if settings.memory_clear_tool_enabled:
        # 可选层：直接删工具原文，不可逆、无归纳，默认关闭（信息保真优先）
        clear_old_tools = ClearToolUsesEdit(
            trigger=settings.memory_clear_tool_tokens,
            keep=settings.memory_clear_tool_keep,
            placeholder="[较早的工具输出已清理；如需细节请重新检索]",
        )
        middlewares.append(ContextEditingMiddleware(edits=[clear_old_tools]))

    middlewares.append(
        SummarizationMiddleware(
            model=model,
            # 列表 = 任一条件满足就触发（OR）
            trigger=[
                ("messages", settings.memory_max_messages),
                ("tokens", settings.memory_max_tokens),
            ],
            keep=("messages", settings.memory_keep_recent),
            summary_prompt=SUMMARY_PROMPT,
        )
    )
    return middlewares
