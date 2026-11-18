"""Resource favorite routes — mirrors FavoriteController (Java).

All endpoints require login. Note /check returns {"isFavorite": bool} (a map),
matching Java's Result<Map<String,Boolean>>, NOT a bare boolean.
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success, success_page
from app.db.session import get_db
from app.middleware.auth import get_current_user
from app.services import favorite_service

router = APIRouter(prefix="/api/favorite", tags=["favorite"])


@router.post("/add")
async def add_favorite(
    resourceId: int = Query(...),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await favorite_service.add(db, user["userId"], resourceId)
    return success("收藏成功")


@router.delete("/remove")
async def remove_favorite(
    resourceId: int = Query(...),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await favorite_service.remove(db, user["userId"], resourceId)
    return success("取消收藏成功")


@router.get("/check")
async def check_favorite(
    resourceId: int = Query(...),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    is_fav = await favorite_service.is_favorite(db, user["userId"], resourceId)
    return success({"isFavorite": is_fav})


@router.get("/list")
async def list_favorites(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    records, total = await favorite_service.get_page(db, pageNum, pageSize, user["userId"])
    return success_page(records, total, pageNum, pageSize)
