from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BusinessException
from app.core.response import success
from app.db.session import get_db
from app.middleware.auth import get_current_user
from app.services import auth_service

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/login")
async def login(payload: dict, db: AsyncSession = Depends(get_db)):
    # 与 Java @Valid LoginDTO 对齐：空字段报「xxx不能为空」，code=400
    blank = []
    if not str(payload.get("username") or "").strip():
        blank.append("用户名不能为空")
    if not str(payload.get("password") or "").strip():
        blank.append("密码不能为空")
    if blank:
        raise BusinessException(", ".join(blank), 400)
    result = await auth_service.login(db, payload.get("username"), payload.get("password"))
    return success(result, "登录成功")


@router.post("/register")
async def register(payload: dict, db: AsyncSession = Depends(get_db)):
    await auth_service.register(db, payload)
    return success(None, "注册成功")


@router.get("/info")
async def get_user_info(db: AsyncSession = Depends(get_db), user: dict = Depends(get_current_user)):
    vo = await auth_service.get_user_vo(db, user["userId"])
    return success(vo)


@router.put("/info")
async def update_user_info(
    payload: dict,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await auth_service.update_info(db, user["userId"], payload)
    return success(None, "更新成功")


@router.put("/password")
async def update_password(
    oldPassword: str = Query(...),
    newPassword: str = Query(...),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await auth_service.update_password(db, user["userId"], oldPassword, newPassword)
    return success(None, "密码修改成功")
