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

# Dev-only fallback (>=32 bytes). Used only when JWT_SECRET env is absent.
# When launching the Java backend for the demo, set the SAME value.
DEV_JWT_SECRET = "neushare-dev-jwt-secret-please-change-in-production-2026"

log = logging.getLogger("config")
if not os.getenv("JWT_SECRET"):
    log.warning("JWT_SECRET env not set; using DEV fallback. Set it to match Java backend in production.")
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
    jwt_secret = _get("JWT_SECRET") or DEV_JWT_SECRET

    # ---- MySQL ----
    mysql_host = _get("MYSQL_HOST", "127.0.0.1")
    mysql_port = int(_get("MYSQL_PORT", "3307"))
    mysql_user = _get("MYSQL_USER", "root")
    mysql_password = _get("MYSQL_PASSWORD", "NeuShare@2026")
    mysql_db = _get("MYSQL_DB", "neushare")

    # ---- Java backend (resource search tool) ----
    java_backend_url = _get("JAVA_BACKEND_URL", "http://localhost:8080").rstrip("/")

    # ---- Service ----
    ai_service_port = int(_get("AI_SERVICE_PORT", "8000"))
    vectorstore_dir = str((BASE_DIR / _get("VECTORSTORE_DIR", "./vectorstore")).resolve())
    uploads_dir = str((BASE_DIR / _get("UPLOADS_DIR", "../neushare-backend/uploads")).resolve())
    rate_limit_per_minute = int(_get("RATE_LIMIT_PER_MINUTE", "10"))

    @property
    def mysql_url(self) -> str:
        # quote_plus the password so special chars (e.g. '@') don't break URL parsing
        return (
            f"mysql+pymysql://{self.mysql_user}:{quote_plus(self.mysql_password)}"
            f"@{self.mysql_host}:{self.mysql_port}/{self.mysql_db}?charset=utf8mb4"
        )


settings = Settings()
