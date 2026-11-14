"""JWT validation compatible with the Java backend (jjwt, HS256).

Java stores: subject = userId (string), claims username / role.
"""
from typing import Optional
import jwt
from app.config import settings


def verify_token(token: str) -> dict:
    # jjwt 按密钥长度自动选 HS256/384/512：共享 secret 为 56 字节时 Java 签发 HS384。
    # 这里放行全部 HS* 算法，只要签名密钥一致即可验签通过，避免算法写死导致 401。
    payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256", "HS384", "HS512"])
    return {
        "userId": int(payload["sub"]),
        "username": payload.get("username", ""),
        "role": payload.get("role", "user"),
    }


def extract_user(authorization: Optional[str]) -> Optional[dict]:
    if not authorization or not authorization.startswith("Bearer "):
        return None
    token = authorization[7:]
    try:
        return verify_token(token)
    except Exception:
        return None
