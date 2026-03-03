"""Tensai — OTP generation and email sending via SMTP."""

import secrets
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
from zoneinfo import ZoneInfo

import aiosmtplib

from app.config import get_settings


def generate_otp() -> str:
    """Return a 6-digit numeric OTP string."""
    return "".join(secrets.choice("0123456789") for _ in range(6))


def _format_expiry_for_email(expires_at: datetime | None, tz_name: str = "Asia/Kolkata") -> str:
    """Format expiry datetime in the given timezone (e.g. IST for India)."""
    if expires_at is None:
        return ""
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    try:
        tz = ZoneInfo(tz_name)
    except Exception:
        tz = timezone.utc
    local = expires_at.astimezone(tz)
    return local.strftime("%d %b %Y, %I:%M %p %Z")


async def send_otp_email(
    email: str,
    otp: str,
    expires_at: datetime | None = None,
    expires_in_minutes: int | None = None,
) -> None:
    """Send OTP email via SMTP with STARTTLS on port 587. HTML body with OTP and expiry (e.g. IST)."""
    settings = get_settings()
    if not settings.smtp_user or not settings.smtp_password:
        raise ValueError("SMTP credentials not configured (smtp_user, smtp_password)")

    expiry_dt = expires_at
    if expiry_dt is None and expires_in_minutes is not None:
        expiry_dt = datetime.now(timezone.utc) + timedelta(minutes=expires_in_minutes)
    tz_name = getattr(settings, "email_timezone", "Asia/Kolkata")
    expiry_str = _format_expiry_for_email(expiry_dt, tz_name)
    validity = expires_in_minutes or getattr(settings, "otp_expire_minutes", 10)

    plain = f"Your Tensai verification code is: {otp}. Valid for {validity} minutes."
    if expiry_str:
        plain += f" Expires at {expiry_str}."

    expiry_line = f'<p style="margin: 0 0 24px 0; font-size: 13px; color: #666;">Expires at <strong>{expiry_str}</strong>.</p>' if expiry_str else ""

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tensai — Verification code</title>
</head>
<body style="margin:0; padding:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f5f5f5;">
    <tr>
      <td align="center" style="padding: 32px 16px;">
        <table role="presentation" width="100%" style="max-width: 440px; background-color: #ffffff; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.08);">
          <tr>
            <td style="padding: 32px 28px;">
              <h1 style="margin: 0 0 8px 0; font-size: 22px; font-weight: 600; color: #1a1a1a;">Tensai</h1>
              <p style="margin: 0 0 24px 0; font-size: 14px; color: #666;">Your AI Study Copilot</p>
              <p style="margin: 0 0 16px 0; font-size: 15px; color: #333;">Use this code to sign in:</p>
              <div style="margin: 0 0 24px 0; padding: 16px 20px; background-color: #f8f9fa; border-radius: 8px; text-align: center;">
                <span style="font-size: 28px; font-weight: 700; letter-spacing: 6px; color: #1a1a1a;">{otp}</span>
              </div>
              <p style="margin: 0 0 4px 0; font-size: 13px; color: #666;">Valid for <strong>{validity} minutes</strong>.</p>
              {expiry_line}
              <p style="margin: 0; font-size: 12px; color: #999;">If you didn't request this code, you can ignore this email.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>"""

    msg = EmailMessage()
    msg["Subject"] = "Tensai — Your verification code"
    msg["From"] = settings.smtp_from_email
    msg["To"] = email
    msg.set_content(plain)
    msg.add_alternative(html, subtype="html")
    await aiosmtplib.send(
        msg,
        hostname=settings.smtp_host,
        port=settings.smtp_port,
        username=settings.smtp_user,
        password=settings.smtp_password,
        start_tls=True,
    )
