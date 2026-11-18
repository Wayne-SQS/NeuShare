"""Post read queries — mirrors PostMapper.xml exactly."""
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.cache.decorator import cached
from app.core.exceptions import BusinessException
from app.services import notification_service
from app.utils.common import fmt_dt
from app.utils.paging import page_window


def _norm_json(val):
    if val is None or isinstance(val, str):
        return val
    import json
    return json.dumps(val, ensure_ascii=False)

_SELECT = (
    "p.id, p.user_id, p.title, p.content, p.tags, p.image_urls, p.files, p.is_recommended, "
    "p.view_count, p.like_count, p.favorite_count, p.comment_count, p.status, p.create_time, p.update_time, "
    "u.nickname AS author_nickname, u.avatar_url AS author_avatar_url, u.college AS author_college"
)
_FROM = " FROM post p LEFT JOIN user u ON p.user_id = u.id"


def to_post_vo(row: dict) -> dict:
    return {
        "id": row["id"],
        "userId": row["user_id"],
        "title": row["title"],
        "content": row.get("content"),
        "tags": row.get("tags"),
        "imageUrls": row.get("image_urls"),
        "files": row.get("files"),
        "isRecommended": row.get("is_recommended"),
        "viewCount": row["view_count"],
        "likeCount": row["like_count"],
        "favoriteCount": row["favorite_count"],
        "commentCount": row["comment_count"],
        "status": row["status"],
        "createTime": fmt_dt(row.get("create_time")),
        "updateTime": fmt_dt(row.get("update_time")),
        "authorNickname": row.get("author_nickname"),
        "authorAvatarUrl": row.get("author_avatar_url"),
        "authorCollege": row.get("author_college"),
    }


def _where(status=None, tag=None, keyword=None, user_id=None):
    where, params = ["1=1"], {}
    if status is not None:
        where.append("p.status = :status"); params["status"] = status
    if tag:
        where.append("JSON_CONTAINS(p.tags, CONCAT('\"', :tag, '\"'))"); params["tag"] = tag
    if keyword:
        where.append("(p.title LIKE CONCAT('%',:keyword,'%') OR p.content LIKE CONCAT('%',:keyword,'%'))")
        params["keyword"] = keyword
    if user_id is not None:
        where.append("p.user_id = :user_id"); params["user_id"] = user_id
    return where, params


def _order(sort_by: str) -> str:
    return ("p.like_count DESC, p.comment_count DESC, p.create_time DESC"
            if sort_by == "hot" else "p.create_time DESC")


async def get_page(db, page_num, page_size, status=None, tag=None, keyword=None, sort_by="new"):
    where, params = _where(status, tag, keyword)
    window = page_window(page_num, page_size)
    total = 0
    if window.count_rows:
        total = (await db.execute(text(f"SELECT COUNT(*) {_FROM} WHERE {' AND '.join(where)}"), params)).scalar() or 0
    sql = f"SELECT {_SELECT} {_FROM} WHERE {' AND '.join(where)} ORDER BY {_order(sort_by)} LIMIT :size OFFSET :offset"
    p = {**params, "size": window.size, "offset": window.offset}
    rows = (await db.execute(text(sql), p)).mappings().all()
    return [to_post_vo(dict(r)) for r in rows], total


async def get_detail(db, pid):
    row = (await db.execute(text(f"SELECT {_SELECT} {_FROM} WHERE p.id = :id"), {"id": pid})).mappings().first()
    return None if row is None else to_post_vo(dict(row))


@cached(key=lambda db, limit: f"post:hot:{limit}", ttl=60)
async def get_hot(db, limit: int):
    sql = (f"SELECT {_SELECT} {_FROM} WHERE p.status = 1 "
           "ORDER BY p.like_count DESC, p.comment_count DESC LIMIT :limit")
    rows = (await db.execute(text(sql), {"limit": limit})).mappings().all()
    return [to_post_vo(dict(r)) for r in rows]


async def increment_view(db, pid):
    await db.execute(text("UPDATE post SET view_count = view_count + 1 WHERE id = :id"), {"id": pid})
    await db.commit()


async def get_user_posts(db, page_num, page_size, user_id):
    where, params = _where(user_id=user_id)
    window = page_window(page_num, page_size)
    total = 0
    if window.count_rows:
        total = (await db.execute(text(f"SELECT COUNT(*) {_FROM} WHERE {' AND '.join(where)}"), params)).scalar() or 0
    sql = f"SELECT {_SELECT} {_FROM} WHERE {' AND '.join(where)} ORDER BY p.create_time DESC LIMIT :size OFFSET :offset"
    p = {**params, "size": window.size, "offset": window.offset}
    rows = (await db.execute(text(sql), p)).mappings().all()
    return [to_post_vo(dict(r)) for r in rows], total


# ---------------- writes (mirrors PostServiceImpl create/update/delete/like/favorite/recommend) ----------------

async def create(db, user_id, dto):
    await db.execute(text(
        "INSERT INTO post (user_id, title, content, tags, image_urls, files, is_recommended, "
        "view_count, like_count, favorite_count, comment_count, status, create_time, update_time) "
        "VALUES (:uid, :title, :content, :tags, :imgs, :files, 0, 0, 0, 0, 0, 1, NOW(), NOW())"
    ), {
        "uid": user_id, "title": dto.get("title"), "content": dto.get("content"),
        "tags": _norm_json(dto.get("tags")), "imgs": _norm_json(dto.get("imageUrls")),
        "files": _norm_json(dto.get("files")),
    })
    await db.commit()


async def update(db, user_id, role, dto):
    pid = dto.get("id")
    row = (await db.execute(text("SELECT user_id FROM post WHERE id = :id"), {"id": pid})).mappings().first()
    if row is None:
        raise BusinessException("帖子不存在")
    if dict(row)["user_id"] != user_id and role != "admin":
        raise BusinessException("无权修改此帖子")
    await db.execute(text(
        "UPDATE post SET title = :title, content = :content, tags = :tags, image_urls = :imgs, "
        "files = :files, update_time = NOW() WHERE id = :id"
    ), {
        "id": pid, "title": dto.get("title"), "content": dto.get("content"),
        "tags": _norm_json(dto.get("tags")), "imgs": _norm_json(dto.get("imageUrls")),
        "files": _norm_json(dto.get("files")),
    })
    await db.commit()


async def delete(db, id_, user_id, role):
    row = (await db.execute(text("SELECT user_id FROM post WHERE id = :id"), {"id": id_})).mappings().first()
    if row is None:
        raise BusinessException("帖子不存在")
    if dict(row)["user_id"] != user_id and role != "admin":
        raise BusinessException("无权删除此帖子")
    await db.execute(text("DELETE FROM post_like WHERE post_id = :id"), {"id": id_})
    await db.execute(text("DELETE FROM post_favorite WHERE post_id = :id"), {"id": id_})
    await db.execute(text("DELETE FROM post_comment WHERE post_id = :id"), {"id": id_})
    await db.execute(text("DELETE FROM post WHERE id = :id"), {"id": id_})
    await db.commit()


async def like(db, post_id, user_id):
    row = (await db.execute(
        text("SELECT id, user_id, title FROM post WHERE id = :id"), {"id": post_id}
    )).mappings().first()
    if row is None:
        raise BusinessException("帖子不存在")
    row = dict(row)
    exist = (await db.execute(
        text("SELECT id FROM post_like WHERE user_id = :uid AND post_id = :pid"),
        {"uid": user_id, "pid": post_id},
    )).scalar()
    if exist is not None:
        raise BusinessException("已点赞该帖子")
    try:
        await db.execute(
            text("INSERT INTO post_like (user_id, post_id, create_time) VALUES (:uid, :pid, NOW())"),
            {"uid": user_id, "pid": post_id},
        )
    except IntegrityError:
        await db.rollback()
        raise BusinessException("已点赞该帖子")
    await db.execute(text("UPDATE post SET like_count = like_count + 1 WHERE id = :id"), {"id": post_id})
    if row["user_id"] != user_id:
        nick = await notification_service.get_nickname(db, user_id)
        await notification_service.send(
            db, row["user_id"], "like", post_id, user_id,
            "有人点赞了你的帖子", f"{nick} 点赞了你的帖子「{row['title']}」。"
        )
    await db.commit()


async def unlike(db, post_id, user_id):
    row = (await db.execute(text("SELECT id FROM post WHERE id = :id"), {"id": post_id})).scalar()
    if row is None:
        raise BusinessException("帖子不存在")
    exist = (await db.execute(
        text("SELECT id FROM post_like WHERE user_id = :uid AND post_id = :pid"),
        {"uid": user_id, "pid": post_id},
    )).scalar()
    if exist is None:
        raise BusinessException("未点赞该帖子")
    await db.execute(
        text("DELETE FROM post_like WHERE user_id = :uid AND post_id = :pid"),
        {"uid": user_id, "pid": post_id},
    )
    await db.execute(
        text("UPDATE post SET like_count = like_count - 1 WHERE id = :id AND like_count > 0"),
        {"id": post_id},
    )
    await db.commit()


async def is_liked(db, post_id, user_id) -> bool:
    return (await db.execute(
        text("SELECT 1 FROM post_like WHERE user_id = :uid AND post_id = :pid"),
        {"uid": user_id, "pid": post_id},
    )).scalar() is not None


async def favorite(db, post_id, user_id):
    row = (await db.execute(
        text("SELECT id, user_id, title FROM post WHERE id = :id"), {"id": post_id}
    )).mappings().first()
    if row is None:
        raise BusinessException("帖子不存在")
    row = dict(row)
    exist = (await db.execute(
        text("SELECT id FROM post_favorite WHERE user_id = :uid AND post_id = :pid"),
        {"uid": user_id, "pid": post_id},
    )).scalar()
    if exist is not None:
        raise BusinessException("已收藏该帖子")
    try:
        await db.execute(
            text("INSERT INTO post_favorite (user_id, post_id, create_time) VALUES (:uid, :pid, NOW())"),
            {"uid": user_id, "pid": post_id},
        )
    except IntegrityError:
        await db.rollback()
        raise BusinessException("已收藏该帖子")
    await db.execute(text("UPDATE post SET favorite_count = favorite_count + 1 WHERE id = :id"), {"id": post_id})
    if row["user_id"] != user_id:
        nick = await notification_service.get_nickname(db, user_id)
        await notification_service.send(
            db, row["user_id"], "favorite", post_id, user_id,
            "有人收藏了你的帖子", f"{nick} 收藏了你的帖子「{row['title']}」。"
        )
    await db.commit()


async def unfavorite(db, post_id, user_id):
    row = (await db.execute(text("SELECT id FROM post WHERE id = :id"), {"id": post_id})).scalar()
    if row is None:
        raise BusinessException("帖子不存在")
    exist = (await db.execute(
        text("SELECT id FROM post_favorite WHERE user_id = :uid AND post_id = :pid"),
        {"uid": user_id, "pid": post_id},
    )).scalar()
    if exist is None:
        raise BusinessException("未收藏该帖子")
    await db.execute(
        text("DELETE FROM post_favorite WHERE user_id = :uid AND post_id = :pid"),
        {"uid": user_id, "pid": post_id},
    )
    await db.execute(
        text("UPDATE post SET favorite_count = favorite_count - 1 WHERE id = :id AND favorite_count > 0"),
        {"id": post_id},
    )
    await db.commit()


async def is_favorited(db, post_id, user_id) -> bool:
    return (await db.execute(
        text("SELECT 1 FROM post_favorite WHERE user_id = :uid AND post_id = :pid"),
        {"uid": user_id, "pid": post_id},
    )).scalar() is not None


async def recommend(db, id_, user_id, role):
    if role != "admin":
        raise BusinessException("仅管理员可推荐帖子")
    row = (await db.execute(text("SELECT id FROM post WHERE id = :id"), {"id": id_})).scalar()
    if row is None:
        raise BusinessException("帖子不存在")
    await db.execute(text("UPDATE post SET is_recommended = 0 WHERE is_recommended = 1"))
    await db.execute(
        text("UPDATE post SET is_recommended = 1, update_time = NOW() WHERE id = :id"), {"id": id_}
    )
    await db.commit()
