import os
import time
import uuid
import aiofiles
from fastapi import UploadFile, HTTPException
from app.config import get_settings
from datetime import datetime

settings = get_settings()

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/jpg", "image/png"}
JPEG_MAGIC = b"\xff\xd8"
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


async def validate_image(file: UploadFile) -> bytes:
    image_bytes = await file.read()

    # Cek ukuran
    max_bytes = settings.max_image_size_mb * 1024 * 1024
    if len(image_bytes) > max_bytes:
        raise HTTPException(
            status_code=400,
            detail=f"Ukuran file terlalu besar. Maksimal {settings.max_image_size_mb}MB",
        )

    # Cek content-type
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail="Format file tidak didukung. Gunakan JPG atau PNG",
        )

    # Cek magic bytes (validasi isi file bukan hanya ekstensi)
    if not (image_bytes[:2] == JPEG_MAGIC or image_bytes[:8] == PNG_MAGIC):
        raise HTTPException(
            status_code=400,
            detail="File bukan gambar yang valid",
        )

    return image_bytes


async def save_image(image_bytes: bytes, user_id: int) -> str:
    now = datetime.now()
    year = now.strftime("%Y")
    month = now.strftime("%m")

    dir_path = os.path.join(settings.storage_path, str(user_id), year, month)
    os.makedirs(dir_path, exist_ok=True)

    filename = f"{uuid.uuid4()}_{int(time.time())}.jpg"
    file_path = os.path.join(dir_path, filename)

    async with aiofiles.open(file_path, "wb") as f:
        await f.write(image_bytes)

    # Return path relatif dari storage_path
    return f"{user_id}/{year}/{month}/{filename}"


def get_image_url(relative_path: str) -> str:
    if not relative_path:
        return None
    return f"{settings.base_url}/storage/{relative_path}"


async def save_avatar(image_bytes: bytes, user_id: int) -> str:
    dir_path = os.path.join("storage", "avatars", str(user_id))
    os.makedirs(dir_path, exist_ok=True)

    filename = f"avatar_{int(time.time())}.jpg"
    file_path = os.path.join(dir_path, filename)

    async with aiofiles.open(file_path, "wb") as f:
        await f.write(image_bytes)

    return f"avatars/{user_id}/{filename}"
