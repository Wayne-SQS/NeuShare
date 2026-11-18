from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success
from app.db.session import get_db
from app.middleware.auth import get_current_user
from app.services import post_comment_service

router = APIRouter(prefix="/api/post/comment", tags=["post-comment"])


@router.get("/list/{postId}")
async def get_comment_tree(postId: int, db: AsyncSession = Depends(get_db)):
    tree = await post_comment_service.get_tree(db, postId)
    return success(tree)


# ---------------- writes (mirrors PostCommentController) ----------------

@router.post("/add")
async def add_post_comment(
    postId: int = Query(...),
    content: str = Query(...),
    parentId: int = Query(0),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_comment_service.add(db, postId, user["userId"], content, parentId)
    return success("评论成功")


@router.delete("/delete/{id}")
async def delete_post_comment(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_comment_service.delete(db, id, user["userId"], user["role"])
    return success("删除成功")


@router.post("/like/{id}")
async def like_post_comment(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_comment_service.like(db, id, user["userId"])
    return success("点赞成功")


@router.delete("/like/{id}")
async def unlike_post_comment(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_comment_service.unlike(db, id, user["userId"])
    return success("取消点赞成功")


@router.get("/like/check/{id}")
async def check_post_comment_liked(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    liked = await post_comment_service.is_liked(db, id, user["userId"])
    return success(liked)
