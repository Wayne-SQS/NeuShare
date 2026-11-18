"""Configuration loaded from environment / .env.

JWT_SECRET must match the Java backend's ${JWT_SECRET} at runtime so tokens
issued by Java can be validated here. A dev fallback is provided for local
demos; override via env for production.
"""
import os
import logging
from pathlib import Path
from urllib.parse import quote_plus
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent  # .../neushare-ai
load_dotenv(BASE_DIR / ".env")

log = logging.getLogger("config")
# 安全红线：JWT_SECRET 只从环境变量读，绝不提供硬编码 fallback。
# 这个仓库是公开的，历史上曾把明文密钥写进 config.py / .env.example / 计划文档。
# 缺配置时启动即失败，比「悄悄用一个人尽皆知的密钥验签」安全得多。
if not os.getenv("JWT_SECRET"):
    raise RuntimeError(
        "JWT_SECRET 未配置。请在 .env 中设置，并与主后端使用同一值（HS256/384/512）。"
    )
if not os.getenv("DEEPSEEK_API_KEY"):
    log.warning("DEEPSEEK_API_KEY env not set; LLM calls will fail until configured.")


def _get(key, default=None):
    v = os.getenv(key)
    return v if v not in (None, "") else default


class Settings:
    # ---- LLM (DeepSeek) ----
    deepseek_api_key = _get("DEEPSEEK_API_KEY", "")
    deepseek_base_url = _get("DEEPSEEK_BASE_URL", "https://api.deepseek.com").rstrip("/")
    deepseek_model = _get("DEEPSEEK_MODEL", "deepseek-chat")

    # ---- Embedding ----
    embedding_provider = _get("EMBEDDING_PROVIDER", "local")
    embedding_model_name = _get("EMBEDDING_MODEL_NAME", "BAAI/bge-small-zh-v1.5")
    zhipu_api_key = _get("ZHIPU_API_KEY", "")
    zhipu_embedding_model = _get("ZHIPU_EMBEDDING_MODEL", "embedding-3")

    # ---- JWT ----
    jwt_secret = _get("JWT_SECRET") or ""

    # ---- MySQL ----
    mysql_host = _get("MYSQL_HOST", "127.0.0.1")
    mysql_port = int(_get("MYSQL_PORT", "3307"))
    mysql_user = _get("MYSQL_USER", "root")
    mysql_password = _get("MYSQL_PASSWORD", "")
    mysql_db = _get("MYSQL_DB", "neushare")

    # ---- 主后端（resource search tool）。Java 后端已于 2026-11-18 退役，端口仍是 8080 ----
    java_backend_url = _get("JAVA_BACKEND_URL", "http://localhost:8080").rstrip("/")

    # ---- Service ----
    ai_service_port = int(_get("AI_SERVICE_PORT", "8000"))
    vectorstore_dir = str((BASE_DIR / _get("VECTORSTORE_DIR", "./vectorstore")).resolve())
    uploads_dir = str((BASE_DIR / _get("UPLOADS_DIR", "../uploads")).resolve())
    rate_limit_per_minute = int(_get("RATE_LIMIT_PER_MINUTE", "10"))

    @property
    def mysql_url(self) -> str:
        # quote_plus the password so special chars (e.g. '@') don't break URL parsing
        return (
            f"mysql+pymysql://{self.mysql_user}:{quote_plus(self.mysql_password)}"
            f"@{self.mysql_host}:{self.mysql_port}/{self.mysql_db}?charset=utf8mb4"
        )


settings = Settings()
