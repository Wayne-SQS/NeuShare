import re
from typing import Optional
from urllib.parse import quote

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile
from fastapi.responses import FileResponse, JSONResponse, RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BusinessException
from app.core.response import success, success_page, error
from app.db.session import get_db
from app.middleware.auth import get_current_user, get_optional_user
from app.services import resource_service, search_service

router = APIRouter(prefix="/api/resource", tags=["resource"])

_ILLEGAL_FN = re.compile(r"[\\/:*?\"<>|]")


def _build_download_filename(title: Optional[str], physical_name: str) -> str:
    base = (title or "resource").strip() or "resource"
    base = _ILLEGAL_FN.sub("_", base)
    ext = ""
    dot = physical_name.rfind(".")
    if dot >= 0:
        ext = physical_name[dot:]
    return base + ext


@router.get("/hot")
async def get_hot_resources(limit: int = Query(10), db: AsyncSession = Depends(get_db)):
    rows = await resource_service.get_hot(db, limit)
    return success(rows)


@router.get("/list")
async def get_resource_list(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    status: Optional[int] = Query(None),
    categoryId: Optional[int] = Query(None),
    keyword: Optional[str] = Query(None),
    sortBy: str = Query("new"),
    courseName: Optional[str] = Query(None),
    teacher: Optional[str] = Query(None),
    schoolYear: Optional[str] = Query(None),
    term: Optional[str] = Query(None),
    type: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    user: Optional[dict] = Depends(get_optional_user),
):
    # 公开接口：非管理员只能看已发布资源
    is_admin = user is not None and user.get("role") == "admin"
    effective_status = status if (status is not None and is_admin) else 1
    query = {
        "status": effective_status, "categoryId": categoryId, "keyword": keyword,
        "sortBy": sortBy, "courseName": courseName, "teacher": teacher,
        "schoolYear": schoolYear, "term": term, "type": type,
    }
    # 无 V5 参数时走原有路径，保证 147/147 契约对拍逐字段不变
    if not search_service.has_structured(query) and sortBy in (None, "", "new", "hot"):
        records, total = await resource_service.get_page(
            db, pageNum, pageSize, effective_status, categoryId, keyword, sortBy
        )
    else:
        records, total = await search_service.structured_page(
            db, query, pageNum, pageSize, user_id=(user or {}).get("userId")
        )
    return success_page(records, total, pageNum, pageSize)


@router.get("/filters")
async def get_resource_filters(db: AsyncSession = Depends(get_db)):
    """V5：已发布资源中出现过的课程与教师，供筛选下拉使用。"""
    return success(await search_service.filter_options(db))


@router.get("/suggest")
async def suggest_resources(
    keyword: str = Query(...),
    limit: int = Query(10),
    db: AsyncSession = Depends(get_db),
):
    """V5：搜索联想，只返回真实存在的标题。"""
    return success(await search_service.suggest(db, keyword, limit))


@router.get("/detail/{id}")
async def get_resource_detail(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: Optional[dict] = Depends(get_optional_user),
):
    vo = await resource_service.get_detail(db, id)
    if vo is None:
        # Java 走 BusinessException（默认 code=500），只有"未发布无权查看"才是 404
        return error(500, "资源不存在")
    # 未发布资源仅上传者和管理员可查看
    if vo.get("status") is not None and vo["status"] != 1:
        is_owner = user is not None and user.get("userId") == vo["uploadUserId"]
        is_admin = user is not None and user.get("role") == "admin"
        if not is_owner and not is_admin:
            return error(404, "资源不存在")
    await resource_service.increment_view(db, id)
    return success(vo)


@router.get("/search")
async def search_resources(
    keyword: str = Query(...),
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    sortBy: str = Query("new"),
    categoryId: Optional[int] = Query(None),
    courseName: Optional[str] = Query(None),
    teacher: Optional[str] = Query(None),
    schoolYear: Optional[str] = Query(None),
    term: Optional[str] = Query(None),
    type: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    user: Optional[dict] = Depends(get_optional_user),
):
    query = {
        "status": 1, "keyword": keyword, "sortBy": sortBy, "categoryId": categoryId,
        "courseName": courseName, "teacher": teacher, "schoolYear": schoolYear,
        "term": term, "type": type,
    }
    if any(query.get(k) not in (None, "") for k in ("courseName", "teacher", "schoolYear", "term", "type", "categoryId")):
        records, total = await search_service.structured_page(
            db, query, pageNum, pageSize, user_id=(user or {}).get("userId")
        )
    else:
        records, total = await resource_service.search_page(db, pageNum, pageSize, keyword, sortBy)
    return success_page(records, total, pageNum, pageSize)


@router.get("/user")
async def get_user_resources(
    pageNum: int = Query(1),
    pageSize: int = Query(10),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    records, total = await resource_service.get_user_resources(db, pageNum, pageSize, user["userId"])
    return success_page(records, total, pageNum, pageSize)


@router.get("/download/{id}")
async def download_resource(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: Optional[dict] = Depends(get_optional_user),
):
    vo = await resource_service.get_detail(db, id)
    if vo is None:
        # 同上：Java 的 BusinessException 默认 500
        return error(500, "资源不存在")
    # 未发布资源仅上传者/管理员可下载
    if vo.get("status") is not None and vo["status"] != 1:
        is_owner = user is not None and user.get("userId") == vo["uploadUserId"]
        is_admin = user is not None and user.get("role") == "admin"
        if not is_owner and not is_admin:
            return JSONResponse(status_code=404, content=error(404, "资源不存在"))
    # 外链直接 302 跳转
    if resource_service.is_external_url(vo.get("contentUrl")):
        return RedirectResponse(url=vo["contentUrl"], status_code=302)
    # 本地文件：缺失时 resolve_download_path 抛业务异常 → 全局处理器转 JSON 错误
    path = resource_service.resolve_download_path(vo.get("contentUrl"))
    filename = _build_download_filename(vo.get("title"), path.name)
    encoded = quote(filename, safe="")
    return FileResponse(
        str(path),
        media_type="application/octet-stream",
        filename=None,
        headers={"Content-Disposition": f"attachment; filename*=UTF-8''{encoded}"},
    )


# ---------------- writes (mirrors ResourceController create/update/delete/like) ----------------

@router.post("/create")
async def create_resource(
    title: Optional[str] = Form(None),
    categoryId: Optional[int] = Form(None),
    type: Optional[str] = Form(None),
    contentUrl: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    coverUrl: Optional[str] = Form(None),
    source: Optional[str] = Form(None),
    tags: Optional[str] = Form(None),
    file: UploadFile = File(None),
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    # 与 Java @Valid 对齐：title NotBlank、categoryId NotNull
    if not title or not str(title).strip():
        raise BusinessException("标题不能为空", 400)
    if categoryId is None:
        raise BusinessException("分类不能为空", 400)
    dto = {
        "title": title, "categoryId": categoryId, "type": type,
        "contentUrl": contentUrl, "description": description,
        "coverUrl": coverUrl, "source": source, "tags": tags,
    }
    # 上传文件优先：存在则覆盖 contentUrl（与 Java fileUploadUtil.upload 一致）
    if file is not None and getattr(file, "filename", None):
        dto["contentUrl"] = await resource_service.save_upload_file(file)
    await resource_service.create(db, user["userId"], dto)
    return success("创建成功，等待审核")


@router.put("/update")
async def update_resource(
    payload: dict,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await resource_service.update(db, user["userId"], user["role"], payload)
    return success("更新成功")


@router.delete("/delete/{id}")
async def delete_resource(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await resource_service.delete(db, id, user["userId"], user["role"])
    return success("删除成功")


@router.post("/like/{id}")
async def like_resource(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await resource_service.like(db, id, user["userId"])
    return success("点赞成功")


@router.delete("/like/{id}")
async def unlike_resource(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    await resource_service.unlike(db, id, user["userId"])
    return success("取消点赞成功")


@router.get("/like/check/{id}")
async def check_resource_liked(
    id: int,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    liked = await resource_service.is_liked(db, id, user["userId"])
    return success(liked)
