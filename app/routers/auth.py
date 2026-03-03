"""Tensai — Auth router: send OTP, verify OTP, return JWT."""

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth_utils import create_access_token, create_refresh_token, validate_refresh_token
from app.config import get_settings
from app.database import get_db
from app.email_service import generate_otp, send_otp_email
from app.models import OTPCode, User

router = APIRouter(prefix="/auth", tags=["auth"])


class SendOtpRequest(BaseModel):
    email: EmailStr


class SendOtpResponse(BaseModel):
    message: str
    expires_in_minutes: int


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=6, max_length=6)


class VerifyOtpResponse(BaseModel):
    access_token: str
    refresh_token: str
    email: str
    is_new_user: bool


class RefreshRequest(BaseModel):
    refresh_token: str = Field(..., min_length=1)


class RefreshResponse(BaseModel):
    access_token: str


@router.post("/send-otp", response_model=SendOtpResponse)
async def send_otp(
    body: SendOtpRequest,
    db: AsyncSession = Depends(get_db),
) -> SendOtpResponse:
    """Delete old OTPs for this email, generate new OTP, save with expiry, send email."""
    settings = get_settings()
    email = body.email.lower().strip()
    await db.execute(delete(OTPCode).where(OTPCode.email == email))
    await db.flush()

    otp = generate_otp()
    # Store naive UTC: Supabase columns are TIMESTAMP WITHOUT TIME ZONE; asyncpg errors on
    # mixing offset-aware Python datetimes with that type. Email shows expiry in EMAIL_TIMEZONE (e.g. IST).
    expires_at = (datetime.now(timezone.utc) + timedelta(minutes=settings.otp_expire_minutes)).replace(tzinfo=None)
    row = OTPCode(email=email, code=otp, expires_at=expires_at, used=False)
    db.add(row)
    await db.flush()

    try:
        await send_otp_email(
            email,
            otp,
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=settings.otp_expire_minutes),
            expires_in_minutes=settings.otp_expire_minutes,
        )
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=502,
            detail=f"Failed to send OTP email: {e}",
        ) from e

    return SendOtpResponse(
        message="OTP sent to your email.",
        expires_in_minutes=settings.otp_expire_minutes,
    )


@router.post("/verify-otp", response_model=VerifyOtpResponse)
async def verify_otp(
    body: VerifyOtpRequest,
    db: AsyncSession = Depends(get_db),
) -> VerifyOtpResponse:
    """Find valid OTP (not used, not expired), mark used, create User if first time; return token + email + is_new_user."""
    # Naive UTC for comparison with DB TIMESTAMP WITHOUT TIME ZONE
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    email = body.email.lower().strip()
    result = await db.execute(
        select(OTPCode)
        .where(OTPCode.email == email)
        .where(OTPCode.code == body.code)
        .where(OTPCode.used == False)  # noqa: E712
        .where(OTPCode.expires_at > now)
        .limit(1)
    )
    otp_row = result.scalars().first()
    if otp_row is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP.",
        )
    otp_row.used = True
    await db.flush()

    user_result = await db.execute(select(User).where(User.email == email).limit(1))
    user = user_result.scalars().first()
    is_new_user = user is None
    if user is None:
        user = User(email=email, is_active=True)
        db.add(user)
        await db.flush()

    access_token = create_access_token(email)
    refresh_token = await create_refresh_token(user.id, db)
    return VerifyOtpResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        email=email,
        is_new_user=is_new_user,
    )


@router.post("/refresh", response_model=RefreshResponse)
async def refresh(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
) -> RefreshResponse:
    """Exchange a valid refresh token for a new access token."""
    user = await validate_refresh_token(body.refresh_token, db)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(user.email)
    return RefreshResponse(access_token=access_token)
