"""Load published resource metadata from MySQL into Documents for the vector store."""
import json
from sqlalchemy import text
from langchain_core.documents import Document
from app.db.session import SessionLocal

_SQL = text(
    "SELECT r.id, r.title, r.description, r.tags, r.type, r.source, r.cover_url, "
    "c.name AS category_name, r.content_url "
    "FROM resource r LEFT JOIN category c ON r.category_id = c.id "
    "WHERE r.status = 1"
)


def _tags_to_str(tags) -> str:
    if tags is None:
        return ""
    if isinstance(tags, str):
        try:
            tags = json.loads(tags)
        except Exception:
            return tags
    if isinstance(tags, list):
        return " ".join(str(t) for t in tags)
    return str(tags)


def load_resources() -> list[Document]:
    docs: list[Document] = []
    db = SessionLocal()
    try:
        rows = db.execute(_SQL).fetchall()
        for row in rows:
            rid, title, desc, tags, rtype, source, cover, cat, content_url = row
            tags_str = _tags_to_str(tags)
            cat_name = cat or rtype or ""
            parts = [f"标题: {title}"]
            if cat_name:
                parts.append(f"分类: {cat_name}")
            if desc:
                parts.append(f"简介: {desc}")
            if tags_str:
                parts.append(f"标签: {tags_str}")
            if source:
                parts.append(f"来源: {source}")
            page = "\n".join(parts)
            docs.append(
                Document(
                    page_content=page,
                    metadata={
                        "source_type": "resource",
                        "resource_id": int(rid),
                        "title": title or "",
                        "category": cat_name,
                        "cover_url": cover or "",
                        "source": source or "",
                        "tags": tags_str,
                        "content_url": content_url or "",
                    },
                )
            )
    finally:
        db.close()
    return docs
