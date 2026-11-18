"""Banner queries + admin CRUD — mirrors BannerServiceImpl.

Field naming follows the Java entity (Jackson camelCase): imageUrl / linkUrl / createTime.
"""
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BusinessException
from app.utils.common import to_entity_dict

_ACTIVE_SQL = text(
    "SELECT id, title, image_url, link_url, sort, status, create_time "
    "FROM banner WHERE status = 1 ORDER BY sort ASC"
)
_ALL_SQL = text(
    "SELECT id, title, image_url, link_url, sort, status, create_time "
    "FROM banner ORDER BY sort ASC"
)

# 请求体 camelCase -> 列名（MyBatis-Plus updateById 只更新非 null 字段）
_UPDATABLE = {
    "title": "title",
    "imageUrl": "image_url",
    "linkUrl": "link_url",
    "sort": "sort",
    "status": "status",
}


async def get_active(db: AsyncSession) -> list:
    res = await db.execute(_ACTIVE_SQL)
    return [to_entity_dict(dict(r)) for r in res.mappings().all()]


async def get_all(db: AsyncSession) -> list:
    res = await db.execute(_ALL_SQL)
    return [to_entity_dict(dict(r)) for r in res.mappings().all()]


async def _exists(db, id_) -> bool:
    return (await db.execute(text("SELECT 1 FROM banner WHERE id = :id"), {"id": id_})).scalar() is not None


async def add(db, payload: dict):
    await db.execute(
        text(
            "INSERT INTO banner (title, image_url, link_url, sort, status, create_time) "
            "VALUES (:title, :image_url, :link_url, :sort, :status, NOW())"
        ),
        {
            "title": payload.get("title"),
            "image_url": payload.get("imageUrl"),
            "link_url": payload.get("linkUrl"),
            "sort": payload.get("sort") if payload.get("sort") is not None else 0,
            "status": payload.get("status") if payload.get("status") is not None else 1,
        },
    )
    await db.commit()


async def update(db, payload: dict):
    id_ = payload.get("id")
    if id_ is None or not await _exists(db, id_):
        raise BusinessException("轮播图不存在")
    sets, params = [], {"id": id_}
    for key, col in _UPDATABLE.items():
        if payload.get(key) is not None:
            sets.append(f"{col} = :{col}")
            params[col] = payload[key]
    if sets:
        await db.execute(text(f"UPDATE banner SET {', '.join(sets)} WHERE id = :id"), params)
        await db.commit()


async def delete(db, id_):
    if not await _exists(db, id_):
        raise BusinessException("轮播图不存在")
    await db.execute(text("DELETE FROM banner WHERE id = :id"), {"id": id_})
    await db.commit()


async def set_status(db, id_, status):
    if not await _exists(db, id_):
        raise BusinessException("轮播图不存在")
    await db.execute(text("UPDATE banner SET status = :status WHERE id = :id"), {"id": id_, "status": status})
    await db.commit()
