"""服务入口：uvicorn app.main:app --reload --port 8000"""
from __future__ import annotations

import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import chat


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="NeuShare AI",
        version="0.1.0",
        description="NeuShare 校园学习助手：FastAPI + LangChain + Tavily 联网检索",
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(chat.router)

    @app.get("/", include_in_schema=False)
    def root():
        return {"service": "neushare-ai", "docs": "/docs", "health": "/api/ai/health"}

    return app


app = create_app()


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="127.0.0.1",
        port=int(os.getenv("AI_SERVICE_PORT", "8000")),
        reload=True,
    )
