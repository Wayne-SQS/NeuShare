from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success, success_page
from app.db.session import get_db
from app.middleware.auth import get_current_user
from app.services import comment_service

router = APIRouter(prefix="/api/comment", tags=["comment"])


@router.get("/list/{resourceId}")
async def get_comments(resourceId: int, db: AsyncSession = Depends(get_db)):
    tree = await comment_service.get_tree(db, resourceId)
    return success(tree)


@router.get("/user")
async def get_user_comments(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    records, total = await comment_service.get_user_comments_page(
        db, pageNum, pageSize, user["userId"]
    )
    return success_page(records, total, pageNum, pageSize)


@router.get("/my")
async def get_my_comments(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    records, total = await comment_service.get_my_comments_page(
        db, pageNum, pageSize, user["userId"]
    )
    return success_page(records, total, pageNum, pageSize)


# ---------------- writes (mirrors CommentController) ----------------

@router.post("/add")
async def add_comment(
    resourceId: int = Query(...),
    content: str = Query(...),
    parentId: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await comment_service.add(db, resourceId, user["userId"], content, parentId)
    return success("评论成功")


@router.delete("/delete/{id}")
async def delete_comment(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await comment_service.delete(db, id, user["userId"])
    return success("删除成功")


@router.post("/like/{id}")
async def like_comment(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await comment_service.like(db, id, user["userId"])
    return success("点赞成功")


@router.delete("/like/{id}")
async def unlike_comment(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await comment_service.unlike(db, id, user["userId"])
    return success("取消点赞成功")


@router.get("/like/check/{id}")
async def check_comment_liked(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    liked = await comment_service.is_liked(db, id, user["userId"])
    return success(liked)
