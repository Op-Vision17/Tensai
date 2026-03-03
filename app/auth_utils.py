"""Tensai — JWT creation, refresh tokens, and current-user dependencies."""

import hashlib
import secrets
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.database import get_db
from app.models import RefreshToken, User

_http_bearer = HTTPBearer()
_http_bearer_optional = HTTPBearer(auto_error=False)


def create_access_token(email: str) -> str:
    """Return a signed JWT string with sub=email and exp."""
    settings = get_settings()
    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {"sub": email, "exp": expire, "iat": now}
    return jwt.encode(
        payload,
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm,
    )


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


async def create_refresh_token(user_id: uuid.UUID, db: AsyncSession) -> str:
    """Generate a refresh token, store its hash in DB, return the plain token (store in client)."""
    settings = get_settings()
    plain = secrets.token_urlsafe(32)
    token_hash = _hash_token(plain)
    expires_at = (datetime.now(timezone.utc) + timedelta(days=settings.jwt_refresh_expire_days)).replace(tzinfo=None)
    row = RefreshToken(user_id=user_id, token_hash=token_hash, expires_at=expires_at)
    db.add(row)
    await db.flush()
    return plain


async def validate_refresh_token(token: str, db: AsyncSession) -> User | None:
    """If the refresh token is valid and not expired, return the User; else None."""
    if not token or not token.strip():
        return None
    token_hash = _hash_token(token.strip())
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    result = await db.execute(
        select(RefreshToken)
        .where(RefreshToken.token_hash == token_hash)
        .where(RefreshToken.expires_at > now)
        .limit(1)
    )
    ref = result.scalars().first()
    if ref is None:
        return None
    user_result = await db.execute(select(User).where(User.id == ref.user_id).limit(1))
    user = user_result.scalars().first()
    return user if user and user.is_active else None


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_http_bearer),
    db: AsyncSession = Depends(get_db),
) -> User:
    """FastAPI dependency: decode Bearer token, load User by email; raise 401 if invalid or missing."""
    if not credentials or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = credentials.credentials
    settings = get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        email = payload.get("sub")
        if not email or not isinstance(email, str):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    result = await db.execute(select(User).where(User.email == email).limit(1))
    user = result.scalars().first()
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User inactive",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


async def get_optional_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_http_bearer_optional),
    db: AsyncSession = Depends(get_db),
) -> User | None:
    """FastAPI dependency: same as get_current_user but returns None if no token or invalid."""
    if not credentials or not credentials.credentials:
        return None
    token = credentials.credentials
    settings = get_settings()
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        email = payload.get("sub")
        if not email or not isinstance(email, str):
            return None
    except JWTError:
        return None
    result = await db.execute(select(User).where(User.email == email).limit(1))
    user = result.scalars().first()
    if user is None or not user.is_active:
        return None
    return user
