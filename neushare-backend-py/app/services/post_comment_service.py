"""Post comment tree queries — mirrors PostCommentMapper.xml + PostCommentServiceImpl.

Difference from resource comments (CommentServiceImpl):
  - ORDER BY pc.create_time ASC (oldest first)
  - deleted children are NOT pruned (the tree keeps soft-deleted nodes so the
    conversation structure stays intact; content is replaced by "该评论已被删除")
"""
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.core.exceptions import BusinessException
from app.services import notification_service
from app.services.comment_service import _build_tree
from app.utils.common import fmt_dt

_SELECT = "pc.id, pc.post_id, pc.user_id, pc.content, pc.parent_id, pc.deleted, pc.create_time, u.nickname, u.avatar_url"
_FROM = " FROM post_comment pc LEFT JOIN user u ON pc.user_id = u.id"


def to_post_comment_vo(row: dict) -> dict:
    return {
        "id": row["id"],
        "postId": row["post_id"],
        "userId": row["user_id"],
        "content": row.get("content"),
        "parentId": row.get("parent_id"),
        "deleted": row.get("deleted"),
        "createTime": fmt_dt(row.get("create_time")),
        "nickname": row.get("nickname"),
        "avatarUrl": row.get("avatar_url"),
    }


async def get_tree(db, post_id) -> list:
    sql = f"SELECT {_SELECT} {_FROM} WHERE pc.post_id = :pid ORDER BY pc.create_time ASC"
    rows = [dict(r) for r in (await db.execute(text(sql), {"pid": post_id})).mappings().all()]
    nodes = [to_post_comment_vo(r) for r in rows]
    return _build_tree(nodes, skip_deleted_children=False)


# ---------------- writes (mirrors PostCommentServiceImpl add/delete/like) ----------------

async def add(db, post_id, user_id, content, parent_id):
    await db.execute(
        text("INSERT INTO post_comment (post_id, user_id, content, parent_id, deleted, create_time, update_time) "
             "VALUES (:pid, :uid, :content, :par, 0, NOW(), NOW())"),
        {"pid": post_id, "uid": user_id, "content": content, "par": parent_id if parent_id else 0},
    )
    await db.execute(text("UPDATE post SET comment_count = comment_count + 1 WHERE id = :id"), {"id": post_id})
    post = (await db.execute(
        text("SELECT user_id, title FROM post WHERE id = :id"), {"id": post_id}
    )).mappings().first()
    post = dict(post) if post is not None else None
    if post is not None and post["user_id"] != user_id:
        nick = await notification_service.get_nickname(db, user_id)
        await notification_service.send(
            db, post["user_id"], "comment", post_id, user_id,
            "有人评论了你的帖子", f"{nick} 评论了你的帖子「{post['title']}」。"
        )
    if parent_id and parent_id > 0:
        pc = (await db.execute(
            text("SELECT user_id FROM post_comment WHERE id = :id"), {"id": parent_id}
        )).mappings().first()
        if pc is not None and dict(pc)["user_id"] != user_id:
            nick = await notification_service.get_nickname(db, user_id)
            title = post["title"] if post is not None else "未知帖子"
            await notification_service.send(
                db, dict(pc)["user_id"], "comment", post_id, user_id,
                "有人回复了你的评论", f"在帖子「{title}」中，{nick} 回复了你的评论。"
            )
    await db.commit()


async def delete(db, id_, user_id, role):
    c = (await db.execute(
        text("SELECT user_id, post_id FROM post_comment WHERE id = :id"), {"id": id_}
    )).mappings().first()
    if c is None:
        raise BusinessException("评论不存在")
    c = dict(c)
    if c["user_id"] != user_id and role != "admin":
        raise BusinessException("无权删除此评论")
    await db.execute(
        text("UPDATE post_comment SET deleted = 1, content = '该评论已被删除', update_time = NOW() WHERE id = :id"),
        {"id": id_},
    )
    try:
        await db.execute(
            text("UPDATE post SET comment_count = comment_count - 1 WHERE id = :pid AND comment_count > 0"),
            {"pid": c["post_id"]},
        )
    except Exception:
        pass  # 计数校准失败不影响删除（对齐 Java）
    await db.commit()


async def like(db, comment_id, user_id):
    c = (await db.execute(text("SELECT 1 FROM post_comment WHERE id = :id"), {"id": comment_id})).scalar()
    if c is None:
        raise BusinessException("评论不存在")
    exist = (await db.execute(
        text("SELECT id FROM post_comment_like WHERE user_id = :uid AND comment_id = :cid"),
        {"uid": user_id, "cid": comment_id},
    )).scalar()
    if exist is not None:
        raise BusinessException("已经点过赞了")
    try:
        await db.execute(
            text("INSERT INTO post_comment_like (user_id, comment_id, create_time) VALUES (:uid, :cid, NOW())"),
            {"uid": user_id, "cid": comment_id},
        )
    except IntegrityError:
        await db.rollback()
        raise BusinessException("已经点过赞了")
    await db.execute(
        text("UPDATE post_comment SET like_count = like_count + 1 WHERE id = :id"), {"id": comment_id}
    )
    await db.commit()


async def unlike(db, comment_id, user_id):
    c = (await db.execute(text("SELECT 1 FROM post_comment WHERE id = :id"), {"id": comment_id})).scalar()
    if c is None:
        raise BusinessException("评论不存在")
    exist = (await db.execute(
        text("SELECT id FROM post_comment_like WHERE user_id = :uid AND comment_id = :cid"),
        {"uid": user_id, "cid": comment_id},
    )).scalar()
    if exist is None:
        raise BusinessException("还没有点赞")
    await db.execute(
        text("DELETE FROM post_comment_like WHERE user_id = :uid AND comment_id = :cid"),
        {"uid": user_id, "cid": comment_id},
    )
    await db.execute(
        text("UPDATE post_comment SET like_count = like_count - 1 WHERE id = :id AND like_count > 0"),
        {"id": comment_id},
    )
    await db.commit()


async def is_liked(db, comment_id, user_id) -> bool:
    return (await db.execute(
        text("SELECT 1 FROM post_comment_like WHERE user_id = :uid AND comment_id = :cid"),
        {"uid": user_id, "cid": comment_id},
    )).scalar() is not None
