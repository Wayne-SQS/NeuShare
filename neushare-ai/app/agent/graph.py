"""LangGraph agent: tool-calling RAG assistant."""
from langgraph.prebuilt import create_react_agent
from app.agent.llm import get_llm
from app.agent.tools import retrieve_notes, search_resources

SYSTEM_PROMPT = """你是 NeuShare 校园学习助手，基于平台共享的学习资料为学生解答问题。

工作流程：
1. 收到问题后，先调用 retrieve_notes 检索学习笔记，用检索到的内容作答，绝不编造知识。
2. 回答末尾列出引用来源（笔记标题或文件名）。
3. 若问题适合推荐学习资料，调用 search_resources 并在回答中列出相关资源。
4. 若检索内容不足以回答，明确说明资料不足，并给出可行的学习建议或方向。
5. 用简洁清晰的中文回答，适当使用 markdown（小标题、列表、公式）排版。
"""

_agent = None


def get_agent():
    global _agent
    if _agent is None:
        _agent = create_react_agent(
            get_llm(),
            [retrieve_notes, search_resources],
            prompt=SYSTEM_PROMPT,
        )
    return _agent
