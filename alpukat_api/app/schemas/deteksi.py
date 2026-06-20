from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class VarietasResult(BaseModel):
    id: int
    nama: str
    deskripsi: Optional[str] = None

    model_config = {"from_attributes": True}


class KematanganResult(BaseModel):
    id: int
    label: str
    deskripsi: Optional[str] = None
    ciri_visual: Optional[str] = None

    model_config = {"from_attributes": True}


class HasilDeteksiResponse(BaseModel):
    id: int
    varietas: Optional[VarietasResult] = None
    kematangan: Optional[KematanganResult] = None
    confidence_varietas: Optional[float] = None
    confidence_kematangan: Optional[float] = None
    all_probs_varietas: Optional[dict] = None
    all_probs_kematangan: Optional[dict] = None
    status_flag: str
    gambar_url: Optional[str] = None
    inference_time_ms: Optional[float] = None
    created_at: Optional[str] = None

    model_config = {"from_attributes": True}


class RiwayatItem(BaseModel):
    id: int
    hasil_id: int
    varietas_nama: Optional[str] = None
    kematangan_label: Optional[str] = None
    confidence_varietas: Optional[float] = None
    confidence_kematangan: Optional[float] = None
    gambar_url: Optional[str] = None
    status_flag: str = "normal"
    aksi: str
    created_at: Optional[str] = None

    model_config = {"from_attributes": True}


class PaginationMeta(BaseModel):
    total: int
    page: int
    per_page: int
    last_page: int


class PaginatedRiwayat(BaseModel):
    items: List[RiwayatItem]
    meta: PaginationMeta


class DistribusiItem(BaseModel):
    nama: str
    jumlah: int
    persentase: float


class StatistikResponse(BaseModel):
    total_deteksi: int
    deteksi_bulan_ini: int
    rata_rata_confidence: Optional[float] = None
    varietas_terbanyak: Optional[str] = None
    distribusi_varietas: List[DistribusiItem] = []
    distribusi_kematangan: List[DistribusiItem] = []
