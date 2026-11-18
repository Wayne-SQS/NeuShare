"""Stream the agent answer as (event_type, payload) tuples."""
import json
from langchain_core.messages import AIMessage, ToolMessage
from app.agent.graph import get_agent


async def stream_answer(question: str, history: list | None = None, resource_id: int | None = None):
    messages = []
    for h in (history or [])[-8:]:
        messages.append({"role": h.get("role"), "content": h.get("content", "")})

    user_content = question
    if resource_id:
        user_content += (
            f"\n\n[上下文] 用户当前正在查看资源 ID={resource_id}，"
            f"请优先围绕该资料检索并回答。"
        )
    messages.append({"role": "user", "content": user_content})

    collected = {"content": "", "sources": [], "resources": [], "web_sources": []}
    seen_note, seen_res, seen_web = set(), set(), set()

    try:
        agent = get_agent()
        async for msg, _meta in agent.astream({"messages": messages}, stream_mode="messages"):
            if isinstance(msg, AIMessage):
                content = msg.content
                if isinstance(content, list):
                    delta = "".join(
                        part.get("text", "") for part in content if isinstance(part, dict)
                    )
                else:
                    delta = content or ""
                if delta:
                    collected["content"] += delta
                    yield ("token", delta)
            elif isinstance(msg, ToolMessage):
                try:
                    data = json.loads(msg.content)
                except Exception:
                    data = {}
                if isinstance(data, dict):
                    if data.get("notes"):
                        for n in data["notes"]:
                            key = n.get("file_name") or n.get("title")
                            if key and key not in seen_note:
                                seen_note.add(key)
                                collected["sources"].append(n)
                        yield ("sources", list(collected["sources"]))
                    if data.get("resources"):
                        for r in data["resources"]:
                            rid = r.get("resource_id")
                            if rid and rid not in seen_res:
                                seen_res.add(rid)
                                collected["resources"].append(r)
                        yield ("resources", list(collected["resources"]))
                    # 联网来源：带 type=web 与完整 URL，与站内来源分渠道
                    if data.get("mode") in ("tavily", "unavailable", "mock"):
                        for w in data.get("results") or []:
                            url = w.get("url") or ""
                            if url and url not in seen_web:
                                seen_web.add(url)
                                collected["web_sources"].append({
                                    "type": "web", "title": w.get("title") or "",
                                    "url": url, "content": (w.get("content") or "")[:800],
                                })
                        if collected["web_sources"]:
                            yield ("web_sources", list(collected["web_sources"]))
                        if data.get("mode") in ("unavailable", "mock"):
                            yield ("notice", data.get("note") or "联网检索当前不可用")
    except Exception as e:  # noqa: BLE001
        yield ("error", str(e))

    yield ("done", collected)
