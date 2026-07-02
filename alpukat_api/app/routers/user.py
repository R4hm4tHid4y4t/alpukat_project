import os
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models.user import User, ProfilPengguna
from app.schemas.user import UpdateProfileRequest, ChangePasswordRequest, ProfilResponse
from app.utils.security import hash_password, verify_password
from app.utils.response import success_response, error_response
from app.dependencies.auth import get_current_user
from app.services import image_service
from app.config import get_settings

router = APIRouter()
settings = get_settings()


# ── UC-10: GET PROFILE ────────────────────────────────────
@router.get("/profile")
async def get_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(ProfilPengguna).where(ProfilPengguna.user_id == current_user.id)
    )
    profil = result.scalar_one_or_none()

    foto_url = image_service.get_image_url(current_user.foto_profil) if current_user.foto_profil else None

    return success_response(
        data={
            "id": current_user.id,
            "nama": current_user.nama,
            "email": current_user.email,
            "role": current_user.role,
            "status_verifikasi": current_user.status_verifikasi,
            "foto_profil": foto_url,
            "bio": profil.bio if profil else None,
            "no_telepon": profil.no_telepon if profil else None,
            "created_at": current_user.created_at.isoformat() if current_user.created_at else None,
        },
        message="Berhasil mengambil data profil",
    )


# ── UC-10: UPDATE PROFILE ─────────────────────────────────
@router.put("/profile")
async def update_profile(
    body: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Update nama di tabel users
    if body.nama is not None:
        current_user.nama = body.nama

    # Update bio & no_telepon di tabel profil_pengguna
    result = await db.execute(
        select(ProfilPengguna).where(ProfilPengguna.user_id == current_user.id)
    )
    profil = result.scalar_one_or_none()

    if not profil:
        profil = ProfilPengguna(user_id=current_user.id)
        db.add(profil)

    if body.bio is not None:
        profil.bio = body.bio
    if body.no_telepon is not None:
        profil.no_telepon = body.no_telepon

    await db.commit()

    return success_response(message="Profil berhasil diperbarui")


# ── UPLOAD AVATAR ─────────────────────────────────────────
@router.post("/avatar")
async def upload_avatar(
    foto: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Validasi: hanya jpg/png, max 2MB
    ALLOWED = {"image/jpeg", "image/jpg", "image/png"}
    if foto.content_type not in ALLOWED:
        raise HTTPException(status_code=400, detail="Format foto tidak didukung. Gunakan JPG atau PNG")

    image_bytes = await foto.read()
    if len(image_bytes) > 2 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Ukuran foto maksimal 2MB")

    # Hapus foto lama jika ada
    if current_user.foto_profil:
        old_path = os.path.join(settings.storage_path, current_user.foto_profil)
        if os.path.exists(old_path):
            os.remove(old_path)

    # Simpan foto baru
    relative_path = await image_service.save_avatar(image_bytes, current_user.id)
    current_user.foto_profil = relative_path
    await db.commit()

    # Pakai helper yang sama dengan gambar deteksi (bukan bangun URL manual
    # lagi) supaya tidak ada lagi risiko salah path seperti sebelumnya.
    foto_url = image_service.get_image_url(relative_path)

    return success_response(
        data={"foto_profil_url": foto_url},
        message="Foto profil berhasil diperbarui",
    )


# ── GANTI PASSWORD ────────────────────────────────────────
@router.put("/password")
async def change_password(
    body: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Verifikasi password saat ini
    if not verify_password(body.current_password, current_user.password):
        raise HTTPException(status_code=400, detail="Password saat ini tidak sesuai")

    # Pastikan password baru cocok dengan konfirmasi
    if body.new_password != body.confirm_password:
        raise HTTPException(status_code=400, detail="Password baru dan konfirmasi tidak cocok")

    current_user.password = hash_password(body.new_password)
    await db.commit()

    return success_response(message="Password berhasil diubah")
