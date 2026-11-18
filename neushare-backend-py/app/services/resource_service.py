"""Resource read queries — raw SQL replicating ResourceMapper.xml exactly.

Column list, joins, WHERE conditions, ORDER BY and LIMIT all mirror the Java
mapper so responses (field names, sort order) are byte-identical.
"""
import uuid
from pathlib import Path
from typing import Optional

from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.cache.decorator import cached
from app.core.config import settings
from app.utils.paging import page_window
from app.core.exceptions import BusinessException
from app.services import notification_service
from app.utils.common import fmt_dt, file_exists

_ALLOWED_EXT = {
    "pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx", "txt", "md", "csv",
    "zip", "rar", "7z", "tar", "gz", "epub", "caj",
    "png", "jpg", "jpeg", "gif", "webp", "bmp",
    "mp3", "wav", "mp4", "avi", "mov",
}

_SELECT_COLS = (
    "r.id, r.title, r.category_id, c.name AS category_name, r.type, r.content_url, "
    "r.description, r.cover_url, r.source, r.tags, r.upload_user_id, r.status, "
    "r.view_count, r.like_count, r.favorite_count, r.create_time, r.update_time, "
    "r.course_name, r.teacher, r.school_year, r.term, "
    "u.username AS upload_username, u.nickname AS upload_nickname, u.avatar_url AS upload_avatar"
)
_FROM = " FROM resource r LEFT JOIN user u ON r.upload_user_id = u.id LEFT JOIN category c ON r.category_id = c.id"


def to_resource_vo(row: dict, favorite_time=None) -> dict:
    return {
        "id": row["id"],
        "title": row["title"],
        "categoryId": row.get("category_id"),
        "categoryName": row.get("category_name"),
        "type": row["type"],
        "contentUrl": row.get("content_url"),
        "fileExists": file_exists(row.get("content_url")),
        "description": row.get("description"),
        "coverUrl": row.get("cover_url"),
        "source": row.get("source"),
        "tags": row.get("tags"),
        "uploadUserId": row["upload_user_id"],
        "status": row["status"],
        "viewCount": row["view_count"],
        "likeCount": row["like_count"],
        "favoriteCount": row["favorite_count"],
        "createTime": fmt_dt(row.get("create_time")),
        "updateTime": fmt_dt(row.get("update_time")),
        "uploadUsername": row.get("upload_username"),
        "uploadNickname": row.get("upload_nickname"),
        "uploadAvatar": row.get("upload_avatar"),
        "favoriteTime": fmt_dt(favorite_time),
        "courseName": row.get("course_name"),
        "teacher": row.get("teacher"),
        "schoolYear": row.get("school_year"),
        "term": row.get("term"),
        "relevance": row.get("relevance"),
    }


def _order(sort_by: str) -> str:
    """原有契约：hot 按浏览+点赞，其余按时间倒序。
    relevance 排序由 search_service 在带全文表达式时单独处理，这里安全降级为时间序，
    避免旧库未建 ngram 索引时生成引用不存在列的 SQL。"""
    if sort_by == "hot":
        return "r.view_count DESC, r.like_count DESC"
    return "r.create_time DESC"


def _build_where(status=None, category_id=None, keyword=None, user_id=None, force_status=None):
    """Return (where_clauses_list, params_dict)."""
    where = ["1=1"]
    params = {}
    if force_status is not None:
        where.append("r.status = :status"); params["status"] = force_status
    elif status is not None:
        where.append("r.status = :status"); params["status"] = status
    if category_id is not None:
        where.append("r.category_id = :category_id"); params["category_id"] = category_id
    if keyword:
        where.append("(r.title LIKE CONCAT('%',:keyword,'%') OR r.description LIKE CONCAT('%',:keyword,'%') OR r.tags LIKE CONCAT('%',:keyword,'%'))")
        params["keyword"] = keyword
    if user_id is not None:
        where.append("r.upload_user_id = :user_id"); params["user_id"] = user_id
    return where, params


async def _paginate(db, where, params, order, page_num, page_size):
    where_sql = " AND ".join(where)
    window = page_window(page_num, page_size)
    total = 0
    if window.count_rows:
        total = (await db.execute(text(f"SELECT COUNT(*) {_FROM} WHERE {where_sql}"), params)).scalar() or 0
    sql = f"SELECT {_SELECT_COLS} {_FROM} WHERE {where_sql} ORDER BY {order} LIMIT :size OFFSET :offset"
    p = {**params, "size": window.size, "offset": window.offset}
    rows = (await db.execute(text(sql), p)).mappings().all()
    records = [to_resource_vo(dict(r)) for r in rows]
    return records, total


@cached(key=lambda db, limit: f"res:hot:{limit}", ttl=60)
async def get_hot(db: AsyncSession, limit: int) -> list:
    sql = f"SELECT {_SELECT_COLS} {_FROM} WHERE r.status = 1 ORDER BY r.view_count DESC, r.like_count DESC LIMIT :limit"
    rows = (await db.execute(text(sql), {"limit": limit})).mappings().all()
    return [to_resource_vo(dict(r)) for r in rows]


async def get_page(db, page_num, page_size, status=None, category_id=None, keyword=None, sort_by="new"):
    where, params = _build_where(status=status, category_id=category_id, keyword=keyword)
    return await _paginate(db, where, params, _order(sort_by), page_num, page_size)


async def get_detail(db, rid):
    sql = f"SELECT {_SELECT_COLS} {_FROM} WHERE r.id = :id"
    row = (await db.execute(text(sql), {"id": rid})).mappings().first()
    return None if row is None else to_resource_vo(dict(row))


async def increment_view(db, rid):
    await db.execute(text("UPDATE resource SET view_count = view_count + 1 WHERE id = :id"), {"id": rid})
    await db.commit()


async def search_page(db, page_num, page_size, keyword, sort_by="new"):
    where, params = _build_where(force_status=1, keyword=keyword)
    return await _paginate(db, where, params, _order(sort_by), page_num, page_size)


async def get_user_resources(db, page_num, page_size, user_id):
    where, params = _build_where(user_id=user_id)
    return await _paginate(db, where, params, "r.create_time DESC", page_num, page_size)


async def get_user_resources_by_status(db, page_num, page_size, user_id, status):
    """Public user-profile view: only published resources are visible."""
    where, params = _build_where(user_id=user_id, force_status=status)
    return await _paginate(db, where, params, "r.create_time DESC", page_num, page_size)


# ---------------- upload + writes (mirrors ResourceServiceImpl create/update/delete/like) ----------------

async def save_upload_file(file) -> str:
    """Save an uploaded file to uploads dir; return stored filename (mirrors FileUploadUtil)."""
    if file is None or not getattr(file, "filename", None):
        raise BusinessException("文件为空", 400)
    name = file.filename
    dot = name.rfind(".")
    ext = name[dot + 1:].lower() if dot >= 0 else ""
    if not ext or ext not in _ALLOWED_EXT:
        raise BusinessException(f"不支持的文件类型：{ext if ext else '无扩展名'}", 400)
    content = await file.read()
    if not content:
        raise BusinessException("文件为空", 400)
    filename = uuid.uuid4().hex + "." + ext
    upload_dir = settings.upload_dir.resolve()
    upload_dir.mkdir(parents=True, exist_ok=True)
    (upload_dir / filename).write_bytes(content)
    return filename


def _safe_delete_physical(content_url):
    if not content_url or is_external_url(content_url):
        return
    try:
        upload_dir = settings.upload_dir.resolve()
        target = (upload_dir / content_url).resolve()
        target.relative_to(upload_dir)
        if target.is_file():
            target.unlink()
    except Exception:
        pass


def _norm_tags(val):
    if val is None or isinstance(val, str):
        return val
    import json
    return json.dumps(val, ensure_ascii=False)


async def create(db, user_id, dto):
    content_url = dto.get("contentUrl")
    if not content_url or not str(content_url).strip():
        raise BusinessException("请上传资源文件或填写资源链接", 400)
    rtype = dto.get("type") or "document"
    await db.execute(text(
        "INSERT INTO resource (title, category_id, type, content_url, description, cover_url, source, tags, "
        "upload_user_id, status, view_count, like_count, favorite_count, create_time, update_time) "
        "VALUES (:title, :cid, :type, :curl, :desc_, :cover, :source, :tags, :uid, 0, 0, 0, 0, NOW(), NOW())"
    ), {
        "title": dto.get("title"), "cid": dto.get("categoryId"), "type": rtype, "curl": content_url,
        "desc_": dto.get("description"), "cover": dto.get("coverUrl"), "source": dto.get("source"),
        "tags": _norm_tags(dto.get("tags")), "uid": user_id,
    })
    await db.execute(text("UPDATE user SET resource_count = resource_count + 1 WHERE id = :id"), {"id": user_id})
    await db.commit()


async def update(db, user_id, role, dto):
    rid = dto.get("id")
    row = (await db.execute(
        text("SELECT upload_user_id FROM resource WHERE id = :id"), {"id": rid}
    )).mappings().first()
    if row is None:
        raise BusinessException("资源不存在")
    if dict(row)["upload_user_id"] != user_id and role != "admin":
        raise BusinessException("无权修改此资源")
    field_map = [
        ("title", "title"), ("categoryId", "category_id"), ("type", "type"),
        ("contentUrl", "content_url"), ("description", "description"),
        ("coverUrl", "cover_url"), ("source", "source"), ("tags", "tags"),
    ]
    sets, params = [], {"id": rid}
    for key, col in field_map:
        if dto.get(key) is not None:
            val = _norm_tags(dto[key]) if key == "tags" else dto[key]
            sets.append(f"{col} = :{key}")
            params[key] = val
    if role != "admin":
        sets.append("status = 0")
        sets.append("reject_reason = NULL")
    sets.append("update_time = NOW()")
    await db.execute(text(f"UPDATE resource SET {', '.join(sets)} WHERE id = :id"), params)
    await db.commit()


async def delete(db, id_, user_id, role):
    row = (await db.execute(
        text("SELECT upload_user_id, content_url FROM resource WHERE id = :id"), {"id": id_}
    )).mappings().first()
    if row is None:
        raise BusinessException("资源不存在")
    row = dict(row)
    if row["upload_user_id"] != user_id and role != "admin":
        raise BusinessException("无权删除此资源")
    await db.execute(text("DELETE FROM comment WHERE resource_id = :id"), {"id": id_})
    await db.execute(text("DELETE FROM favorite WHERE resource_id = :id"), {"id": id_})
    await db.execute(text("DELETE FROM resource_like WHERE resource_id = :id"), {"id": id_})
    _safe_delete_physical(row.get("content_url"))
    await db.execute(text("DELETE FROM resource WHERE id = :id"), {"id": id_})
    await db.execute(
        text("UPDATE user SET resource_count = resource_count - 1 WHERE id = :uid AND resource_count > 0"),
        {"uid": row["upload_user_id"]},
    )
    await db.commit()


async def like(db, resource_id, user_id):
    row = (await db.execute(
        text("SELECT id, upload_user_id, title FROM resource WHERE id = :id"), {"id": resource_id}
    )).mappings().first()
    if row is None:
        raise BusinessException("资源不存在")
    row = dict(row)
    exist = (await db.execute(
        text("SELECT id FROM resource_like WHERE user_id = :uid AND resource_id = :rid"),
        {"uid": user_id, "rid": resource_id},
    )).scalar()
    if exist is not None:
        raise BusinessException("已点赞该资源")
    try:
        await db.execute(
            text("INSERT INTO resource_like (user_id, resource_id, create_time) VALUES (:uid, :rid, NOW())"),
            {"uid": user_id, "rid": resource_id},
        )
    except IntegrityError:
        await db.rollback()
        raise BusinessException("已点赞该资源")
    await db.execute(text("UPDATE resource SET like_count = like_count + 1 WHERE id = :id"), {"id": resource_id})
    await db.execute(
        text("UPDATE user SET total_likes_received = total_likes_received + 1 WHERE id = :id"),
        {"id": row["upload_user_id"]},
    )
    if row["upload_user_id"] != user_id:
        nick = await notification_service.get_nickname(db, user_id)
        await notification_service.send(
            db, row["upload_user_id"], "like", resource_id, user_id,
            "有人点赞了你的资源", f"{nick} 点赞了你的资源「{row['title']}」。"
        )
    await db.commit()


async def unlike(db, resource_id, user_id):
    row = (await db.execute(
        text("SELECT id, upload_user_id FROM resource WHERE id = :id"), {"id": resource_id}
    )).mappings().first()
    if row is None:
        raise BusinessException("资源不存在")
    row = dict(row)
    exist = (await db.execute(
        text("SELECT id FROM resource_like WHERE user_id = :uid AND resource_id = :rid"),
        {"uid": user_id, "rid": resource_id},
    )).scalar()
    if exist is None:
        raise BusinessException("未点赞该资源")
    await db.execute(
        text("DELETE FROM resource_like WHERE user_id = :uid AND resource_id = :rid"),
        {"uid": user_id, "rid": resource_id},
    )
    await db.execute(
        text("UPDATE resource SET like_count = like_count - 1 WHERE id = :id AND like_count > 0"),
        {"id": resource_id},
    )
    await db.execute(
        text("UPDATE user SET total_likes_received = total_likes_received - 1 "
             "WHERE id = :id AND total_likes_received > 0"),
        {"id": row["upload_user_id"]},
    )
    await db.commit()


async def is_liked(db, resource_id, user_id) -> bool:
    return (await db.execute(
        text("SELECT 1 FROM resource_like WHERE user_id = :uid AND resource_id = :rid"),
        {"uid": user_id, "rid": resource_id},
    )).scalar() is not None


def is_external_url(content_url) -> bool:
    return bool(content_url) and (content_url.startswith("http://") or content_url.startswith("https://"))


def resolve_download_path(content_url) -> Path:
    """Return resolved Path inside upload dir, or raise BusinessException. Mirrors resolveDownloadFile."""
    if not content_url:
        raise BusinessException("资源未关联文件")
    if is_external_url(content_url):
        raise BusinessException("该资源为外部链接，请直接访问原地址")
    upload_dir = settings.upload_dir.resolve()
    try:
        target = (upload_dir / content_url).resolve()
        target.relative_to(upload_dir)
    except (ValueError, OSError):
        raise BusinessException("文件不存在或已丢失", 404)
    if not target.is_file():
        raise BusinessException("文件不存在或已丢失", 404)
    return target


# ---------------- admin audit (mirrors ResourceServiceImpl.auditResource) ----------------

async def audit(db, id_, status, reject_reason, admin_user_id):
    """通过/驳回资源并推送审核通知。

    与 Java 一致：status=1 前校验物理文件存在（外链跳过），否则拒绝审核；
    驳回时仅当 rejectReason 非空才写入 reject_reason。
    """
    row = (await db.execute(
        text("SELECT id, title, content_url, upload_user_id FROM resource WHERE id = :id"), {"id": id_}
    )).mappings().first()
    if row is None:
        raise BusinessException("资源不存在")
    r = dict(row)
    if status == 1 and not is_external_url(r.get("content_url")) and not file_exists(r.get("content_url")):
        raise BusinessException("资源文件不存在，无法通过审核，请重新上传")

    sets = ["status = :status", "update_time = NOW()"]
    params = {"id": id_, "status": status}
    if status == 2 and reject_reason:
        sets.append("reject_reason = :reason")
        params["reason"] = reject_reason
    await db.execute(text(f"UPDATE resource SET {', '.join(sets)} WHERE id = :id"), params)

    title = "资源审核通过" if status == 1 else "资源已被驳回"
    if status == 1:
        content = f"您上传的资源「{r['title']}」已通过审核，现已公开发布。"
    else:
        content = f"您上传的资源「{r['title']}」已被驳回"
        content += f"，原因：{reject_reason}" if reject_reason else "。"
    await notification_service.send(db, r["upload_user_id"], "audit", id_, admin_user_id, title, content)
    await db.commit()
