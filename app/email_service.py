"""Tensai — OTP generation and email sending via SMTP."""

import secrets
from email.message import EmailMessage

import aiosmtplib

from app.config import get_settings


def generate_otp() -> str:
    """Return a 6-digit numeric OTP string."""
    return "".join(secrets.choice("0123456789") for _ in range(6))


async def send_otp_email(
    email: str,
    otp: str,
    expires_in_minutes: int | None = None,
) -> None:
    """Send OTP email via SMTP with STARTTLS on port 587. HTML body with OTP and validity."""
    settings = get_settings()
    if not settings.smtp_user or not settings.smtp_password:
        raise ValueError("SMTP credentials not configured (smtp_user, smtp_password)")

    validity = expires_in_minutes or getattr(settings, "otp_expire_minutes", 10)
    plain = f"Your Tensai verification code is: {otp}. Valid for {validity} minutes."

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Tensai — Verification code</title>
</head>
<body style="margin:0; padding:0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #0f0f0f;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0f0f0f;">
    <tr>
      <td align="center" style="padding: 32px 16px;">
        <table role="presentation" width="100%" style="max-width: 480px; background-color: #1a1a1a; border-radius: 16px;">
          <tr>
            <td style="height: 4px; background-color: #6366f1;"></td>
          </tr>
          <tr>
            <td style="padding: 28px 32px;">
              <p style="margin: 0 0 4px 0; font-size: 28px; font-weight: 700; color: #6366f1; letter-spacing: 2px;">TENSAI</p>
              <p style="margin: 0 0 24px 0; font-size: 13px; color: #888;">Tensai · AI Study Copilot</p>
              <div style="height: 1px; background-color: #2a2a2a; margin: 0 0 24px 0;"></div>
              <p style="margin: 0 0 12px 0; font-size: 15px; color: #e0e0e0;">Use this code to sign in:</p>
              <div style="margin: 0 0 20px 0; padding: 20px 24px; background-color: #0f0f0f; border: 1px solid #2a2a2a; border-radius: 12px; text-align: center;">
                <span style="font-size: 36px; font-weight: 700; letter-spacing: 10px; color: #ffffff;">{otp}</span>
              </div>
              <p style="margin: 0 0 24px 0; font-size: 13px; color: #888;">Valid for {validity} minutes.</p>
              <p style="margin: 0; font-size: 12px; color: #555;">If you didn't request this, ignore this email.</p>
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
