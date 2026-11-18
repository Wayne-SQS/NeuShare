"""Follow routes — mirrors FollowController (Java).

/check returns {"isFollowing": bool} (a map), matching Java's Result<Map<String,Boolean>>.
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success, success_page
from app.db.session import get_db
from app.middleware.auth import get_current_user
from app.services import follow_service

router = APIRouter(prefix="/api/follow", tags=["follow"])


@router.post("/add")
async def follow_user(
    followedId: int = Query(...),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await follow_service.add(db, user["userId"], followedId)
    return success("关注成功")


@router.delete("/remove")
async def unfollow_user(
    followedId: int = Query(...),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await follow_service.remove(db, user["userId"], followedId)
    return success("取消关注成功")


@router.get("/check")
async def check_follow(
    followedId: int = Query(...),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    is_following = await follow_service.is_following(db, user["userId"], followedId)
    return success({"isFollowing": is_following})


@router.get("/following")
async def get_following(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    records, total = await follow_service.get_following(db, pageNum, pageSize, user["userId"])
    return success_page(records, total, pageNum, pageSize)


@router.get("/followers")
async def get_followers(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    records, total = await follow_service.get_followers(db, pageNum, pageSize, user["userId"])
    return success_page(records, total, pageNum, pageSize)
