"""Resource comment queries + O(n) tree building (mirrors CommentMapper/ServiceImpl)."""
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.core.exceptions import BusinessException
from app.services import notification_service
from app.utils.common import fmt_dt
from app.utils.paging import page_window

_SELECT = ("c.id, c.resource_id, c.user_id, c.content, c.parent_id, c.deleted, c.create_time, "
           "u.username, u.nickname, u.avatar_url")
_FROM = " FROM comment c LEFT JOIN user u ON c.user_id = u.id"


def to_comment_vo(row: dict) -> dict:
    return {
        "id": row["id"], "resourceId": row["resource_id"], "userId": row["user_id"],
        "content": row["content"], "parentId": row["parent_id"], "deleted": row["deleted"],
        "createTime": fmt_dt(row.get("create_time")), "username": row.get("username"),
        "nickname": row.get("nickname"), "avatarUrl": row.get("avatar_url"),
        # 扁平列表（/api/comment/user）里 Java 的 CommentVO.children 为 null；
        # 树形接口会由 _build_tree 覆盖成 []。
        "children": None,
    }


def _build_tree(nodes: list, skip_deleted_children: bool) -> list:
    by_id = {n["id"]: n for n in nodes}
    for n in nodes:
        n["children"] = []
    roots = []
    for n in nodes:
        pid = n["parentId"]
        if pid is None or pid == 0:
            roots.append(n)
            continue
        parent = by_id.get(pid)
        if parent is None:
            continue  # orphan → dropped (matches Java)
        if skip_deleted_children and n.get("deleted") == 1:
            continue  # resource comments: deleted children vanish
        parent["children"].append(n)
    return roots


async def get_tree(db, resource_id) -> list:
    sql = f"SELECT {_SELECT} {_FROM} WHERE c.resource_id = :rid ORDER BY c.create_time DESC"
    rows = [dict(r) for r in (await db.execute(text(sql), {"rid": resource_id})).mappings().all()]
    nodes = [to_comment_vo(r) for r in rows]
    return _build_tree(nodes, skip_deleted_children=True)


async def get_user_comments_page(db, page_num, page_size, user_id):
    where = "c.user_id = :user_id"; params = {"user_id": user_id}
    window = page_window(page_num, page_size)
    total = 0
    if window.count_rows:
        total = (await db.execute(text(f"SELECT COUNT(*) {_FROM} WHERE {where}"), params)).scalar() or 0
    sql = f"SELECT {_SELECT} {_FROM} WHERE {where} ORDER BY c.create_time DESC LIMIT :size OFFSET :offset"
    p = {**params, "size": window.size, "offset": window.offset}
    rows = (await db.execute(text(sql), p)).mappings().all()
    return [to_comment_vo(dict(r)) for r in rows], total


_MY_SQL = text("""
SELECT * FROM (
    SELECT c.id, c.resource_id AS source_id, 'resource' AS source_type, r.title AS source_title,
           c.content, c.parent_id, c.deleted, c.create_time, c.like_count,
           (SELECT COUNT(*) FROM comment WHERE parent_id = c.id AND deleted = 0) AS reply_count
    FROM comment c LEFT JOIN resource r ON c.resource_id = r.id
    WHERE c.user_id = :uid AND c.deleted = 0
    UNION ALL
    SELECT pc.id, pc.post_id AS source_id, 'post' AS source_type, p.title AS source_title,
           pc.content, pc.parent_id, pc.deleted, pc.create_time, pc.like_count,
           (SELECT COUNT(*) FROM post_comment WHERE parent_id = pc.id AND deleted = 0) AS reply_count
    FROM post_comment pc LEFT JOIN post p ON pc.post_id = p.id
    WHERE pc.user_id = :uid AND pc.deleted = 0
) merged ORDER BY create_time DESC
""")


def to_my_comment_vo(row: dict) -> dict:
    return {
        "id": row["id"], "sourceId": row["source_id"], "sourceType": row["source_type"],
        "sourceTitle": row.get("source_title"), "content": row["content"],
        "parentId": row["parent_id"], "deleted": row["deleted"],
        "createTime": fmt_dt(row.get("create_time")), "likeCount": row["like_count"],
        "replyCount": row["reply_count"],
    }


async def get_my_comments_page(db, page_num, page_size, user_id):
    total = (await db.execute(text(
        "SELECT COUNT(*) FROM (SELECT id FROM comment WHERE user_id=:uid AND deleted=0 "
        "UNION ALL SELECT id FROM post_comment WHERE user_id=:uid AND deleted=0) t"),
        {"uid": user_id})).scalar() or 0
    window = page_window(page_num, page_size)
    p = {"uid": user_id, "size": window.size, "offset": window.offset}
    sql = "SELECT * FROM (" + _MY_SQL.text.replace(":uid", ":uid").strip() + ") AS m LIMIT :size OFFSET :offset"
    # simpler: append limit/offset to the union query directly
    full = text(_MY_SQL.text.strip().rstrip(';') + " LIMIT :size OFFSET :offset")
    rows = (await db.execute(full, p)).mappings().all()
    return [to_my_comment_vo(dict(r)) for r in rows], total


# ---------------- writes (mirrors CommentServiceImpl add/delete/like) ----------------

async def add(db, resource_id, user_id, content, parent_id):
    await db.execute(
        text("INSERT INTO comment (resource_id, user_id, content, parent_id, deleted, create_time, update_time) "
             "VALUES (:rid, :uid, :content, :pid, 0, NOW(), NOW())"),
        {"rid": resource_id, "uid": user_id, "content": content, "pid": parent_id if parent_id else 0},
    )
    if parent_id and parent_id > 0:
        pc = (await db.execute(
            text("SELECT user_id FROM comment WHERE id = :id"), {"id": parent_id}
        )).mappings().first()
        if pc is not None and dict(pc)["user_id"] != user_id:
            res = (await db.execute(
                text("SELECT title FROM resource WHERE id = :id"), {"id": resource_id}
            )).mappings().first()
            title = dict(res)["title"] if res is not None else "未知资源"
            await notification_service.send(
                db, dict(pc)["user_id"], "comment", resource_id, user_id,
                "有人回复了你的评论", f"在资源「{title}」中，有人回复了你的评论。"
            )
    await db.commit()


async def delete(db, id_, user_id):
    c = (await db.execute(
        text("SELECT user_id, resource_id FROM comment WHERE id = :id"), {"id": id_}
    )).mappings().first()
    if c is None:
        raise BusinessException("评论不存在")
    c = dict(c)
    is_owner = c["user_id"] == user_id
    if not is_owner:
        r = (await db.execute(
            text("SELECT upload_user_id FROM resource WHERE id = :id"), {"id": c["resource_id"]}
        )).mappings().first()
        if r is None or dict(r)["upload_user_id"] != user_id:
            raise BusinessException("无权删除此评论")
    await db.execute(
        text("UPDATE comment SET deleted = 1, content = '该评论已被删除', update_time = NOW() WHERE id = :id"),
        {"id": id_},
    )
    await db.commit()


async def like(db, comment_id, user_id):
    c = (await db.execute(text("SELECT 1 FROM comment WHERE id = :id"), {"id": comment_id})).scalar()
    if c is None:
        raise BusinessException("评论不存在")
    exist = (await db.execute(
        text("SELECT id FROM comment_like WHERE user_id = :uid AND comment_id = :cid"),
        {"uid": user_id, "cid": comment_id},
    )).scalar()
    if exist is not None:
        raise BusinessException("已经点过赞了")
    try:
        await db.execute(
            text("INSERT INTO comment_like (user_id, comment_id, create_time) VALUES (:uid, :cid, NOW())"),
            {"uid": user_id, "cid": comment_id},
        )
    except IntegrityError:
        await db.rollback()
        raise BusinessException("已经点过赞了")
    await db.execute(
        text("UPDATE comment SET like_count = like_count + 1 WHERE id = :id"), {"id": comment_id}
    )
    await db.commit()


async def unlike(db, comment_id, user_id):
    c = (await db.execute(text("SELECT 1 FROM comment WHERE id = :id"), {"id": comment_id})).scalar()
    if c is None:
        raise BusinessException("评论不存在")
    exist = (await db.execute(
        text("SELECT id FROM comment_like WHERE user_id = :uid AND comment_id = :cid"),
        {"uid": user_id, "cid": comment_id},
    )).scalar()
    if exist is None:
        raise BusinessException("还没有点赞")
    await db.execute(
        text("DELETE FROM comment_like WHERE user_id = :uid AND comment_id = :cid"),
        {"uid": user_id, "cid": comment_id},
    )
    await db.execute(
        text("UPDATE comment SET like_count = like_count - 1 WHERE id = :id AND like_count > 0"),
        {"id": comment_id},
    )
    await db.commit()


async def is_liked(db, comment_id, user_id) -> bool:
    return (await db.execute(
        text("SELECT 1 FROM comment_like WHERE user_id = :uid AND comment_id = :cid"),
        {"uid": user_id, "cid": comment_id},
    )).scalar() is not None


# ---------------- admin comment management (mirrors CommentMapper.selectCommentVOPage) ----------------

async def get_admin_page(db, page_num, page_size):
    """全部评论（含已标记删除），按创建时间倒序；children 为 null（Java 未构建树）。"""
    window = page_window(page_num, page_size)
    total = 0
    if window.count_rows:
        total = (await db.execute(text(f"SELECT COUNT(*) {_FROM}"))).scalar() or 0
    sql = f"SELECT {_SELECT} {_FROM} ORDER BY c.create_time DESC LIMIT :size OFFSET :offset"
    p = {"size": window.size, "offset": window.offset}
    rows = (await db.execute(text(sql), p)).mappings().all()
    records = []
    for r in rows:
        vo = to_comment_vo(dict(r))
        vo["children"] = None
        records.append(vo)
    return records, total


async def admin_delete(db, id_):
    """管理员硬删除单条评论（Java removeById，不留软删标记）。"""
    await db.execute(text("DELETE FROM comment WHERE id = :id"), {"id": id_})
    await db.commit()
