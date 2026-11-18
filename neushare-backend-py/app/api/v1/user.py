from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success, success_page, error
from app.db.session import get_db
from app.services import user_service, resource_service

router = APIRouter(prefix="/api/user", tags=["user"])


def _check_enabled(profile):
    """公开接口：用户不存在或已禁用 → 默认 code 500（对齐 Java Result.error(msg)）。"""
    if profile is None or profile.get("status") == 0:
        return error(500, "用户不存在或已被禁用")
    return None


@router.get("/{id}")
async def get_user_profile(id: int, db: AsyncSession = Depends(get_db)):
    profile = await user_service.get_profile(db, id)
    err = _check_enabled(profile)
    if err is not None:
        return err
    return success(profile)


@router.get("/{id}/resources")
async def get_user_resources(
    id: int,
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    db: AsyncSession = Depends(get_db),
):
    profile = await user_service.get_profile(db, id)
    err = _check_enabled(profile)
    if err is not None:
        return err
    records, total = await resource_service.get_user_resources_by_status(
        db, pageNum, pageSize, id, 1
    )
    return success_page(records, total, pageNum, pageSize)
