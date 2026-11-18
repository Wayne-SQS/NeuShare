"""FastAPI application entrypoint for the NeuShare Python backend (port 8080).

Replaces the Spring Boot backend with a 100% API-compatible FastAPI service.
Port 8080 is intentional: it matches the original Java port so the Vue frontend
and HarmonyOS client BASE_URL need no changes, and avoids neushare-ai's 8000.
"""
import logging
import re
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.core.exceptions import (BusinessException, UnauthorizedException,
                                 register_exception_handlers)
from app.core.security import decode_token, extract_bearer
from app.db.session import verify_connection
from app.db import redis as redis_db
from app.api.v1 import (
    resource as resource_router,
    category as category_router,
    banner as banner_router,
    formcard as formcard_router,
    auth as auth_router,
    post as post_router,
    comment as comment_router,
    post_comment as post_comment_router,
    stats as stats_router,
    user as user_router,
    favorite as favorite_router,
    follow as follow_router,
    notification as notification_router,
    admin as admin_router,
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    log.info("starting neushare-backend-py on port %s", settings.port)
    await verify_connection()
    await redis_db.init_redis()
    yield
    log.info("neushare-backend-py shutting down")
    await redis_db.close_redis()


app = FastAPI(title="NeuShare Backend (Python)", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

register_exception_handlers(app)

app.include_router(resource_router.router)
app.include_router(category_router.router)
app.include_router(banner_router.router)
app.include_router(formcard_router.router)
app.include_router(auth_router.router)
app.include_router(post_router.router)
app.include_router(comment_router.router)
app.include_router(post_comment_router.router)
app.include_router(stats_router.router)
app.include_router(user_router.router)
app.include_router(favorite_router.router)
app.include_router(follow_router.router)
app.include_router(notification_router.router)
app.include_router(admin_router.router)

# 静态文件：上传目录映射为 /files/**（与 Java WebMvcConfig 一致，供封面图 / 附件访问）
settings.upload_dir.mkdir(parents=True, exist_ok=True)
app.mount("/files", StaticFiles(directory=settings.upload_dir), name="files")


@app.get("/health")
async def health():
    return {"status": "ok"}


# 未匹配的 /api/** —— 必须最后注册，让上面的具体路由先匹配。
# Java 的真实行为（M0 实测）：
#   路径不存在 + 无 token -> HTTP 401 信封（JWT 拦截器先于路由）
#   路径不存在 + 有 token -> HTTP 200 / code=500（404 被全局处理器包成 500）
#   路径存在但方法不对     -> HTTP 200 / code=500（405 在拦截器之前抛出）
_API_METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]


_API_METHODS = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]

_KNOWN_PATH_RES = None


def _known_path_matched(path: str) -> bool:
    """Whether any registered route (any method) matches ``path``.

    ``app.routes`` does not expose individual APIRoute objects in this FastAPI
    version (included routers are wrapped), so the OpenAPI path templates —
    ``/api/resource/detail/{id}`` etc. — are compiled once instead.
    """
    global _KNOWN_PATH_RES
    if _KNOWN_PATH_RES is None:
        patterns = []
        for template in app.openapi().get("paths", {}):
            parts = re.split(r"\{[^}]+\}", template)
            patterns.append(re.compile("^" + "[^/]+".join(re.escape(p) for p in parts) + "$"))
        _KNOWN_PATH_RES = patterns
    return any(pattern.match(path) for pattern in _KNOWN_PATH_RES)


@app.api_route("/api/{unknown_path:path}", methods=_API_METHODS, include_in_schema=False)
async def unknown_api(unknown_path: str, request: Request):
    full_path = "/api/" + unknown_path
    if _known_path_matched(full_path):
        # 路径存在但方法不支持：Java 在 JWT 拦截器之前抛 405，被全局处理器包成 500 信封
        raise BusinessException("系统异常，请稍后重试")
    token = extract_bearer(request.headers.get("authorization"))
    if not token or decode_token(token) is None:
        raise UnauthorizedException()
    raise BusinessException("系统异常，请稍后重试")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=settings.port, reload=False)
