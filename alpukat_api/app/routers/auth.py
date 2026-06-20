from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from app.database import get_db
from app.models.user import User, OtpVerifikasi, ProfilPengguna
from app.schemas.auth import (
    RegisterRequest, LoginRequest, OtpVerifyRequest,
    ForgotPasswordRequest, ResetPasswordRequest,
    TokenResponse, UserResponse,
)
from app.utils.security import hash_password, verify_password, generate_otp
from app.utils.jwt import create_access_token, create_refresh_token, decode_token
from app.utils.response import success_response, error_response
from app.services.email_service import send_otp_email
from app.dependencies.auth import get_current_user, oauth2_scheme
from app.config import get_settings

router = APIRouter()
settings = get_settings()


def _make_token_response(user: User) -> dict:
    """Buat access + refresh token untuk user."""
    payload = {"sub": str(user.id), "role": user.role}
    return {
        "access_token": create_access_token(payload),
        "refresh_token": create_refresh_token(payload),
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "nama": user.nama,
            "email": user.email,
            "role": user.role,
            "status_verifikasi": user.status_verifikasi,
            "foto_profil": user.foto_profil,
        },
    }


async def _create_otp(db: AsyncSession, user_id: int, tipe: str) -> str:
    """Generate OTP baru dan simpan ke database."""
    kode = generate_otp(settings.otp_length)
    expired_at = datetime.now(timezone.utc) + timedelta(minutes=settings.otp_expire_minutes)

    # Nonaktifkan OTP lama dengan tipe yang sama
    await db.execute(
        update(OtpVerifikasi)
        .where(OtpVerifikasi.user_id == user_id, OtpVerifikasi.tipe == tipe)
        .values(status_digunakan=1)
    )

    otp = OtpVerifikasi(
        user_id=user_id,
        kode_otp=kode,
        tipe=tipe,
        status_digunakan=0,
        expired_at=expired_at,
    )
    db.add(otp)
    await db.flush()
    return kode


# ── UC-01: REGISTER ───────────────────────────────────────
@router.post("/register", status_code=201)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    # Cek email sudah terdaftar
    result = await db.execute(select(User).where(User.email == body.email))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email sudah terdaftar",
        )

    # Buat user baru
    user = User(
        nama=body.nama,
        email=body.email,
        password=hash_password(body.password),
        role="pengguna",
        status_verifikasi=0,
    )
    db.add(user)
    await db.flush()  # dapatkan user.id tanpa commit

    # Buat profil kosong
    db.add(ProfilPengguna(user_id=user.id))

    # Generate & kirim OTP verifikasi
    kode_otp = await _create_otp(db, user.id, "verifikasi")
    await db.commit()

    try:
        await send_otp_email(body.email, body.nama, kode_otp, "verifikasi")
    except Exception:
        # Jangan gagalkan registrasi jika email gagal terkirim
        pass

    return success_response(
        data={"user_id": user.id, "email": user.email},
        message="Registrasi berhasil. Kode OTP telah dikirim ke email Anda.",
        status_code=201,
    )


# ── UC-05: VERIFIKASI OTP ─────────────────────────────────
@router.post("/verify-otp")
async def verify_otp(body: OtpVerifyRequest, db: AsyncSession = Depends(get_db)):
    now = datetime.now(timezone.utc)

    # Cari OTP yang valid
    result = await db.execute(
        select(OtpVerifikasi).where(
            OtpVerifikasi.user_id == body.user_id,
            OtpVerifikasi.kode_otp == body.kode_otp,
            OtpVerifikasi.tipe == "verifikasi",
            OtpVerifikasi.status_digunakan == 0,
            OtpVerifikasi.expired_at > now,
        )
    )
    otp = result.scalar_one_or_none()

    if not otp:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kode OTP tidak valid atau sudah kedaluwarsa",
        )

    # Ambil user
    result = await db.execute(select(User).where(User.id == body.user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Pengguna tidak ditemukan")

    # Update status verifikasi user dan OTP
    user.status_verifikasi = 1
    otp.status_digunakan = 1
    await db.commit()

    return success_response(
        data=_make_token_response(user),
        message="Verifikasi berhasil. Selamat datang!",
    )


# ── UC-02: LOGIN ──────────────────────────────────────────
@router.post("/login")
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    # Cari user by email
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    # Jangan bocorkan apakah email ada atau tidak
    if not user or not verify_password(body.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email atau password salah",
        )

    # Akun belum diverifikasi — kirim ulang OTP
    if user.status_verifikasi == 0:
        kode_otp = await _create_otp(db, user.id, "verifikasi")
        await db.commit()
        try:
            await send_otp_email(user.email, user.nama, kode_otp, "verifikasi")
        except Exception:
            pass
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Akun belum diverifikasi. Kode OTP baru telah dikirim ke email Anda.",
        )

    return success_response(
        data=_make_token_response(user),
        message="Login berhasil",
    )


# ── UC-04: LUPA PASSWORD ──────────────────────────────────
@router.post("/forgot-password")
async def forgot_password(body: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    # Tetap return 200 meski email tidak ditemukan (jangan bocorkan info)
    if user and user.status_verifikasi == 1:
        kode_otp = await _create_otp(db, user.id, "reset")
        await db.commit()
        try:
            await send_otp_email(user.email, user.nama, kode_otp, "reset")
        except Exception:
            pass

    return success_response(
        message="Jika email terdaftar, kode OTP reset password akan dikirim.",
    )


# ── RESET PASSWORD ────────────────────────────────────────
@router.post("/reset-password")
async def reset_password(body: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    now = datetime.now(timezone.utc)

    # Cari user by email
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=400, detail="Email tidak ditemukan")

    # Validasi OTP reset
    result = await db.execute(
        select(OtpVerifikasi).where(
            OtpVerifikasi.user_id == user.id,
            OtpVerifikasi.kode_otp == body.kode_otp,
            OtpVerifikasi.tipe == "reset",
            OtpVerifikasi.status_digunakan == 0,
            OtpVerifikasi.expired_at > now,
        )
    )
    otp = result.scalar_one_or_none()
    if not otp:
        raise HTTPException(
            status_code=400,
            detail="Kode OTP tidak valid atau sudah kedaluwarsa",
        )

    # Update password & nonaktifkan semua OTP reset user ini
    user.password = hash_password(body.new_password)
    otp.status_digunakan = 1
    await db.execute(
        update(OtpVerifikasi)
        .where(OtpVerifikasi.user_id == user.id, OtpVerifikasi.tipe == "reset")
        .values(status_digunakan=1)
    )
    await db.commit()

    return success_response(message="Password berhasil diubah. Silakan login kembali.")


# ── REFRESH TOKEN ─────────────────────────────────────────
@router.post("/refresh")
async def refresh_token(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
):
    payload = decode_token(token)

    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Token tidak valid")

    user_id = int(payload.get("sub"))
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="Pengguna tidak ditemukan")

    new_access = create_access_token({"sub": str(user.id), "role": user.role})
    return success_response(
        data={"access_token": new_access, "token_type": "bearer"},
        message="Token berhasil diperbarui",
    )


# ── UC-03: LOGOUT ─────────────────────────────────────────
@router.post("/logout")
async def logout(current_user: User = Depends(get_current_user)):
    # Stateless JWT — client cukup hapus token dari storage
    # Untuk blacklist token, bisa ditambahkan ke Redis/DB di sini
    return success_response(message="Logout berhasil")
