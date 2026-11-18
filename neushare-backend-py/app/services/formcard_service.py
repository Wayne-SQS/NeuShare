"""Form card queries + admin CRUD — mirrors FormCardServiceImpl.

Entity field names follow Java (Jackson camelCase): resourceType / resourceId /
contentUrl / sortOrder / createTime / updateTime.
"""
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BusinessException
from app.utils.common import to_entity_dict

_CURRENT_SQL = text(
    "SELECT title, resource_id, resource_type, content_url "
    "FROM form_card WHERE status = 1 ORDER BY sort_order ASC LIMIT 1"
)
_ALL_SQL = text(
    "SELECT id, title, resource_type, resource_id, content_url, sort_order, status, create_time, update_time "
    "FROM form_card ORDER BY sort_order ASC"
)

_UPDATABLE = {
    "title": "title",
    "resourceType": "resource_type",
    "resourceId": "resource_id",
    "contentUrl": "content_url",
    "sortOrder": "sort_order",
    "status": "status",
}


async def get_current(db: AsyncSession) -> dict:
    res = await db.execute(_CURRENT_SQL)
    row = res.mappings().first()
    if row is None:
        return {"resourceTitle": "暂无推荐", "resourceId": 0, "resourceType": "book", "contentUrl": ""}
    r = dict(row)
    return {
        "resourceTitle": r.get("title"),
        "resourceId": r.get("resource_id"),
        "resourceType": r.get("resource_type") or "book",
        "contentUrl": r.get("content_url") or "",
    }


async def get_all(db: AsyncSession) -> list:
    res = await db.execute(_ALL_SQL)
    return [to_entity_dict(dict(r)) for r in res.mappings().all()]


async def _exists(db, id_) -> bool:
    return (await db.execute(text("SELECT 1 FROM form_card WHERE id = :id"), {"id": id_})).scalar() is not None


async def add(db, payload: dict):
    await db.execute(
        text(
            "INSERT INTO form_card (title, resource_type, resource_id, content_url, sort_order, status, "
            "create_time, update_time) "
            "VALUES (:title, :resource_type, :resource_id, :content_url, :sort_order, :status, NOW(), NOW())"
        ),
        {
            "title": payload.get("title"),
            "resource_type": payload.get("resourceType") or "book",
            "resource_id": payload.get("resourceId"),
            "content_url": payload.get("contentUrl"),
            "sort_order": payload.get("sortOrder") if payload.get("sortOrder") is not None else 0,
            "status": payload.get("status") if payload.get("status") is not None else 1,
        },
    )
    await db.commit()


async def update(db, payload: dict):
    id_ = payload.get("id")
    if id_ is None or not await _exists(db, id_):
        raise BusinessException("卡片不存在")
    sets, params = ["update_time = NOW()"], {"id": id_}
    for key, col in _UPDATABLE.items():
        if payload.get(key) is not None:
            sets.append(f"{col} = :{col}")
            params[col] = payload[key]
    await db.execute(text(f"UPDATE form_card SET {', '.join(sets)} WHERE id = :id"), params)
    await db.commit()


async def delete(db, id_):
    if not await _exists(db, id_):
        raise BusinessException("卡片不存在")
    await db.execute(text("DELETE FROM form_card WHERE id = :id"), {"id": id_})
    await db.commit()


async def set_status(db, id_, status):
    if not await _exists(db, id_):
        raise BusinessException("卡片不存在")
    await db.execute(
        text("UPDATE form_card SET status = :status, update_time = NOW() WHERE id = :id"),
        {"id": id_, "status": status},
    )
    await db.commit()
