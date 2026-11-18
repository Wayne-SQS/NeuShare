"""V7 BYOK：用户自带 AI API Key（从 master 的 Java AiConfigController 移植）。

契约与 master 完全一致，前端 /profile/ai 设置页零改动即可对接：
  GET /api/ai/config            -> {hasDeepseekKey, deepseekKeyMasked, hasTavilyKey, tavilyKeyMasked}
  PUT /api/ai/config            -> null=不改动、""=清除、有值=加密保存
  GET /api/ai/config/internal   -> 给 neushare-ai 服务取明文（持用户 JWT）

安全约束：
  - key 用 AES-256-GCM 加密落库，主密钥只从环境变量 AI_KEY_ENCRYPT_SECRET 读；
  - 用户接口只回掩码，永不回明文；
  - 路径刻意不放 /api/user/*（那是 JWT 白名单），三个接口都要求登录。
"""
from __future__ import annotations

import base64
import os
from typing import Optional

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.response import success, error
from app.db.session import get_db
from app.middleware.auth import get_current_user

router = APIRouter(prefix="/api/ai", tags=["ai-config"])


def _master_key() -> bytes:
    secret = getattr(settings, "ai_key_encrypt_secret", "") or os.getenv("AI_KEY_ENCRYPT_SECRET", "")
    if not secret:
        raise RuntimeError("AI_KEY_ENCRYPT_SECRET 未配置，无法加解密用户 AI Key")
    # 派生 32 字节主密钥；不做硬编码 fallback
    import hashlib
    return hashlib.sha256(secret.encode("utf-8")).digest()


def encrypt(plain: str) -> str:
    key = _master_key()
    nonce = os.urandom(12)
    ct = AESGCM(key).encrypt(nonce, plain.encode("utf-8"), None)
    return base64.b64encode(nonce + ct).decode("ascii")


def decrypt(blob: str) -> str:
    try:
        raw = base64.b64decode(blob)
        return AESGCM(_master_key()).decrypt(raw[:12], raw[12:], None).decode("utf-8")
    except Exception:
        return ""


def mask(key: str) -> str:
    if not key:
        return ""
    return key if len(key) <= 8 else f"{key[:4]}****{key[-4:]}"


class AiConfigUpdate(BaseModel):
    # None = 不改动该字段；"" = 清除；有值 = 保存
    deepseekKey: Optional[str] = None
    tavilyKey: Optional[str] = None


async def _row(db: AsyncSession, user_id: int) -> dict:
    row = (await db.execute(text(
        "SELECT deepseek_key_enc, tavily_key_enc FROM ai_user_api_config WHERE user_id = :uid"
    ), {"uid": user_id})).mappings().first()
    return dict(row) if row else {}


@router.get("/config")
async def get_status(user: dict = Depends(get_current_user),
                     db: AsyncSession = Depends(get_db)):
    row = await _row(db, user["userId"])
    deepseek = decrypt(row.get("deepseek_key_enc") or "")
    tavily = decrypt(row.get("tavily_key_enc") or "")
    return success({
        "hasDeepseekKey": bool(deepseek),
        "deepseekKeyMasked": mask(deepseek),
        "hasTavilyKey": bool(tavily),
        "tavilyKeyMasked": mask(tavily),
    })


@router.put("/config")
async def update_config(body: AiConfigUpdate,
                        user: dict = Depends(get_current_user),
                        db: AsyncSession = Depends(get_db)):
    uid = user["userId"]
    row = await _row(db, uid)
    deepseek = row.get("deepseek_key_enc")
    tavily = row.get("tavily_key_enc")
    if body.deepseekKey is not None:
        deepseek = encrypt(body.deepseekKey.strip()) if body.deepseekKey.strip() else None
    if body.tavilyKey is not None:
        tavily = encrypt(body.tavilyKey.strip()) if body.tavilyKey.strip() else None
    await db.execute(text(
        "INSERT INTO ai_user_api_config (user_id, deepseek_key_enc, tavily_key_enc) "
        "VALUES (:uid, :d, :t) ON DUPLICATE KEY UPDATE "
        "deepseek_key_enc = VALUES(deepseek_key_enc), tavily_key_enc = VALUES(tavily_key_enc)"
    ), {"uid": uid, "d": deepseek, "t": tavily})
    await db.commit()
    return success("已保存")


@router.get("/config/internal")
async def get_plain(user: dict = Depends(get_current_user),
                    db: AsyncSession = Depends(get_db)):
    """给 neushare-ai 服务：持用户 JWT 校验身份，返回该用户自己的明文 key。
    未配置返回空串，AI 侧据此降级平台 key。"""
    row = await _row(db, user["userId"])
    return success({
        "userId": user["userId"],
        "deepseekKey": decrypt(row.get("deepseek_key_enc") or ""),
        "tavilyKey": decrypt(row.get("tavily_key_enc") or ""),
    })
