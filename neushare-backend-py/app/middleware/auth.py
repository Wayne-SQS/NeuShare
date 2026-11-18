"""Auth dependencies (FastAPI Depends) replacing the Java JWT interceptors.

Mirrors WebMvcConfig's two-layer model:
  - get_current_user   : token required, else 401 (JwtInterceptor)
  - get_optional_user  : token optional; valid token writes identity, absent/invalid -> None (OptionalJwtInterceptor)
  - get_current_admin  : get_current_user + role == "admin", else 403

Token is decoded exactly once per request; claims returned as {userId, username, role}.
"""
from typing import Optional

from fastapi import Depends, Header

from app.core.security import decode_token, extract_bearer
from app.core.exceptions import UnauthorizedException, ForbiddenException


async def get_current_user(authorization: Optional[str] = Header(None)) -> dict:
    token = extract_bearer(authorization)
    user = decode_token(token) if token else None
    if not user:
        raise UnauthorizedException()
    return user


async def get_optional_user(authorization: Optional[str] = Header(None)) -> Optional[dict]:
    token = extract_bearer(authorization)
    if not token:
        return None
    return decode_token(token)


async def get_current_admin(user: dict = Depends(get_current_user)) -> dict:
    if user.get("role") != "admin":
        raise ForbiddenException()
    return user
