"""Agent tools: retrieve study notes (FAISS) + search platform resources."""
import json
import httpx
from langchain_core.tools import tool
from app.ingestion.vectorstore import similarity_search
from app.config import settings


@tool
def retrieve_notes(query: str, k: int = 4) -> str:
    """从学习笔记知识库中检索与问题最相关的片段，用于基于资料作答。参数 query 为用户问题。"""
    docs = similarity_search(query, k=k, source_type="note")
    notes = []
    for d in docs:
        md = d.metadata
        notes.append(
            {
                "title": md.get("title") or md.get("file_name") or "",
                "resource_id": md.get("resource_id"),
                "file_name": md.get("file_name") or "",
                "snippet": d.page_content[:400],
            }
        )
    return json.dumps(
        {"notes": notes, "summary": f"检索到 {len(notes)} 条相关笔记片段"},
        ensure_ascii=False,
    )


@tool
def search_resources(keyword: str, limit: int = 5) -> str:
    """在 NeuShare 平台搜索相关学习资源，用于推荐给用户。参数 keyword 为搜索关键词。"""
    resources = []
    # 1) Try Java backend real-time search; graceful fallback if unavailable
    try:
        r = httpx.get(
            f"{settings.java_backend_url}/api/resource/search",
            params={"keyword": keyword, "pageSize": limit, "pageNum": 1},
            timeout=3.0,
        )
        if r.status_code == 200:
            payload = (r.json() or {}).get("data")
            items = []
            if isinstance(payload, dict):
                items = payload.get("list") or payload.get("records") or []
            elif isinstance(payload, list):
                items = payload
            for it in items[:limit]:
                resources.append(
                    {
                        "resource_id": it.get("id"),
                        "title": it.get("title"),
                        "cover_url": it.get("coverUrl") or it.get("cover_url") or "",
                        "category": it.get("categoryName") or it.get("category_name") or it.get("type") or "",
                        "source": it.get("source") or "",
                    }
                )
    except Exception:
        resources = []

    # 2) Fallback: semantic match over resource metadata in FAISS
    if not resources:
        docs = similarity_search(keyword, k=limit, source_type="resource")
        for d in docs:
            md = d.metadata
            resources.append(
                {
                    "resource_id": md.get("resource_id"),
                    "title": md.get("title") or "",
                    "cover_url": md.get("cover_url") or "",
                    "category": md.get("category") or "",
                    "source": md.get("source") or "",
                }
            )

    # de-duplicate by resource_id
    seen, uniq = set(), []
    for r in resources:
        rid = r.get("resource_id")
        if rid and rid not in seen:
            seen.add(rid)
            uniq.append(r)
    return json.dumps(
        {"resources": uniq, "summary": f"找到 {len(uniq)} 个相关资源"},
        ensure_ascii=False,
    )
