"""Pagination normalization that mirrors the Java (MyBatis-Plus) behaviour.

The M0 contract baseline pinned these down by running the Java backend:

    pageNum  <= 0    -> current = 1
    pageSize 1..100  -> size = pageSize
    pageSize > 100   -> size = 100          (PaginationInnerInterceptor.setMaxLimit(100L))
    pageSize < 0     -> size = 100, total = 0 (MyBatis-Plus reads a negative size as
                                              "no limit": it caps the SQL at maxLimit and
                                              skips the COUNT query, hence total=0)
    pageSize == 0    -> HTTP 200, code=500 "系统异常，请稍后重试" (Java divides by zero
                                              when computing pages)

Every paged service goes through :func:`page_window` so the SQL window, the echoed
``current``/``size`` and the ``total`` all agree with the reference implementation.
"""
from dataclasses import dataclass
from typing import Optional

from app.core.exceptions import BusinessException

MAX_PAGE_SIZE = 100


@dataclass(frozen=True)
class PageWindow:
    current: int
    size: int
    offset: int
    count_rows: bool = True


def page_window(page_num: Optional[int] = None, page_size: Optional[int] = None) -> PageWindow:
    current = page_num if isinstance(page_num, int) and page_num > 0 else 1
    if page_size is None:
        page_size = 10

    if page_size == 0:
        # Bug-for-bug with Java: the reference backend answers 200/{"code":500}. A real
        # client never sends 0, so keeping parity is cheaper than special-casing the
        # frontend. TODO: switch to "参数格式错误：pageSize" once Java is decommissioned.
        raise BusinessException("系统异常，请稍后重试")

    if page_size < 0:
        return PageWindow(current=current, size=MAX_PAGE_SIZE, offset=0, count_rows=False)

    size = min(page_size, MAX_PAGE_SIZE)
    return PageWindow(current=current, size=size, offset=(current - 1) * size)
