"""Notification routes — mirrors NotificationController (Java).

/unread returns a bare integer (Result<Integer>), matching Java exactly.
"""
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success, success_page
from app.db.session import get_db
from app.middleware.auth import get_current_user
from app.services import notification_service

router = APIRouter(prefix="/api/notification", tags=["notification"])


@router.get("/list")
async def list_notifications(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    type: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    records, total = await notification_service.get_page(
        db, pageNum, pageSize, user["userId"], type
    )
    return success_page(records, total, pageNum, pageSize)


@router.get("/unread")
async def unread_count(
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    count = await notification_service.count_unread(db, user["userId"])
    return success(count)


@router.put("/read/{id}")
async def mark_read(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await notification_service.mark_read(db, id, user["userId"])
    return success("已读")


@router.put("/read-all")
async def mark_all_read(
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await notification_service.mark_all_read(db, user["userId"])
    return success("全部已读")


@router.delete("/delete/{id}")
async def delete_notification(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await notification_service.delete(db, id, user["userId"])
    return success("删除成功")
