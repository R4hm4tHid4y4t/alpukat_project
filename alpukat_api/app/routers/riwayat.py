from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, delete, and_
from datetime import datetime, timezone
from app.database import get_db
from app.models.user import User
from app.models.master import Varietas, TingkatKematangan
from app.models.deteksi import HasilDeteksi, RiwayatDeteksi
from app.dependencies.auth import get_current_user
from app.services import image_service
from app.utils.response import success_response, paginated_response
from app.config import get_settings

router = APIRouter()
settings = get_settings()


# ── GET RIWAYAT (dengan pagination & filter) ──────────────
@router.get("/riwayat")
async def get_riwayat(
    page: int = Query(default=1, ge=1),
    per_page: int = Query(default=10, ge=1, le=50),
    varietas_id: int = Query(default=None),
    kematangan_id: int = Query(default=None),
    sort: str = Query(default="desc", pattern="^(asc|desc)$"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Base query: ambil hasil_deteksi milik user
    conditions = [HasilDeteksi.user_id == current_user.id]
    if varietas_id:
        conditions.append(HasilDeteksi.varietas_id == varietas_id)
    if kematangan_id:
        conditions.append(HasilDeteksi.kematangan_id == kematangan_id)

    # Hitung total
    count_q = await db.execute(
        select(func.count()).select_from(HasilDeteksi).where(and_(*conditions))
    )
    total = count_q.scalar()

    # Query data dengan JOIN
    order = HasilDeteksi.created_at.desc() if sort == "desc" else HasilDeteksi.created_at.asc()
    result = await db.execute(
        select(HasilDeteksi, Varietas, TingkatKematangan)
        .outerjoin(Varietas, HasilDeteksi.varietas_id == Varietas.id)
        .outerjoin(TingkatKematangan, HasilDeteksi.kematangan_id == TingkatKematangan.id)
        .where(and_(*conditions))
        .order_by(order)
        .limit(per_page)
        .offset((page - 1) * per_page)
    )
    rows = result.all()

    items = []
    for hasil, varietas, kematangan in rows:
        items.append({
            "id": hasil.id,
            "varietas_nama": varietas.nama_varietas if varietas else None,
            "kematangan_label": kematangan.label_kematangan if kematangan else None,
            "confidence_varietas": float(hasil.confidence_varietas) if hasil.confidence_varietas else None,
            "confidence_kematangan": float(hasil.confidence_kematangan) if hasil.confidence_kematangan else None,
            "gambar_url": image_service.get_image_url(hasil.gambar_input),
            "status_flag": hasil.status_flag,
            "created_at": hasil.created_at.isoformat() if hasil.created_at else None,
        })

    return paginated_response(items=items, total=total, page=page, per_page=per_page)


# ── GET DETAIL RIWAYAT ────────────────────────────────────
@router.get("/riwayat/{hasil_id}")
async def get_detail_riwayat(
    hasil_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HasilDeteksi, Varietas, TingkatKematangan)
        .outerjoin(Varietas, HasilDeteksi.varietas_id == Varietas.id)
        .outerjoin(TingkatKematangan, HasilDeteksi.kematangan_id == TingkatKematangan.id)
        .where(HasilDeteksi.id == hasil_id)
    )
    row = result.first()

    if not row:
        raise HTTPException(status_code=404, detail="Riwayat tidak ditemukan")

    hasil, varietas, kematangan = row

    # Cek kepemilikan — admin boleh lihat semua
    if hasil.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Akses ditolak")

    return success_response(
        data={
            "id": hasil.id,
            "varietas": {
                "id": varietas.id if varietas else None,
                "nama": varietas.nama_varietas if varietas else None,
                "deskripsi": varietas.deskripsi if varietas else None,
            },
            "kematangan": {
                "id": kematangan.id if kematangan else None,
                "label": kematangan.label_kematangan if kematangan else None,
                "deskripsi": kematangan.deskripsi if kematangan else None,
                "ciri_visual": kematangan.ciri_visual if kematangan else None,
            },
            "confidence_varietas": float(hasil.confidence_varietas) if hasil.confidence_varietas else None,
            "confidence_kematangan": float(hasil.confidence_kematangan) if hasil.confidence_kematangan else None,
            "status_flag": hasil.status_flag,
            "catatan_flag": hasil.catatan_flag,
            "gambar_url": image_service.get_image_url(hasil.gambar_input),
            "created_at": hasil.created_at.isoformat() if hasil.created_at else None,
        },
        message="Berhasil",
    )


# ── DELETE RIWAYAT ────────────────────────────────────────
@router.delete("/riwayat/{hasil_id}")
async def delete_riwayat(
    hasil_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HasilDeteksi).where(HasilDeteksi.id == hasil_id)
    )
    hasil = result.scalar_one_or_none()

    if not hasil:
        raise HTTPException(status_code=404, detail="Riwayat tidak ditemukan")

    if hasil.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Akses ditolak")

    await db.delete(hasil)
    await db.commit()

    return success_response(message="Riwayat berhasil dihapus")


# ── STATISTIK USER ────────────────────────────────────────
@router.get("/statistik")
async def get_statistik(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    now = datetime.now(timezone.utc)

    # Total deteksi user
    total_q = await db.execute(
        select(func.count()).select_from(HasilDeteksi)
        .where(HasilDeteksi.user_id == current_user.id)
    )
    total_deteksi = total_q.scalar()

    # Deteksi bulan ini
    bulan_q = await db.execute(
        select(func.count()).select_from(HasilDeteksi)
        .where(
            HasilDeteksi.user_id == current_user.id,
            func.month(HasilDeteksi.created_at) == now.month,
            func.year(HasilDeteksi.created_at) == now.year,
        )
    )
    deteksi_bulan_ini = bulan_q.scalar()

    # Rata-rata confidence
    avg_q = await db.execute(
        select(
            func.avg(HasilDeteksi.confidence_varietas),
            func.avg(HasilDeteksi.confidence_kematangan),
        ).where(HasilDeteksi.user_id == current_user.id)
    )
    avg_row = avg_q.first()
    avg_var = float(avg_row[0]) if avg_row[0] else 0
    avg_kem = float(avg_row[1]) if avg_row[1] else 0
    rata_rata = round((avg_var + avg_kem) / 2, 2) if (avg_var or avg_kem) else 0

    # Distribusi varietas
    var_q = await db.execute(
        select(Varietas.nama_varietas, func.count(HasilDeteksi.id).label("jumlah"))
        .join(HasilDeteksi, HasilDeteksi.varietas_id == Varietas.id)
        .where(HasilDeteksi.user_id == current_user.id)
        .group_by(Varietas.id)
    )
    distribusi_varietas_raw = var_q.all()

    # Distribusi kematangan
    kem_q = await db.execute(
        select(TingkatKematangan.label_kematangan, func.count(HasilDeteksi.id).label("jumlah"))
        .join(HasilDeteksi, HasilDeteksi.kematangan_id == TingkatKematangan.id)
        .where(HasilDeteksi.user_id == current_user.id)
        .group_by(TingkatKematangan.id)
    )
    distribusi_kematangan_raw = kem_q.all()

    def to_distribusi(rows):
        total = sum(r.jumlah for r in rows)
        return [
            {
                "nama": r[0],
                "jumlah": r.jumlah,
                "persentase": round(r.jumlah / total * 100, 1) if total > 0 else 0,
            }
            for r in rows
        ]

    distribusi_varietas = to_distribusi(distribusi_varietas_raw)
    varietas_terbanyak = (
        max(distribusi_varietas, key=lambda x: x["jumlah"])["nama"]
        if distribusi_varietas else None
    )

    return success_response(
        data={
            "total_deteksi": total_deteksi,
            "deteksi_bulan_ini": deteksi_bulan_ini,
            "rata_rata_confidence": rata_rata,
            "varietas_terbanyak": varietas_terbanyak,
            "distribusi_varietas": distribusi_varietas,
            "distribusi_kematangan": to_distribusi(distribusi_kematangan_raw),
        },
        message="Berhasil",
    )
