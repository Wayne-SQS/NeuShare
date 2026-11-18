"""Auth business logic — mirrors UserServiceImpl.login / register exactly.

Validation messages and error codes replicate the Java @NotBlank/@Size messages
and BusinessException defaults so the frontend sees identical responses.
"""
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User
from app.core.security import verify_password, hash_password, create_token
from app.core.exceptions import BusinessException


async def get_by_username(db: AsyncSession, username: str):
    res = await db.execute(select(User).where(User.username == username))
    return res.scalar_one_or_none()


async def get_by_id(db: AsyncSession, user_id: int):
    res = await db.execute(select(User).where(User.id == user_id))
    return res.scalar_one_or_none()


def to_user_vo(user) -> dict:
    return {
        "id": user.id,
        "username": user.username,
        "role": user.role,
        "nickname": user.nickname,
        "avatarUrl": user.avatar_url,
        "college": user.college,
        "grade": user.grade,
        "status": user.status,
    }


def _validate_login(username, password):
    if not username or not str(username).strip():
        raise BusinessException("用户名不能为空", 400)
    if not password:
        raise BusinessException("密码不能为空", 400)


async def login(db: AsyncSession, username, password) -> dict:
    _validate_login(username, password)
    user = await get_by_username(db, username)
    if user is None or not verify_password(password, user.password or ""):
        raise BusinessException("用户名或密码错误")
    if user.status == 0:
        raise BusinessException("账号已被禁用")
    token = create_token(user.id, user.username, user.role or "user")
    return {"token": token, "user": to_user_vo(user)}


def _validate_register(dto: dict):
    username = dto.get("username")
    password = dto.get("password")
    if not username or not str(username).strip():
        raise BusinessException("用户名不能为空", 400)
    if len(username) < 3 or len(username) > 20:
        raise BusinessException("用户名长度需为 3-20 位", 400)
    if not password:
        raise BusinessException("密码不能为空", 400)
    if len(password) < 6 or len(password) > 32:
        raise BusinessException("密码长度需为 6-32 位", 400)


async def register(db: AsyncSession, dto: dict):
    _validate_register(dto)
    existing = await get_by_username(db, dto["username"])
    if existing is not None:
        raise BusinessException("用户名已存在")
    user = User(
        username=dto["username"],
        password=hash_password(dto["password"]),
        nickname=dto.get("nickname") or dto["username"],
        avatar_url=dto.get("avatarUrl"),
        college=dto.get("college"),
        grade=dto.get("grade"),
        role="student",
        status=1,
    )
    db.add(user)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise BusinessException("用户名已存在")


# ---------- current-user info / password (mirrors AuthController GET/PUT /info, PUT /password) ----------

async def get_user_vo(db: AsyncSession, user_id: int):
    user = await get_by_id(db, user_id)
    return None if user is None else to_user_vo(user)


async def update_info(db: AsyncSession, user_id: int, dto: dict):
    user = await get_by_id(db, user_id)
    if user is None:
        raise BusinessException("用户不存在")
    if dto.get("nickname") is not None:
        user.nickname = dto["nickname"]
    if dto.get("avatarUrl") is not None:
        user.avatar_url = dto["avatarUrl"]
    if dto.get("college") is not None:
        user.college = dto["college"]
    if dto.get("grade") is not None:
        user.grade = dto["grade"]
    await db.commit()


async def update_password(db: AsyncSession, user_id: int, old_pwd, new_pwd):
    user = await get_by_id(db, user_id)
    if user is None:
        raise BusinessException("用户不存在")
    if not new_pwd or len(new_pwd) < 6 or len(new_pwd) > 32:
        raise BusinessException("新密码长度需为 6-32 位", 400)
    if old_pwd is not None and old_pwd == new_pwd:
        raise BusinessException("新密码不能与旧密码相同", 400)
    if not verify_password(old_pwd, user.password or ""):
        raise BusinessException("旧密码错误")
    user.password = hash_password(new_pwd)
    await db.commit()
