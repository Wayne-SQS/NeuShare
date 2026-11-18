"""Shared helpers: datetime formatting (mirrors the Java reference: ISO-8601 'T')
and resource file-existence check (mirrors ResourceServiceImpl)."""
import os
import re
from datetime import datetime
from typing import Any, Optional

from app.core.config import settings

_CAMEL_RE = re.compile(r"_([a-z])")


def fmt_dt(dt: Optional[datetime]) -> Optional[str]:
    """Format like the Java reference: ISO-8601 with a 'T' separator.

    ``spring.jackson.date-format`` does NOT apply to ``LocalDateTime`` (JSR-310 is
    serialized by its own module), so Java actually emits ``2026-11-14T13:01:48``.
    Verified against the running Java backend in the M0 contract baseline.
    """
    if not dt:
        return None
    return dt.strftime("%Y-%m-%dT%H:%M:%S")


def file_exists(content_url: Optional[str]) -> bool:
    """Mirror Java: external link (http/https) always exists; local file checked
    on disk under uploads dir. Path traversal is defended by resolving & boundary check."""
    if not content_url:
        return False
    if content_url.startswith("http://") or content_url.startswith("https://"):
        return True
    upload_dir = settings.upload_dir
    try:
        target = (upload_dir / content_url).resolve()
        target.relative_to(upload_dir.resolve())  # raises ValueError if outside
    except (ValueError, OSError):
        return False
    return target.is_file()


def is_true(v) -> bool:
    """Treat int 1 / '1' / True as true (Java boolean columns stored as tinyint)."""
    if isinstance(v, bool):
        return v
    if v is None:
        return False
    return int(v) == 1


def camelize(key: str) -> str:
    """snake_case -> camelCase (matches Java Jackson field naming)."""
    return _CAMEL_RE.sub(lambda m: m.group(1).upper(), key)


def to_entity_dict(row: dict) -> dict:
    """Convert a snake_case DB row dict into a camelCase dict, formatting any
    datetime values to Java's 'yyyy-MM-dd HH:mm:ss'. Used for endpoints that
    return raw entities (category, banner, ...)."""
    out: dict = {}
    for k, v in row.items():
        out[camelize(k)] = fmt_dt(v) if isinstance(v, datetime) else v
    return out
