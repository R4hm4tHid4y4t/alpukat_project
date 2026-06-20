from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from app.config import get_settings

settings = get_settings()

conf = ConnectionConfig(
    MAIL_USERNAME=settings.mail_username,
    MAIL_PASSWORD=settings.mail_password,
    MAIL_FROM=settings.mail_from,
    MAIL_PORT=settings.mail_port,
    MAIL_SERVER=settings.mail_server,
    MAIL_STARTTLS=settings.mail_starttls,
    MAIL_SSL_TLS=settings.mail_ssl_tls,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True,
)

fm = FastMail(conf)


def _build_otp_html(nama: str, kode_otp: str, tipe: str, expire_menit: int) -> str:
    if tipe == "verifikasi":
        judul = "Verifikasi Akun Anda"
        subjudul = "Gunakan kode OTP berikut untuk memverifikasi akun Anda."
        catatan = "Jika Anda tidak mendaftar di Alpukat CNN, abaikan email ini."
    else:
        judul = "Reset Password"
        subjudul = "Gunakan kode OTP berikut untuk mereset password Anda."
        catatan = "Jika Anda tidak meminta reset password, abaikan email ini dan segera amankan akun Anda."

    return f"""
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{judul} - Alpukat CNN</title>
</head>
<body style="margin:0;padding:0;background-color:#F8F9FA;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#F8F9FA;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="560" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:12px;overflow:hidden;
                      box-shadow:0 4px 16px rgba(0,0,0,0.08);">

          <!-- Header -->
          <tr>
            <td style="background-color:#2D6A4F;padding:32px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;
                         letter-spacing:1px;">🥑 Alpukat CNN</h1>
              <p style="margin:6px 0 0;color:#B7E4C7;font-size:13px;">
                Klasifikasi Varietas &amp; Deteksi Kematangan
              </p>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:36px 40px;">
              <p style="margin:0 0 8px;color:#1A1A2E;font-size:16px;">
                Halo, <strong>{nama}</strong>!
              </p>
              <h2 style="margin:0 0 12px;color:#2D6A4F;font-size:20px;">{judul}</h2>
              <p style="margin:0 0 24px;color:#555;font-size:14px;line-height:1.6;">
                {subjudul}
              </p>

              <!-- OTP Box -->
              <div style="background:#F0FFF4;border:2px dashed #52B788;border-radius:10px;
                          padding:24px;text-align:center;margin-bottom:24px;">
                <p style="margin:0 0 8px;color:#555;font-size:13px;text-transform:uppercase;
                           letter-spacing:1px;">Kode OTP Anda</p>
                <p style="margin:0;font-size:42px;font-weight:700;letter-spacing:12px;
                           color:#2D6A4F;font-family:'Courier New',monospace;">{kode_otp}</p>
                <p style="margin:10px 0 0;color:#E63946;font-size:12px;">
                  ⏱ Berlaku selama <strong>{expire_menit} menit</strong>
                </p>
              </div>

              <p style="margin:0 0 8px;color:#777;font-size:12px;line-height:1.6;">
                ⚠️ {catatan}
              </p>
              <p style="margin:0;color:#777;font-size:12px;">
                Jangan bagikan kode ini kepada siapapun termasuk tim Alpukat CNN.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background:#F8F9FA;padding:20px 40px;text-align:center;
                       border-top:1px solid #E8E8E8;">
              <p style="margin:0;color:#aaa;font-size:11px;">
                © 2026 Alpukat CNN — Politeknik Negeri Padang<br>
                Rahmat Hidayat (2311081030)
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
"""


async def send_otp_email(email: str, nama: str, kode_otp: str, tipe: str) -> None:
    subject_map = {
        "verifikasi": "🔐 Kode OTP Verifikasi Akun - Alpukat CNN",
        "reset": "🔑 Kode OTP Reset Password - Alpukat CNN",
    }
    subject = subject_map.get(tipe, "Kode OTP - Alpukat CNN")
    html_body = _build_otp_html(
        nama=nama,
        kode_otp=kode_otp,
        tipe=tipe,
        expire_menit=settings.otp_expire_minutes,
    )

    message = MessageSchema(
        subject=subject,
        recipients=[email],
        body=html_body,
        subtype=MessageType.html,
    )

    await fm.send_message(message)
