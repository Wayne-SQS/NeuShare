"""Notification queries + delivery — mirrors NotificationServiceImpl.

send() just inserts a row; the message strings (type/title/content) are composed by
the calling service (comment/like/favorite/follow) to match Java exactly.
"""
from sqlalchemy import text

from app.core.exceptions import BusinessException
from app.utils.common import fmt_dt
from app.utils.paging import page_window


def to_notification_vo(row: dict) -> dict:
    return {
        "id": row["id"],
        "userId": row["user_id"],
        "fromUserId": row.get("from_user_id"),
        "type": row["type"],
        "title": row.get("title"),
        "content": row.get("content"),
        "resourceId": row.get("resource_id"),
        "isRead": row.get("is_read"),
        "createTime": fmt_dt(row.get("create_time")),
        "fromUsername": row.get("from_username"),
        "fromNickname": row.get("from_nickname"),
        "fromAvatarUrl": row.get("from_avatar_url"),
    }


async def send(db, user_id, type_, resource_id, from_user_id, title, content):
    """Insert a notification. Caller is responsible for committing the transaction."""
    await db.execute(
        text(
            "INSERT INTO notification (user_id, type, resource_id, from_user_id, title, content, is_read, create_time) "
            "VALUES (:uid, :type, :rid, :fuid, :title, :content, 0, NOW())"
        ),
        {"uid": user_id, "type": type_, "rid": resource_id, "fuid": from_user_id,
         "title": title, "content": content},
    )


async def get_nickname(db, uid) -> str:
    r = (await db.execute(text("SELECT nickname FROM user WHERE id = :id"), {"id": uid})).mappings().first()
    if r is None:
        return "有人"
    nick = dict(r).get("nickname")
    return nick if nick else "有人"


async def get_page(db, page_num, page_size, user_id, type_=None):
    where = "n.user_id = :uid"
    params = {"uid": user_id}
    if type_:
        where += " AND n.type = :type"
        params["type"] = type_
    window = page_window(page_num, page_size)
    total = 0
    if window.count_rows:
        total = (await db.execute(text(f"SELECT COUNT(*) FROM notification n WHERE {where}"), params)).scalar() or 0
    sql = (
        "SELECT n.*, u.username AS from_username, u.nickname AS from_nickname, u.avatar_url AS from_avatar_url "
        f"FROM notification n LEFT JOIN user u ON n.from_user_id = u.id WHERE {where} "
        "ORDER BY n.create_time DESC LIMIT :size OFFSET :offset"
    )
    params = {**params, "size": window.size, "offset": window.offset}
    rows = (await db.execute(text(sql), params)).mappings().all()
    return [to_notification_vo(dict(r)) for r in rows], total


async def count_unread(db, user_id) -> int:
    return (await db.execute(
        text("SELECT COUNT(*) FROM notification WHERE user_id = :uid AND is_read = 0"),
        {"uid": user_id},
    )).scalar() or 0


async def mark_read(db, id_, user_id):
    row = (await db.execute(text("SELECT user_id FROM notification WHERE id = :id"), {"id": id_})).mappings().first()
    if row is None or dict(row)["user_id"] != user_id:
        raise BusinessException("通知不存在")
    await db.execute(text("UPDATE notification SET is_read = 1 WHERE id = :id"), {"id": id_})
    await db.commit()


async def mark_all_read(db, user_id):
    await db.execute(text("UPDATE notification SET is_read = 1 WHERE user_id = :uid AND is_read = 0"), {"uid": user_id})
    await db.commit()


async def delete(db, id_, user_id):
    row = (await db.execute(text("SELECT user_id FROM notification WHERE id = :id"), {"id": id_})).mappings().first()
    if row is None or dict(row)["user_id"] != user_id:
        raise BusinessException("通知不存在")
    await db.execute(text("DELETE FROM notification WHERE id = :id"), {"id": id_})
    await db.commit()
