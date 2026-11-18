"""Resource favorite add/remove/check/list — mirrors FavoriteServiceImpl + FavoriteMapper.xml."""
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.core.exceptions import BusinessException
from app.services import resource_service, notification_service
from app.utils.paging import page_window

_SEL_COLS = (
    "r.id, r.title, r.category_id, r.type, r.content_url, r.description, r.cover_url, "
    "r.upload_user_id, r.status, r.view_count, r.like_count, r.favorite_count, "
    "r.create_time, r.update_time, f.create_time AS favorite_time, "
    "u.username AS upload_username, u.nickname AS upload_nickname, u.avatar_url AS upload_avatar, "
    "c.name AS category_name"
)
_FROM = (
    " FROM favorite f LEFT JOIN resource r ON f.resource_id = r.id "
    "LEFT JOIN user u ON r.upload_user_id = u.id LEFT JOIN category c ON r.category_id = c.id "
    "WHERE f.user_id = :uid AND r.id IS NOT NULL"
)


async def add(db, user_id, resource_id):
    r = (await db.execute(
        text("SELECT id, upload_user_id, title FROM resource WHERE id = :id"), {"id": resource_id}
    )).mappings().first()
    if r is None:
        raise BusinessException("资源不存在")
    r = dict(r)
    exist = (await db.execute(
        text("SELECT id FROM favorite WHERE user_id = :uid AND resource_id = :rid"),
        {"uid": user_id, "rid": resource_id},
    )).scalar()
    if exist is not None:
        raise BusinessException("已收藏该资源")
    try:
        await db.execute(
            text("INSERT INTO favorite (user_id, resource_id, create_time) VALUES (:uid, :rid, NOW())"),
            {"uid": user_id, "rid": resource_id},
        )
    except IntegrityError:
        await db.rollback()
        raise BusinessException("已收藏该资源")
    await db.execute(
        text("UPDATE resource SET favorite_count = favorite_count + 1 WHERE id = :id"), {"id": resource_id}
    )
    if r["upload_user_id"] != user_id:
        nick = await notification_service.get_nickname(db, user_id)
        await notification_service.send(
            db, r["upload_user_id"], "favorite", resource_id, user_id,
            "有人收藏了你的资源", f"{nick} 收藏了你的资源「{r['title']}」。"
        )
    await db.commit()


async def remove(db, user_id, resource_id):
    exist = (await db.execute(
        text("SELECT id FROM favorite WHERE user_id = :uid AND resource_id = :rid"),
        {"uid": user_id, "rid": resource_id},
    )).scalar()
    if exist is None:
        raise BusinessException("未收藏该资源")
    await db.execute(
        text("DELETE FROM favorite WHERE user_id = :uid AND resource_id = :rid"),
        {"uid": user_id, "rid": resource_id},
    )
    await db.execute(
        text("UPDATE resource SET favorite_count = favorite_count - 1 WHERE id = :id AND favorite_count > 0"),
        {"id": resource_id},
    )
    await db.commit()


async def is_favorite(db, user_id, resource_id) -> bool:
    return (await db.execute(
        text("SELECT 1 FROM favorite WHERE user_id = :uid AND resource_id = :rid"),
        {"uid": user_id, "rid": resource_id},
    )).scalar() is not None


async def get_page(db, page_num, page_size, user_id):
    window = page_window(page_num, page_size)
    total = 0
    if window.count_rows:
        total = (await db.execute(text(f"SELECT COUNT(*) {_FROM}"), {"uid": user_id})).scalar() or 0
    sql = f"SELECT {_SEL_COLS} {_FROM} ORDER BY f.create_time DESC LIMIT :size OFFSET :offset"
    rows = (await db.execute(text(sql), {
        "uid": user_id, "size": window.size, "offset": window.offset,
    })).mappings().all()
    records = []
    for r in rows:
        vo = resource_service.to_resource_vo(dict(r), favorite_time=r.get("favorite_time"))
        # Java 的 FavoriteMapper 只查资源字段，未回填 fileExists → 恒为 null
        vo["fileExists"] = None
        records.append(vo)
    return records, total
