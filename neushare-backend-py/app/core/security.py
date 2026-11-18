"""JWT issuing/parsing (decode once) and password hashing.

JWT contract (identical to Java JwtUtil + neushare-ai):
  - sub = str(userId)
  - claims: username, role
  - signed with the shared JWT_SECRET (HS256 here; neushare-ai accepts HS256/384/512)
  - verify accepts HS256/HS384/HS512 so tokens issued by Java (HS384 for a 56B key) validate

Passwords use standard bcrypt, compatible with Spring's BCryptPasswordEncoder hashes in the DB.
"""
from datetime import datetime, timedelta, timezone
from typing import Optional

import jwt
import bcrypt

from app.core.config import settings

_ALGS = ["HS256", "HS384", "HS512"]


def create_token(user_id: int, username: str, role: str = "user") -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "username": username,
        "role": role,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(milliseconds=settings.jwt_expiration)).timestamp()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


def decode_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=_ALGS)
        return {
            "userId": int(payload["sub"]),
            "username": payload.get("username", ""),
            "role": payload.get("role", "user"),
        }
    except Exception:
        return None


def extract_bearer(authorization: Optional[str]) -> Optional[str]:
    if not authorization or not authorization.startswith("Bearer "):
        return None
    return authorization[7:]


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=10)).decode("utf-8")


def verify_password(password: str, hashed: str) -> bool:
    if not hashed:
        return False
    try:
        return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))
    except Exception:
        return False
