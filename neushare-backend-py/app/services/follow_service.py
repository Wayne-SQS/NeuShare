"""Follow add/remove/check/following/followers — mirrors FollowServiceImpl + FollowMapper.xml."""
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.core.exceptions import BusinessException
from app.services import notification_service
from app.utils.paging import page_window

_USER_COLS = "u.id, u.username, u.role, u.nickname, u.avatar_url, u.college, u.grade, u.status"


def _user_vo(row: dict) -> dict:
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


async def add(db, follower_id, followed_id):
    if follower_id == followed_id:
        raise BusinessException("不能关注自己")
    u = (await db.execute(text("SELECT status FROM user WHERE id = :id"), {"id": followed_id})).mappings().first()
    if u is None or dict(u)["status"] == 0:
        raise BusinessException("用户不存在或已被禁用")
    exist = (await db.execute(
        text("SELECT id FROM follow WHERE follower_id = :fid AND followed_id = :eid"),
        {"fid": follower_id, "eid": followed_id},
    )).scalar()
    if exist is not None:
        raise BusinessException("已关注该用户")
    try:
        await db.execute(
            text("INSERT INTO follow (follower_id, followed_id, create_time) VALUES (:fid, :eid, NOW())"),
            {"fid": follower_id, "eid": followed_id},
        )
    except IntegrityError:
        await db.rollback()
        raise BusinessException("已关注该用户")
    await db.execute(text("UPDATE user SET following_count = following_count + 1 WHERE id = :id"), {"id": follower_id})
    await db.execute(text("UPDATE user SET follower_count = follower_count + 1 WHERE id = :id"), {"id": followed_id})
    nick = await notification_service.get_nickname(db, follower_id)
    await notification_service.send(
        db, followed_id, "follow", None, follower_id, "有人关注了你", f"{nick} 关注了你。"
    )
    await db.commit()


async def remove(db, follower_id, followed_id):
    exist = (await db.execute(
        text("SELECT id FROM follow WHERE follower_id = :fid AND followed_id = :eid"),
        {"fid": follower_id, "eid": followed_id},
    )).scalar()
    if exist is None:
        raise BusinessException("未关注该用户")
    await db.execute(
        text("DELETE FROM follow WHERE follower_id = :fid AND followed_id = :eid"),
        {"fid": follower_id, "eid": followed_id},
    )
    await db.execute(
        text("UPDATE user SET following_count = following_count - 1 WHERE id = :id AND following_count > 0"),
        {"id": follower_id},
    )
    await db.execute(
        text("UPDATE user SET follower_count = follower_count - 1 WHERE id = :id AND follower_count > 0"),
        {"id": followed_id},
    )
    await db.commit()


async def is_following(db, follower_id, followed_id) -> bool:
    return (await db.execute(
        text("SELECT 1 FROM follow WHERE follower_id = :fid AND followed_id = :eid"),
        {"fid": follower_id, "eid": followed_id},
    )).scalar() is not None


async def get_following(db, page_num, page_size, user_id):
    base = " FROM follow f JOIN user u ON f.followed_id = u.id WHERE f.follower_id = :uid"
    window = page_window(page_num, page_size)
    total = 0
    if window.count_rows:
        total = (await db.execute(text(f"SELECT COUNT(*) {base}"), {"uid": user_id})).scalar() or 0
    rows = (await db.execute(text(
        f"SELECT {_USER_COLS} {base} ORDER BY f.create_time DESC LIMIT :size OFFSET :offset"
    ), {"uid": user_id, "size": window.size, "offset": window.offset})).mappings().all()
    return [_user_vo(dict(r)) for r in rows], total


async def get_followers(db, page_num, page_size, user_id):
    base = " FROM follow f JOIN user u ON f.follower_id = u.id WHERE f.followed_id = :uid"
    window = page_window(page_num, page_size)
    total = 0
    if window.count_rows:
        total = (await db.execute(text(f"SELECT COUNT(*) {base}"), {"uid": user_id})).scalar() or 0
    rows = (await db.execute(text(
        f"SELECT {_USER_COLS} {base} ORDER BY f.create_time DESC LIMIT :size OFFSET :offset"
    ), {"uid": user_id, "size": window.size, "offset": window.offset})).mappings().all()
    return [_user_vo(dict(r)) for r in rows], total
