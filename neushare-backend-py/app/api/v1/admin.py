"""Admin routes — mirrors AdminController (19 endpoints under /api/admin/**).

All routes require role="admin": the router-level dependency raises 401 (no token)
or 403 (non-admin) exactly like the Java JwtInterceptor. FastAPI caches the
dependency per request, so the token is still decoded only once.
"""
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success, success_page
from app.db.session import get_db
from app.middleware.auth import get_current_admin
from app.services import (
    banner_service,
    comment_service,
    formcard_service,
    resource_service,
    stats_service,
    user_service,
)

router = APIRouter(prefix="/api/admin", tags=["admin"], dependencies=[Depends(get_current_admin)])


# ==================== 用户管理 ====================

@router.get("/user/list")
async def get_user_list(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    keyword: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
):
    records, total = await user_service.get_admin_page(db, pageNum, pageSize, keyword)
    return success_page(records, total, pageNum, pageSize)


@router.put("/user/status")
async def update_user_status(
    id: int = Query(...),
    status: int = Query(...),
    db: AsyncSession = Depends(get_db),
):
    await user_service.set_status(db, id, status)
    return success("更新成功")


@router.delete("/user/delete/{id}")
async def delete_user(id: int, db: AsyncSession = Depends(get_db)):
    await user_service.delete_cascade(db, id)
    return success("删除成功")


# ==================== 资源管理 ====================

@router.get("/resource/pending")
async def get_pending_resources(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    db: AsyncSession = Depends(get_db),
):
    records, total = await resource_service.get_page(db, pageNum, pageSize, status=0)
    return success_page(records, total, pageNum, pageSize)


@router.put("/resource/audit")
async def audit_resource(
    id: int = Query(...),
    status: int = Query(...),
    rejectReason: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(get_current_admin),
):
    await resource_service.audit(db, id, status, rejectReason, admin["userId"])
    return success("审核成功")


@router.delete("/resource/delete/{id}")
async def delete_resource(
    id: int,
    db: AsyncSession = Depends(get_db),
    admin: dict = Depends(get_current_admin),
):
    await resource_service.delete(db, id, admin["userId"], "admin")
    return success("删除成功")


# ==================== 评论管理 ====================

@router.get("/comment/list")
async def get_comment_list(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    db: AsyncSession = Depends(get_db),
):
    records, total = await comment_service.get_admin_page(db, pageNum, pageSize)
    return success_page(records, total, pageNum, pageSize)


@router.delete("/comment/delete/{id}")
async def delete_comment(id: int, db: AsyncSession = Depends(get_db)):
    await comment_service.admin_delete(db, id)
    return success("删除成功")


# ==================== 轮播图管理 ====================

@router.get("/banner/list")
async def get_banner_list(db: AsyncSession = Depends(get_db)):
    return success(await banner_service.get_all(db))


@router.post("/banner/add")
async def add_banner(payload: dict, db: AsyncSession = Depends(get_db)):
    await banner_service.add(db, payload)
    return success("添加成功")


@router.put("/banner/update")
async def update_banner(payload: dict, db: AsyncSession = Depends(get_db)):
    await banner_service.update(db, payload)
    return success("更新成功")


@router.delete("/banner/delete/{id}")
async def delete_banner(id: int, db: AsyncSession = Depends(get_db)):
    await banner_service.delete(db, id)
    return success("删除成功")


@router.put("/banner/status")
async def update_banner_status(
    id: int = Query(...),
    status: int = Query(...),
    db: AsyncSession = Depends(get_db),
):
    await banner_service.set_status(db, id, status)
    return success("更新成功")


# ==================== 服务卡片管理 ====================

@router.get("/form-card/list")
async def get_form_card_list(db: AsyncSession = Depends(get_db)):
    return success(await formcard_service.get_all(db))


@router.post("/form-card/add")
async def add_form_card(payload: dict, db: AsyncSession = Depends(get_db)):
    await formcard_service.add(db, payload)
    return success("添加成功")


@router.put("/form-card/update")
async def update_form_card(payload: dict, db: AsyncSession = Depends(get_db)):
    await formcard_service.update(db, payload)
    return success("更新成功")


@router.delete("/form-card/delete/{id}")
async def delete_form_card(id: int, db: AsyncSession = Depends(get_db)):
    await formcard_service.delete(db, id)
    return success("删除成功")


@router.put("/form-card/status")
async def update_form_card_status(
    id: int = Query(...),
    status: int = Query(...),
    db: AsyncSession = Depends(get_db),
):
    await formcard_service.set_status(db, id, status)
    return success("更新成功")


# ==================== 统计数据 ====================

@router.get("/statistics")
async def get_statistics(db: AsyncSession = Depends(get_db)):
    return success(await stats_service.get_admin_statistics(db))
