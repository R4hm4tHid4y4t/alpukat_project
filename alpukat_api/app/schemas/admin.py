from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, List


class DashboardResponse(BaseModel):
    total_pengguna: int
    total_deteksi: int
    deteksi_hari_ini: int
    deteksi_bulan_ini: int
    total_flagged: int
    akurasi_model_varietas: Optional[float] = None
    akurasi_model_kematangan: Optional[float] = None
    tren_mingguan: List[dict] = []
    distribusi_varietas: List[dict] = []
    distribusi_kematangan: List[dict] = []


class UserAdminItem(BaseModel):
    id: int
    nama: str
    email: str
    role: str
    status_verifikasi: int
    foto_profil: Optional[str] = None
    total_deteksi: int = 0
    created_at: Optional[str] = None

    model_config = {"from_attributes": True}


class VarietasCRUD(BaseModel):
    nama_varietas: str
    deskripsi: Optional[str] = None
    gambar_referensi: Optional[str] = None

    @field_validator("nama_varietas")
    @classmethod
    def validate_nama(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Nama varietas minimal 2 karakter")
        if len(v) > 100:
            raise ValueError("Nama varietas maksimal 100 karakter")
        return v


class KematanganCRUD(BaseModel):
    label_kematangan: str
    deskripsi: Optional[str] = None
    ciri_visual: Optional[str] = None

    @field_validator("label_kematangan")
    @classmethod
    def validate_label(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Label kematangan minimal 2 karakter")
        return v


class ModelCnnResponse(BaseModel):
    id: int
    versi: str
    akurasi: Optional[float] = None
    format_file: str
    deskripsi: Optional[str] = None
    status_aktif: int
    uploaded_by: Optional[int] = None
    created_at: Optional[str] = None

    model_config = {"from_attributes": True}


class FlagRequest(BaseModel):
    status_flag: str
    catatan_flag: Optional[str] = None

    @field_validator("status_flag")
    @classmethod
    def validate_flag(cls, v: str) -> str:
        allowed = {"perlu_ditinjau", "normal", "sudah_ditinjau"}
        if v not in allowed:
            raise ValueError(f"status_flag harus salah satu dari: {', '.join(allowed)}")
        return v
