"""User profile queries — mirrors UserController.getUserProfile (BeanUtil.copyProperties).

Only UserProfileVO fields are projected (password / timestamps are intentionally
excluded, exactly like BeanUtil.copyProperties which ignores non-matching fields).
"""
from sqlalchemy import text

from app.core.exceptions import BusinessException
from app.utils.paging import page_window

_COLS = ("id, username, role, nickname, avatar_url, college, grade, status, "
         "resource_count, follower_count, following_count, total_likes_received")


def to_profile_vo(row: dict) -> dict:
    return {
        "id": row["id"],
        "username": row.get("username"),
        "role": row.get("role"),
        "nickname": row.get("nickname"),
        "avatarUrl": row.get("avatar_url"),
        "college": row.get("college"),
        "grade": row.get("grade"),
        "status": row.get("status"),
        "resourceCount": row.get("resource_count"),
        "followerCount": row.get("follower_count"),
        "followingCount": row.get("following_count"),
        "totalLikesReceived": row.get("total_likes_received"),
    }


async def get_profile(db, uid):
    row = (await db.execute(text(f"SELECT {_COLS} FROM user WHERE id = :id"), {"id": uid})).mappings().first()
    return None if row is None else to_profile_vo(dict(row))


# ---------------- admin user management (mirrors AdminController + UserServiceImpl) ----------------

# UserVO 只有这 8 个字段（实体其余字段被 BeanUtil.copyProperties 丢弃）
_ADMIN_COLS = "id, username, role, nickname, avatar_url, college, grade, status"


def to_admin_user_vo(row: dict) -> dict:
    return {
        "id": row["id"],
        "username": row.get("username"),
        "role": row.get("role"),
        "nickname": row.get("nickname"),
        "avatarUrl": row.get("avatar_url"),
        "college": row.get("college"),
        "grade": row.get("grade"),
        "status": row.get("status"),
    }


async def get_admin_page(db, page_num, page_size, keyword=None):
    where = "1=1"
    params: dict = {}
    if keyword:
        # 与 (like username OR like nickname) 等价
        where = "(username LIKE CONCAT('%', :kw, '%') OR nickname LIKE CONCAT('%', :kw, '%'))"
        params["kw"] = keyword
    window = page_window(page_num, page_size)
    total = 0
    if window.count_rows:
        total = (await db.execute(text(f"SELECT COUNT(*) FROM user WHERE {where}"), params)).scalar() or 0
    sql = (f"SELECT {_ADMIN_COLS} FROM user WHERE {where} "
           "ORDER BY create_time DESC LIMIT :size OFFSET :offset")
    p = {**params, "size": window.size, "offset": window.offset}
    rows = (await db.execute(text(sql), p)).mappings().all()
    return [to_admin_user_vo(dict(r)) for r in rows], total


async def set_status(db, id_, status):
    row = (await db.execute(text("SELECT id FROM user WHERE id = :id"), {"id": id_})).mappings().first()
    if row is None:
        raise BusinessException("用户不存在")
    await db.execute(
        text("UPDATE user SET status = :status, update_time = NOW() WHERE id = :id"),
        {"id": id_, "status": status},
    )
    await db.commit()


# 顺序与原 deleteUserCascade 一致；子表清理全部用子查询，避免原 Java 的 N+1
_CASCADE_STATEMENTS = (
    "DELETE FROM comment WHERE resource_id IN (SELECT id FROM resource WHERE upload_user_id = :id)",
    "DELETE FROM favorite WHERE resource_id IN (SELECT id FROM resource WHERE upload_user_id = :id)",
    "DELETE FROM resource_like WHERE resource_id IN (SELECT id FROM resource WHERE upload_user_id = :id)",
    "DELETE FROM resource WHERE upload_user_id = :id",
    "DELETE FROM post_comment_like WHERE comment_id IN "
    "(SELECT id FROM post_comment WHERE post_id IN (SELECT id FROM post WHERE user_id = :id))",
    "DELETE FROM post_comment WHERE post_id IN (SELECT id FROM post WHERE user_id = :id)",
    "DELETE FROM post_like WHERE post_id IN (SELECT id FROM post WHERE user_id = :id)",
    "DELETE FROM post_favorite WHERE post_id IN (SELECT id FROM post WHERE user_id = :id)",
    "DELETE FROM post WHERE user_id = :id",
    "DELETE FROM post_comment_like WHERE comment_id IN (SELECT id FROM post_comment WHERE user_id = :id)",
    "DELETE FROM post_comment WHERE user_id = :id",
    "DELETE FROM post_comment_like WHERE user_id = :id",
    "DELETE FROM post_like WHERE user_id = :id",
    "DELETE FROM post_favorite WHERE user_id = :id",
    "DELETE FROM comment WHERE user_id = :id",
    "DELETE FROM favorite WHERE user_id = :id",
    "DELETE FROM follow WHERE follower_id = :id OR followed_id = :id",
    "DELETE FROM resource_like WHERE user_id = :id",
    "DELETE FROM notification WHERE user_id = :id OR from_user_id = :id",
    "DELETE FROM user WHERE id = :id",
)


async def delete_cascade(db, id_):
    row = (await db.execute(text("SELECT id FROM user WHERE id = :id"), {"id": id_})).mappings().first()
    if row is None:
        raise BusinessException("用户不存在")
    for sql in _CASCADE_STATEMENTS:
        await db.execute(text(sql), {"id": id_})
    await db.commit()
