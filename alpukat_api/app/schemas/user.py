from pydantic import BaseModel, field_validator
from typing import Optional
import re


class UpdateProfileRequest(BaseModel):
    nama: Optional[str] = None
    bio: Optional[str] = None
    no_telepon: Optional[str] = None

    @field_validator("nama")
    @classmethod
    def validate_nama(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            if len(v) < 2:
                raise ValueError("Nama minimal 2 karakter")
            if len(v) > 100:
                raise ValueError("Nama maksimal 100 karakter")
        return v

    @field_validator("no_telepon")
    @classmethod
    def validate_telepon(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v.strip():
            if not re.match(r"^[0-9+\-\s]{8,15}$", v):
                raise ValueError("Format nomor telepon tidak valid")
        return v


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str
    confirm_password: str

    @field_validator("new_password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password baru minimal 8 karakter")
        if not re.search(r"[A-Za-z]", v):
            raise ValueError("Password harus mengandung huruf")
        if not re.search(r"\d", v):
            raise ValueError("Password harus mengandung angka")
        return v

    @classmethod
    def model_post_init(cls, __context) -> None:
        pass

    def check_passwords_match(self) -> bool:
        return self.new_password == self.confirm_password


class ProfilResponse(BaseModel):
    id: int
    nama: str
    email: str
    role: str
    status_verifikasi: int
    foto_profil: Optional[str] = None
    bio: Optional[str] = None
    no_telepon: Optional[str] = None

    model_config = {"from_attributes": True}


class StatistikPenggunaResponse(BaseModel):
    total_deteksi: int
    deteksi_bulan_ini: int
    rata_rata_confidence: Optional[float] = None
    varietas_terbanyak: Optional[str] = None
    tanggal_bergabung: Optional[str] = None
