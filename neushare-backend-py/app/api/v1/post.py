from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success, success_page, error
from app.db.session import get_db
from app.middleware.auth import get_current_user, get_optional_user
from app.services import post_service

router = APIRouter(prefix="/api/post", tags=["post"])


@router.get("/list")
async def get_post_list(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    status: Optional[int] = Query(None),
    tag: Optional[str] = Query(None),
    keyword: Optional[str] = Query(None),
    sortBy: str = Query("new"),
    db: AsyncSession = Depends(get_db),
    user: Optional[dict] = Depends(get_optional_user),
):
    # 公开接口：非管理员只能看已发布帖子，防止通过 status 窥探待审核/驳回内容
    is_admin = user is not None and user.get("role") == "admin"
    effective_status = status if (status is not None and is_admin) else 1
    records, total = await post_service.get_page(
        db, pageNum, pageSize, effective_status, tag, keyword, sortBy
    )
    return success_page(records, total, pageNum, pageSize)


@router.get("/detail/{id}")
async def get_post_detail(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: Optional[dict] = Depends(get_optional_user),
):
    vo = await post_service.get_detail(db, id)
    if vo is None:
        # Java 走 BusinessException（默认 code=500），未发布无权查看才是 404
        return error(500, "帖子不存在")
    # 未发布帖子仅作者和管理员可查看
    if vo.get("status") is not None and vo["status"] != 1:
        is_owner = user is not None and user.get("userId") == vo["userId"]
        is_admin = user is not None and user.get("role") == "admin"
        if not is_owner and not is_admin:
            return error(404, "帖子不存在")
    await post_service.increment_view(db, id)
    return success(vo)


@router.get("/hot")
async def get_hot_posts(limit: int = Query(10), db: AsyncSession = Depends(get_db)):
    rows = await post_service.get_hot(db, limit)
    return success(rows)


@router.get("/user")
async def get_user_posts(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    records, total = await post_service.get_user_posts(db, pageNum, pageSize, user["userId"])
    return success_page(records, total, pageNum, pageSize)


# ---------------- writes (mirrors PostController) ----------------

@router.post("/create")
async def create_post(
    payload: dict,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_service.create(db, user["userId"], payload)
    return success("发布成功")


@router.put("/update")
async def update_post(
    payload: dict,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_service.update(db, user["userId"], user["role"], payload)
    return success("更新成功")


@router.delete("/delete/{id}")
async def delete_post(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_service.delete(db, id, user["userId"], user["role"])
    return success("删除成功")


@router.post("/like/{id}")
async def like_post(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_service.like(db, id, user["userId"])
    return success("点赞成功")


@router.delete("/like/{id}")
async def unlike_post(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_service.unlike(db, id, user["userId"])
    return success("取消点赞成功")


@router.get("/like/check/{id}")
async def check_post_liked(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    liked = await post_service.is_liked(db, id, user["userId"])
    return success(liked)


@router.post("/favorite/{id}")
async def favorite_post(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_service.favorite(db, id, user["userId"])
    return success("收藏成功")


@router.delete("/favorite/{id}")
async def unfavorite_post(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_service.unfavorite(db, id, user["userId"])
    return success("取消收藏成功")


@router.get("/favorite/check/{id}")
async def check_post_favorited(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    favorited = await post_service.is_favorited(db, id, user["userId"])
    return success(favorited)


@router.put("/recommend/{id}")
async def recommend_post(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await post_service.recommend(db, id, user["userId"], user["role"])
    return success("推荐成功")
