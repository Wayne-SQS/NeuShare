"""V5/V6 结构化检索（从 master 的 Java 版移植到 Python 后端）。

设计前提：API 契约 100% 兼容。
  - 不传任何 V5 参数时，路由层继续走 resource_service.get_page，行为与 Java 版逐字段一致；
  - 只有带结构化筛选 / 关键词时才进本模块，因此不影响已有的 147/147 契约对拍。

字段口径与 master 的 ResourceVO / ResourceQuery 对齐：
  courseName / teacher / schoolYear / term / type / sortBy(relevance|hot|new)

全文检索降级链（对应 master ResourceServiceImpl 的 fulltext-enabled 开关）：
  ngram FULLTEXT 可用 -> MATCH ... AGAINST 并按相关度排序
  索引缺失 / 词太短 / 任何 SQL 异常 -> 退化为 LIKE，不报错、不伪造结果
"""
from __future__ import annotations

from typing import Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.services import resource_service as rs
from app.utils.paging import page_window

# ngram 默认 2 字切分，单字走全文索引没有意义
_MIN_FT_LEN = 2

# 只放行白名单字段，杜绝把用户输入拼进 SQL 标识符
_STRUCTURED = {
    "courseName": "r.course_name",
    "teacher": "r.teacher",
    "schoolYear": "r.school_year",
    "term": "r.term",
    "type": "r.type",
}


def has_structured(query: dict) -> bool:
    return any(query.get(k) not in (None, "") for k in _STRUCTURED) or bool(query.get("keyword"))


def _clean_keyword(keyword: Optional[str]) -> str:
    """布尔模式特殊字符会让 MATCH 语法报错，先剥掉再进全文索引。"""
    if not keyword:
        return ""
    return "".join(ch for ch in keyword.strip() if ch not in '+-@><()~*"&|')


def filter_summary(query: dict) -> Optional[str]:
    """写进 search_log 的筛选摘要，格式与 master 的 ResourceQuery.filterSummary 一致。"""
    parts = []
    if query.get("categoryId") not in (None, ""):
        parts.append(f"category={query['categoryId']}")
    for key in ("courseName", "teacher", "schoolYear", "term", "type"):
        if query.get(key) not in (None, ""):
            parts.append(f"{key}={query[key]}")
    return ",".join(parts) or None


async def _fulltext_available(db: AsyncSession) -> bool:
    """检查 ngram 全文索引是否已建立；查不到就走 LIKE，不让用户吃 500。"""
    try:
        row = (await db.execute(text(
            "SELECT COUNT(*) FROM information_schema.STATISTICS "
            "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'resource' "
            "AND INDEX_NAME = 'ft_resource_search'"
        ))).scalar()
        return bool(row)
    except Exception:
        return False


async def log_search(db: AsyncSession, keyword: str, result_count: int,
                     filters: Optional[str], user_id: Optional[int]) -> None:
    """记录「用户搜了什么、搜到多少」。零命中高频词是补内容的依据。
    日志表缺失或写入失败都不影响搜索本身。"""
    try:
        await db.execute(text(
            "INSERT INTO search_log (user_id, keyword, result_count, filters) "
            "VALUES (:user_id, :keyword, :result_count, :filters)"
        ), {"user_id": user_id, "keyword": (keyword or "")[:100],
            "result_count": result_count, "filters": filters})
        await db.commit()
    except Exception:
        await db.rollback()


async def structured_page(db: AsyncSession, query: dict, page_num: int,
                          page_size: int, user_id: Optional[int] = None) -> tuple[list, int]:
    """带 V5 结构化条件的分页检索，返回 (records, total)。"""
    where = ["r.status = :status"]
    params: dict = {"status": query.get("status", 1)}
    if query.get("categoryId") not in (None, ""):
        where.append("r.category_id = :category_id")
        params["category_id"] = query["categoryId"]
    for key, col in _STRUCTURED.items():
        val = query.get(key)
        if val not in (None, ""):
            where.append(f"{col} = :{key}")
            params[key] = val

    keyword = (query.get("keyword") or "").strip()
    ft_kw = _clean_keyword(keyword)
    use_ft = False
    if keyword and len(ft_kw) >= _MIN_FT_LEN and settings.search_fulltext_enabled:
        use_ft = await _fulltext_available(db)
    if keyword and use_ft:
        where.append("MATCH(r.title, r.description, r.tags_text) AGAINST (:ft_kw IN NATURAL LANGUAGE MODE)")
        params["ft_kw"] = ft_kw
    elif keyword:
        where.append("(r.title LIKE CONCAT('%',:keyword,'%') OR r.description LIKE CONCAT('%',:keyword,'%') OR r.tags LIKE CONCAT('%',:keyword,'%'))")
        params["keyword"] = keyword

    sort_by = query.get("sortBy") or ("relevance" if keyword else "new")
    cols = rs._SELECT_COLS
    if sort_by == "relevance" and use_ft:
        cols += ", MATCH(r.title, r.description, r.tags_text) AGAINST (:ft_kw IN NATURAL LANGUAGE MODE) AS relevance"
        order = "relevance DESC, r.create_time DESC"
    elif sort_by == "hot":
        order = "r.view_count DESC, r.like_count DESC"
    else:
        order = "r.create_time DESC"

    from_clause = rs._FROM
    where_sql = " AND ".join(where)
    window = page_window(page_num, page_size)
    try:
        total = (await db.execute(text(f"SELECT COUNT(*) {from_clause} WHERE {where_sql}"), params)).scalar() or 0
        sql = f"SELECT {cols} {from_clause} WHERE {where_sql} ORDER BY {order} LIMIT :size OFFSET :offset"
        p = {**params, "size": window.size, "offset": window.offset}
        rows = (await db.execute(text(sql), p)).mappings().all()
    except Exception:
        # 全文索引存在但列/解析器异常时，退化为纯 LIKE，保证用户仍能搜到东西
        await db.rollback()
        where = [w for w in where if "MATCH(" not in w]
        params.pop("ft_kw", None)
        if keyword:
            where.append("(r.title LIKE CONCAT('%',:keyword,'%') OR r.description LIKE CONCAT('%',:keyword,'%') OR r.tags LIKE CONCAT('%',:keyword,'%'))")
            params["keyword"] = keyword
        cols = rs._SELECT_COLS
        order = "r.create_time DESC"
        where_sql = " AND ".join(where)
        total = (await db.execute(text(f"SELECT COUNT(*) {from_clause} WHERE {where_sql}"), params)).scalar() or 0
        sql = f"SELECT {cols} {from_clause} WHERE {where_sql} ORDER BY {order} LIMIT :size OFFSET :offset"
        p = {**params, "size": window.size, "offset": window.offset}
        rows = (await db.execute(text(sql), p)).mappings().all()

    records = [rs.to_resource_vo(dict(r)) for r in rows]
    if keyword:
        await log_search(db, keyword, total, filter_summary(query), user_id)
    return records, total


async def filter_options(db: AsyncSession) -> dict:
    """只列已发布资源里真实出现过的课程与教师，绝不给空选项或编造候选。"""
    try:
        courses = (await db.execute(text(
            "SELECT DISTINCT course_name FROM resource "
            "WHERE status = 1 AND course_name IS NOT NULL AND course_name <> '' "
            "ORDER BY course_name"
        ))).scalars().all()
        teachers = (await db.execute(text(
            "SELECT DISTINCT teacher FROM resource "
            "WHERE status = 1 AND teacher IS NOT NULL AND teacher <> '' "
            "ORDER BY teacher"
        ))).scalars().all()
    except Exception:
        await db.rollback()
        return {"courses": [], "teachers": []}
    return {"courses": list(courses), "teachers": list(teachers)}


async def suggest(db: AsyncSession, keyword: str, limit: int = 10) -> list[str]:
    limit = max(1, min(int(limit or 10), 20))
    try:
        rows = (await db.execute(text(
            "SELECT DISTINCT title FROM resource "
            "WHERE status = 1 AND title LIKE CONCAT('%',:kw,'%') "
            "ORDER BY title LIMIT :lim"
        ), {"kw": keyword, "lim": limit})).scalars().all()
    except Exception:
        await db.rollback()
        return []
    return list(rows)
