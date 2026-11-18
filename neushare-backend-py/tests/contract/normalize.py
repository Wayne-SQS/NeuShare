"""Normalize HTTP responses so a Java backend and a Python backend can be compared.

Volatile values are masked, but their *shape* is preserved, so a real format
difference still shows up as a diff instead of being silently erased:

* ``token``            -> ``<token>``
* timestamps           -> ``<timestamp:isoT>`` (``2026-11-14T13:01:48``)
                          or ``<timestamp:space>`` (``2026-11-14 13:01:48``)
   Java serializes ``LocalDateTime`` through JSR-310, which ignores
   ``spring.jackson.date-format``; the two styles are *not* interchangeable for
   strict clients, so the style is part of the contract.
* upload filenames     -> ``<uuid>`` (each backend generates its own name)
"""
from __future__ import annotations

import hashlib
import json
import re

_UUID = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
_ISO_TS = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?$")
_SPACE_TS = re.compile(r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d+)?$")
_TOKEN_KEYS = {"token", "accessToken"}


def _sort_validation_message(value: str) -> str:
    """Sort joined bean-validation messages — Java itself does not order them.

    ``@Valid`` violation sets are unordered in Hibernate Validator, so the same
    request can answer ``密码不能为空, 用户名不能为空`` or the reverse. Comparing the
    *set* of messages keeps the content check while dropping the coin flip.
    """
    parts = [part.strip() for part in value.split(", ")]
    if len(parts) > 1 and all("不能为空" in part for part in parts):
        return ", ".join(sorted(parts))
    return value


def _walk(value, key):
    if isinstance(value, dict):
        return {k: _walk(value[k], k) for k in sorted(value)}
    if isinstance(value, list):
        return [_walk(item, key) for item in value]
    if isinstance(value, str):
        if key in _TOKEN_KEYS:
            return "<token>"
        if _ISO_TS.match(value):
            return "<timestamp:isoT>"
        if _SPACE_TS.match(value):
            return "<timestamp:space>"
        if key == "message":
            value = _sort_validation_message(value)
        return _UUID.sub("<uuid>", value)
    return value


def normalize_response(status: int, headers, body: bytes) -> dict:
    """Return a comparable snapshot: status + media type + normalized body."""
    content_type = (headers.get("content-type") or "").split(";")[0].strip().lower()

    if "json" in content_type:
        try:
            parsed = json.loads(body.decode("utf-8"))
        except Exception:  # noqa: BLE001 - a broken body becomes a diff, not a crash
            payload = {"invalidJson": body[:400].decode("utf-8", "replace")}
        else:
            payload = {"json": _walk(parsed, None)}
    else:
        payload = {
            "bytes": {
                "sha256": hashlib.sha256(body).hexdigest(),
                "len": len(body),
            }
        }

    return {
        "status": status,
        "contentType": content_type,
        "contentDisposition": headers.get("content-disposition"),
        "location": headers.get("location"),
        "body": payload,
    }
