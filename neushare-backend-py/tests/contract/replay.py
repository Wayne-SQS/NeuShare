"""Replay engine shared by the golden capture, the diff tool and pytest."""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field

import httpx

from .normalize import normalize_response

_TEMPLATE = re.compile(r"\{\{(\w+)\}\}")


@dataclass
class Result:
    status: int
    headers: dict
    body: bytes
    normalized: dict | None = None
    error: str | None = None

    @property
    def json(self):
        return json.loads(self.body.decode("utf-8"))


class Backend:
    """One running backend instance plus its per-role JWTs."""

    def __init__(self, base_url: str, timeout: float = 30.0):
        self.base_url = base_url.rstrip("/")
        self.client = httpx.Client(
            base_url=self.base_url,
            timeout=timeout,
            follow_redirects=False,
            headers={"Accept-Language": "zh-CN"},
        )
        self.tokens: dict[str, str | None] = {"anon": None}

    # -- low level ---------------------------------------------------------
    def request(self, method, path, role="anon", *, params=None, json_body=None,
                form=None, files=None) -> Result:
        headers = {}
        token = self.tokens.get(role)
        if token:
            headers["Authorization"] = f"Bearer {token}"
        try:
            resp = self.client.request(
                method.upper(), path, params=params, json=json_body,
                data=form, files=files, headers=headers,
            )
        except Exception as exc:  # noqa: BLE001 - network errors become a result
            return Result(status=-1, headers={}, body=b"", error=f"{type(exc).__name__}: {exc}")
        result = Result(status=resp.status_code, headers=dict(resp.headers), body=resp.content)
        result.normalized = normalize_response(resp.status_code, resp.headers, resp.content)
        return result

    def login(self, role: str, username: str, password: str) -> None:
        res = self.request("POST", "/api/auth/login", "anon",
                           json_body={"username": username, "password": password})
        if res.status != 200:
            raise RuntimeError(f"{self.base_url} 登录失败 role={role} status={res.status} body={res.body[:200]!r}")
        payload = res.json
        token = (payload.get("data") or {}).get("token")
        if not token:
            raise RuntimeError(f"{self.base_url} 登录响应缺少 token: {payload!r}")
        self.tokens[role] = token

    def login_all(self) -> None:
        self.login("student", "20240001", "123456")
        self.login("teacher", "T20240001", "123456")
        self.login("admin", "admin", "123456")

    def close(self) -> None:
        self.client.close()


# -- template helpers ------------------------------------------------------
def fill_path(value: str, ctx: dict) -> str:
    """Replace ``{{name}}`` placeholders (double braces so JSON text is untouched)."""
    return _TEMPLATE.sub(lambda m: str(ctx[m.group(1)]), value)


def fill_deep(value, ctx: dict):
    """Recursively replace strings that consist *only* of a ``{{name}}`` placeholder."""
    if isinstance(value, str):
        match = _TEMPLATE.fullmatch(value)
        if match:
            return ctx[match.group(1)]
        return value
    if isinstance(value, list):
        return [fill_deep(v, ctx) for v in value]
    if isinstance(value, dict):
        return {k: fill_deep(v, ctx) for k, v in value.items()}
    return value


def execute(backend: Backend, case: dict, ctx: dict) -> Result:
    path = fill_path(case["path"], ctx)
    params = {k: fill_path(str(v), ctx) for k, v in (case.get("query") or {}).items()} or None
    json_body = fill_deep(case["json"], ctx) if case.get("json") is not None else None
    form = fill_deep(case["form"], ctx) if case.get("form") is not None else None
    files = fill_deep(case["files"], ctx) if case.get("files") is not None else None
    return backend.request(case["method"], path, case.get("role", "anon"),
                           params=params, json_body=json_body, form=form, files=files)


def run_case(backend: Backend, case: dict, ctx: dict) -> Result:
    result = execute(backend, case, ctx)
    for name, derive in (case.get("derive") or {}).items():
        try:
            ctx[name] = derive(backend, ctx)
        except Exception as exc:  # noqa: BLE001
            raise RuntimeError(f"用例 {case['name']} 的 derive({name}) 失败: {exc}") from exc
    return result
