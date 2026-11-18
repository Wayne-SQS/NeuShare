"""Business exceptions + global handlers that keep the exact Java response shape.

Contract details pinned by the M0 baseline (see tests/contract/FINDINGS.md):
  - business / validation error -> HTTP 200, body {"code":<code>,"message":...,"data":null}
  - missing or expired token   -> HTTP 401, {"code":401,"message":"未登录或登录已过期",...}
  - non-admin on /api/admin/** -> HTTP 403, {"code":403,"message":"无访问权限",...}
  - unsupported method (405)   -> HTTP 200, {"code":500,"message":"系统异常，请稍后重试",...}
    (Java throws before the JWT interceptor runs, so it never becomes a 401)
  - missing query/path param   -> code 400, "缺少必填参数：<name>"
  - unparsable query/path param-> code 400, "参数格式错误：<name>"
"""
import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

log = logging.getLogger("exceptions")

# Pydantic error types that really mean "the value could not be parsed as the
# declared type" -> Java's 参数格式错误：<name>.
_MALFORMED_TYPES = {
    "int_parsing", "int_type", "float_parsing", "float_type", "bool_parsing",
    "bool_type", "decimal_parsing", "decimal_type", "string_type", "bytes_type",
    "list_type", "dict_type", "datetime_parsing", "datetime_type", "date_parsing",
    "date_type", "time_parsing", "time_type", "uuid_parsing", "uuid_type",
    "enum", "json_invalid",
}
_MISSING_TYPES = {"missing", "value_error.missing"}


class BusinessException(Exception):
    def __init__(self, message: str, code: int = 500):
        super().__init__(message)
        self.code = code
        self.message = message


class UnauthorizedException(Exception):
    """Raised when a protected route has no valid token. -> HTTP 401."""


class ForbiddenException(Exception):
    """Raised when a non-admin hits an admin route. -> HTTP 403."""


def _param_name(loc) -> str:
    parts = [str(part) for part in loc if part not in ("body", "query", "path", "header", "cookie")]
    return parts[-1] if parts else ""


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(BusinessException)
    async def _business(request: Request, exc: BusinessException):
        log.warning("business error code=%s msg=%s", exc.code, exc.message)
        return JSONResponse(status_code=200, content={"code": exc.code, "message": exc.message, "data": None})

    @app.exception_handler(UnauthorizedException)
    async def _unauthorized(request: Request, exc: UnauthorizedException):
        return JSONResponse(status_code=401, content={"code": 401, "message": "未登录或登录已过期", "data": None})

    @app.exception_handler(ForbiddenException)
    async def _forbidden(request: Request, exc: ForbiddenException):
        return JSONResponse(status_code=403, content={"code": 403, "message": "无访问权限", "data": None})

    @app.exception_handler(RequestValidationError)
    async def _validation(request: Request, exc: RequestValidationError):
        missing: list[str] = []
        malformed: list[str] = []
        custom: list[str] = []
        for err in exc.errors():
            name = _param_name(err.get("loc", []))
            kind = err.get("type", "")
            message = (err.get("msg") or "").removeprefix("Value error, ")
            if kind in _MISSING_TYPES:
                missing.append(name)
            elif kind in _MALFORMED_TYPES:
                malformed.append(name)
            else:
                custom.append(message)
        parts = [f"缺少必填参数：{name}" for name in missing]
        parts += [f"参数格式错误：{name}" for name in malformed]
        parts += custom
        return JSONResponse(status_code=200, content={
            "code": 400, "message": ", ".join(parts) or "参数校验失败", "data": None,
        })

    @app.exception_handler(StarletteHTTPException)
    async def _http_exception(request: Request, exc: StarletteHTTPException):
        if exc.status_code == 405:
            # Java 在拦截器之前抛 405，全局处理器包成 500 信封
            return JSONResponse(status_code=200, content={
                "code": 500, "message": "系统异常，请稍后重试", "data": None,
            })
        if exc.status_code == 404:
            # 非 /api 路径（静态文件等）保持 404 语义，但仍是信封
            return JSONResponse(status_code=404, content={
                "code": 404, "message": "接口不存在", "data": None,
            })
        return JSONResponse(status_code=exc.status_code, content={
            "code": exc.status_code, "message": str(exc.detail), "data": None,
        })

    @app.exception_handler(Exception)
    async def _generic(request: Request, exc: Exception):
        log.exception("unhandled exception: %s", exc)
        return JSONResponse(status_code=200, content={"code": 500, "message": "系统异常，请稍后重试", "data": None})
