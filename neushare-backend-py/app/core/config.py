"""Application configuration — all values come from environment variables.

No real secrets are hard-coded. JWT_SECRET MUST equal neushare-ai's JWT_SECRET
at runtime so tokens issued by either service are mutually verifiable (JWT interop).
"""
import os
import logging
from pathlib import Path
from urllib.parse import quote_plus

from dotenv import load_dotenv

# config.py lives at .../neushare-backend-py/app/core/config.py -> go up 3 levels
BASE_DIR = Path(__file__).resolve().parent.parent.parent  # .../neushare-backend-py
load_dotenv(BASE_DIR / ".env")

log = logging.getLogger("config")
# 安全红线：JWT_SECRET 必须由环境变量注入，且与 neushare-ai 共用同一个值。
# 公开仓库里曾出现过明文密钥，绝不再提供硬编码 fallback；缺配置时启动即失败，
# 比「悄悄用一个谁都知道的密钥签发 token」安全得多。


def _get(key, default=None):
    v = os.getenv(key)
    return v if v not in (None, "") else default


class Settings:
    # ---- JWT ----
    jwt_secret = _get("JWT_SECRET") or ""
    jwt_expiration = int(_get("JWT_EXPIRATION", "86400000"))  # ms, matches Java

    # ---- MySQL (asyncmy) ----
    mysql_host = _get("MYSQL_HOST", "127.0.0.1")
    mysql_port = int(_get("MYSQL_PORT", "3307"))
    mysql_user = _get("MYSQL_USER", "root")
    mysql_password = _get("MYSQL_PASSWORD", "")
    mysql_db = _get("MYSQL_DB", "neushare")

    # ---- Redis (optional — cache degrades gracefully when empty/unreachable) ----
    redis_url = _get("REDIS_URL", "")

    # ---- Uploads ----
    upload_path = _get("UPLOAD_PATH", "uploads")

    # ---- CORS ----
    cors_origins = [o.strip() for o in _get("CORS_ORIGINS", "http://localhost:3000").split(",") if o.strip()]

    # ---- V7 BYOK ----
    ai_key_encrypt_secret = _get("AI_KEY_ENCRYPT_SECRET", "")

    # ---- V5 search ----
    search_fulltext_enabled = _get("SEARCH_FULLTEXT_ENABLED", "true").lower() == "true"

    # ---- Service ----
    port = int(_get("PORT", "8080"))

    def validate(self) -> None:
        if not self.jwt_secret:
            raise RuntimeError(
                "JWT_SECRET 未配置。请在 .env 中设置，并与 neushare-ai 使用同一值（HS256/384/512）。"
            )

    @property
    def db_url(self) -> str:
        return (
            f"mysql+asyncmy://{self.mysql_user}:{quote_plus(self.mysql_password)}"
            f"@{self.mysql_host}:{self.mysql_port}/{self.mysql_db}?charset=utf8mb4"
        )

    @property
    def upload_dir(self) -> Path:
        p = Path(self.upload_path)
        if not p.is_absolute():
            p = (BASE_DIR / p).resolve()
        return p


settings = Settings()
settings.validate()
