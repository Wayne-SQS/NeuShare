"""Unified response envelope matching the Java Result<T> / PageResult<T>.

Success: {"code": 200, "message": "操作成功", "data": ...}
Business error: {"code": <code>, "message": "...", "data": null}  (HTTP 200)
Paged data: {"code":200,"message":"操作成功","data":{"records":[...],"total":N,"current":n,"size":s,"pages":p}}
"""
from typing import Any, Optional

from app.utils.paging import MAX_PAGE_SIZE


def success(data: Any = None, message: Optional[str] = None) -> dict:
    # 与 Java Result 的四个重载严格对齐：
    #   success(String message)       -> message=str, data=null   （字符串实参走此分支）
    #   success(T data)               -> message="操作成功", data=T
    #   success(String message, T d)  -> 显式 message + data
    #   success()                     -> message="操作成功", data=null
    if message is not None:
        return {"code": 200, "message": message, "data": data}
    if isinstance(data, str):
        return {"code": 200, "message": data, "data": None}
    return {"code": 200, "message": "操作成功", "data": data}


def error(code: int, message: str) -> dict:
    return {"code": code, "message": message, "data": None}


def page_result(records: list, total: int, current: int, size: int) -> dict:
    """Echo the same current/size/pages the Java backend reports.

    Clamping mirrors :mod:`app.utils.paging`; a negative size also zeroes ``total``
    because MyBatis-Plus skips the COUNT query for "unlimited" pages.
    """
    num = current if isinstance(current, int) and current > 0 else 1
    if size is None:
        size = 10
    if size < 0:
        size = MAX_PAGE_SIZE
        total = 0
    elif size == 0:
        # Unreachable through the services (page_window raises first); kept safe.
        size = MAX_PAGE_SIZE
    else:
        size = min(size, MAX_PAGE_SIZE)
    pages = (total + size - 1) // size
    return {"records": records, "total": total, "current": num, "size": size, "pages": pages}


def success_page(records: list, total: int, current: int, size: int) -> dict:
    return success(page_result(records, total, current, size))
