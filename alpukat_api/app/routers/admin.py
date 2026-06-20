import csv
import io
import os
import aiofiles
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, Form
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, update, delete, and_, or_, desc, text
from app.database import get_db
from app.models.user import User, ProfilPengguna
from app.models.master import Varietas, TingkatKematangan, ModelCnn
from app.models.deteksi import HasilDeteksi, RiwayatDeteksi
from app.dependencies.auth import get_current_admin
from app.schemas.admin import VarietasCRUD, KematanganCRUD, FlagRequest
from app.services.tflite_service import TFLiteInferenceService
from app.utils.response import success_response, paginated_response
from app.config import get_settings

router = APIRouter()
settings = get_settings()


# ── UC-11: DASHBOARD ADMIN ────────────────────────────────
@router.get("/dashboard")
async def dashboard(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    now = datetime.now(timezone.utc)

    total_pengguna = (await db.execute(
        select(func.count()).select_from(User).where(User.role == "pengguna")
    )).scalar()

    total_deteksi = (await db.execute(
        select(func.count()).select_from(HasilDeteksi)
    )).scalar()

    deteksi_hari_ini = (await db.execute(
        select(func.count()).select_from(HasilDeteksi)
        .where(func.date(HasilDeteksi.created_at) == func.curdate())
    )).scalar()

    deteksi_bulan_ini = (await db.execute(
        select(func.count()).select_from(HasilDeteksi)
        .where(
            func.month(HasilDeteksi.created_at) == now.month,
            func.year(HasilDeteksi.created_at) == now.year,
        )
    )).scalar()

    total_flagged = (await db.execute(
        select(func.count()).select_from(HasilDeteksi)
        .where(HasilDeteksi.status_flag == "perlu_ditinjau")
    )).scalar()

    # Akurasi dari model aktif
    model_aktif = (await db.execute(
        select(ModelCnn).where(ModelCnn.status_aktif == 1).limit(1)
    )).scalar_one_or_none()

    # Tren 7 hari terakhir
    tren_q = await db.execute(
        select(
            func.date(HasilDeteksi.created_at).label("tanggal"),
            func.count().label("jumlah"),
        )
        .where(
            HasilDeteksi.created_at >= func.date_sub(func.curdate(), text("interval 7 day"))
        )
        .group_by(func.date(HasilDeteksi.created_at))
        .order_by(func.date(HasilDeteksi.created_at))
    )
    tren_mingguan = [
        {"tanggal": str(r.tanggal), "jumlah": r.jumlah}
        for r in tren_q.all()
    ]

    # Distribusi varietas
    var_q = await db.execute(
        select(Varietas.nama_varietas, func.count(HasilDeteksi.id).label("jumlah"))
        .join(HasilDeteksi, HasilDeteksi.varietas_id == Varietas.id)
        .group_by(Varietas.id)
    )
    var_rows = var_q.all()
    total_var = sum(r.jumlah for r in var_rows)
    distribusi_varietas = [
        {"nama": r.nama_varietas, "jumlah": r.jumlah,
         "persentase": round(r.jumlah / total_var * 100, 1) if total_var else 0}
        for r in var_rows
    ]

    # Distribusi kematangan
    kem_q = await db.execute(
        select(TingkatKematangan.label_kematangan, func.count(HasilDeteksi.id).label("jumlah"))
        .join(HasilDeteksi, HasilDeteksi.kematangan_id == TingkatKematangan.id)
        .group_by(TingkatKematangan.id)
    )
    kem_rows = kem_q.all()
    total_kem = sum(r.jumlah for r in kem_rows)
    distribusi_kematangan = [
        {"label": r.label_kematangan, "jumlah": r.jumlah,
         "persentase": round(r.jumlah / total_kem * 100, 1) if total_kem else 0}
        for r in kem_rows
    ]

    return success_response(data={
        "total_pengguna": total_pengguna,
        "total_deteksi": total_deteksi,
        "deteksi_hari_ini": deteksi_hari_ini,
        "deteksi_bulan_ini": deteksi_bulan_ini,
        "total_flagged": total_flagged,
        "akurasi_model": float(model_aktif.akurasi) if model_aktif and model_aktif.akurasi else None,
        "model_versi": model_aktif.versi if model_aktif else None,
        "tren_mingguan": tren_mingguan,
        "distribusi_varietas": distribusi_varietas,
        "distribusi_kematangan": distribusi_kematangan,
    })


# ── UC-14: MANAJEMEN PENGGUNA ─────────────────────────────
@router.get("/users")
async def list_users(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    search: str = Query(None),
    role: str = Query(None),
    status: int = Query(None),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    conditions = []
    if search:
        conditions.append(or_(
            User.nama.ilike(f"%{search}%"),
            User.email.ilike(f"%{search}%"),
        ))
    if role:
        conditions.append(User.role == role)
    if status is not None:
        conditions.append(User.status_verifikasi == status)

    total = (await db.execute(
        select(func.count()).select_from(User).where(and_(*conditions) if conditions else True)
    )).scalar()

    result = await db.execute(
        select(User).where(and_(*conditions) if conditions else True)
        .order_by(desc(User.created_at))
        .limit(per_page).offset((page - 1) * per_page)
    )
    users = result.scalars().all()

    items = []
    for u in users:
        count_q = await db.execute(
            select(func.count()).select_from(HasilDeteksi).where(HasilDeteksi.user_id == u.id)
        )
        items.append({
            **u.to_dict(),
            "total_deteksi": count_q.scalar(),
        })

    return paginated_response(items=items, total=total, page=page, per_page=per_page)


@router.put("/users/{user_id}/toggle-role")
async def toggle_role(
    user_id: int,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Tidak dapat mengubah role diri sendiri")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Pengguna tidak ditemukan")

    user.role = "admin" if user.role == "pengguna" else "pengguna"
    await db.commit()
    return success_response(
        data={"id": user.id, "role": user.role},
        message=f"Role berhasil diubah menjadi {user.role}",
    )


@router.put("/users/{user_id}/toggle-status")
async def toggle_status(
    user_id: int,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="Tidak dapat menonaktifkan akun sendiri")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Pengguna tidak ditemukan")

    user.status_verifikasi = 0 if user.status_verifikasi == 1 else 1
    await db.commit()
    status_label = "aktif" if user.status_verifikasi == 1 else "nonaktif"
    return success_response(
        data={"id": user.id, "status_verifikasi": user.status_verifikasi},
        message=f"Akun berhasil di{status_label}kan",
    )


# ── UC-12: CRUD VARIETAS ──────────────────────────────────
@router.get("/varietas")
async def list_varietas(admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Varietas).order_by(Varietas.id))
    varietas_list = result.scalars().all()
    items = []
    for v in varietas_list:
        count_q = await db.execute(
            select(func.count()).select_from(HasilDeteksi).where(HasilDeteksi.varietas_id == v.id)
        )
        items.append({**v.to_dict(), "total_deteksi": count_q.scalar()})
    return success_response(data=items)


@router.post("/varietas", status_code=201)
async def create_varietas(
    body: VarietasCRUD,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    exists = (await db.execute(
        select(Varietas).where(func.lower(Varietas.nama_varietas) == body.nama_varietas.lower())
    )).scalar_one_or_none()
    if exists:
        raise HTTPException(status_code=400, detail="Nama varietas sudah ada")

    v = Varietas(**body.model_dump())
    db.add(v)
    await db.commit()
    return success_response(data=v.to_dict(), message="Varietas berhasil ditambahkan", status_code=201)


@router.put("/varietas/{varietas_id}")
async def update_varietas(
    varietas_id: int, body: VarietasCRUD,
    admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Varietas).where(Varietas.id == varietas_id))
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Varietas tidak ditemukan")
    for key, val in body.model_dump(exclude_none=True).items():
        setattr(v, key, val)
    await db.commit()
    return success_response(data=v.to_dict(), message="Varietas berhasil diperbarui")


@router.delete("/varietas/{varietas_id}")
async def delete_varietas(
    varietas_id: int,
    admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db),
):
    count_q = await db.execute(
        select(func.count()).select_from(HasilDeteksi).where(HasilDeteksi.varietas_id == varietas_id)
    )
    if count_q.scalar() > 0:
        raise HTTPException(
            status_code=400,
            detail=f"Varietas masih digunakan dalam {count_q.scalar()} riwayat deteksi"
        )
    result = await db.execute(select(Varietas).where(Varietas.id == varietas_id))
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Varietas tidak ditemukan")
    await db.delete(v)
    await db.commit()
    return success_response(message="Varietas berhasil dihapus")


# ── UC-13: CRUD KEMATANGAN ────────────────────────────────
@router.get("/kematangan")
async def list_kematangan(admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(TingkatKematangan).order_by(TingkatKematangan.id))
    items = result.scalars().all()
    data = []
    for k in items:
        count_q = await db.execute(
            select(func.count()).select_from(HasilDeteksi).where(HasilDeteksi.kematangan_id == k.id)
        )
        data.append({**k.to_dict(), "total_deteksi": count_q.scalar()})
    return success_response(data=data)


@router.post("/kematangan", status_code=201)
async def create_kematangan(
    body: KematanganCRUD,
    admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db),
):
    k = TingkatKematangan(**body.model_dump())
    db.add(k)
    await db.commit()
    return success_response(data=k.to_dict(), message="Tingkat kematangan berhasil ditambahkan", status_code=201)


@router.put("/kematangan/{kematangan_id}")
async def update_kematangan(
    kematangan_id: int, body: KematanganCRUD,
    admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(TingkatKematangan).where(TingkatKematangan.id == kematangan_id))
    k = result.scalar_one_or_none()
    if not k:
        raise HTTPException(status_code=404, detail="Tingkat kematangan tidak ditemukan")
    for key, val in body.model_dump(exclude_none=True).items():
        setattr(k, key, val)
    await db.commit()
    return success_response(data=k.to_dict(), message="Tingkat kematangan berhasil diperbarui")


@router.delete("/kematangan/{kematangan_id}")
async def delete_kematangan(
    kematangan_id: int,
    admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db),
):
    count_q = await db.execute(
        select(func.count()).select_from(HasilDeteksi).where(HasilDeteksi.kematangan_id == kematangan_id)
    )
    if count_q.scalar() > 0:
        raise HTTPException(status_code=400, detail="Tingkat kematangan masih digunakan dalam riwayat deteksi")
    result = await db.execute(select(TingkatKematangan).where(TingkatKematangan.id == kematangan_id))
    k = result.scalar_one_or_none()
    if not k:
        raise HTTPException(status_code=404, detail="Tingkat kematangan tidak ditemukan")
    await db.delete(k)
    await db.commit()
    return success_response(message="Tingkat kematangan berhasil dihapus")


# ── UC-15: KELOLA MODEL CNN ───────────────────────────────
@router.get("/model")
async def list_model(admin: User = Depends(get_current_admin), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(ModelCnn).order_by(desc(ModelCnn.created_at)))
    return success_response(data=[m.to_dict() for m in result.scalars().all()])


@router.post("/model/activate/{model_id}")
async def activate_model(
    model_id: int,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(ModelCnn).where(ModelCnn.id == model_id))
    model = result.scalar_one_or_none()
    if not model:
        raise HTTPException(status_code=404, detail="Model tidak ditemukan")

    # Nonaktifkan semua model, aktifkan yang dipilih
    await db.execute(update(ModelCnn).values(status_aktif=0))
    model.status_aktif = 1
    await db.commit()

    # Reload TFLite service jika path tersedia
    try:
        varietas_path = f"models_tflite/varietas_{model.versi}.tflite"
        kematangan_path = f"models_tflite/kematangan_{model.versi}.tflite"
        if os.path.exists(varietas_path) and os.path.exists(kematangan_path):
            TFLiteInferenceService.reload(varietas_path, kematangan_path, settings)
    except Exception:
        pass

    return success_response(
        data=model.to_dict(),
        message=f"Model {model.versi} berhasil diaktifkan",
    )


# ── UC-16, UC-17: RIWAYAT DETEKSI GLOBAL ─────────────────
@router.get("/deteksi")
async def list_deteksi_global(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    varietas_id: int = Query(None),
    kematangan_id: int = Query(None),
    flag: str = Query(None),
    search: str = Query(None),
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    conditions = []
    if varietas_id:
        conditions.append(HasilDeteksi.varietas_id == varietas_id)
    if kematangan_id:
        conditions.append(HasilDeteksi.kematangan_id == kematangan_id)
    if flag:
        conditions.append(HasilDeteksi.status_flag == flag)
    if search:
        conditions.append(or_(
            User.nama.ilike(f"%{search}%"),
            User.email.ilike(f"%{search}%"),
        ))

    base_query = (
        select(HasilDeteksi, User, Varietas, TingkatKematangan)
        .join(User, HasilDeteksi.user_id == User.id)
        .outerjoin(Varietas, HasilDeteksi.varietas_id == Varietas.id)
        .outerjoin(TingkatKematangan, HasilDeteksi.kematangan_id == TingkatKematangan.id)
        .where(and_(*conditions) if conditions else True)
    )

    total = (await db.execute(
        select(func.count()).select_from(base_query.subquery())
    )).scalar()

    result = await db.execute(
        base_query.order_by(desc(HasilDeteksi.created_at))
        .limit(per_page).offset((page - 1) * per_page)
    )

    items = []
    for hasil, user, varietas, kematangan in result.all():
        items.append({
            "id": hasil.id,
            "pengguna": {"id": user.id, "nama": user.nama, "email": user.email},
            "varietas_nama": varietas.nama_varietas if varietas else None,
            "kematangan_label": kematangan.label_kematangan if kematangan else None,
            "confidence_varietas": float(hasil.confidence_varietas) if hasil.confidence_varietas else None,
            "confidence_kematangan": float(hasil.confidence_kematangan) if hasil.confidence_kematangan else None,
            "status_flag": hasil.status_flag,
            "catatan_flag": hasil.catatan_flag,
            "created_at": hasil.created_at.isoformat() if hasil.created_at else None,
        })

    return paginated_response(items=items, total=total, page=page, per_page=per_page)


@router.put("/deteksi/{hasil_id}/flag")
async def flag_deteksi(
    hasil_id: int,
    body: FlagRequest,
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(HasilDeteksi).where(HasilDeteksi.id == hasil_id))
    hasil = result.scalar_one_or_none()
    if not hasil:
        raise HTTPException(status_code=404, detail="Hasil deteksi tidak ditemukan")

    hasil.status_flag = body.status_flag
    hasil.catatan_flag = body.catatan_flag

    db.add(RiwayatDeteksi(
        user_id=admin.id,
        hasil_id=hasil_id,
        aksi="ditandai_admin",
    ))
    await db.commit()

    return success_response(
        data={"id": hasil_id, "status_flag": body.status_flag},
        message="Status flag berhasil diperbarui",
    )


@router.get("/deteksi/export")
async def export_deteksi(
    admin: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(HasilDeteksi, User, Varietas, TingkatKematangan)
        .join(User, HasilDeteksi.user_id == User.id)
        .outerjoin(Varietas, HasilDeteksi.varietas_id == Varietas.id)
        .outerjoin(TingkatKematangan, HasilDeteksi.kematangan_id == TingkatKematangan.id)
        .order_by(desc(HasilDeteksi.created_at))
    )
    rows = result.all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "ID", "Pengguna", "Email", "Varietas", "Kematangan",
        "Confidence Varietas (%)", "Confidence Kematangan (%)",
        "Status Flag", "Tanggal",
    ])
    for hasil, user, varietas, kematangan in rows:
        writer.writerow([
            hasil.id, user.nama, user.email,
            varietas.nama_varietas if varietas else "-",
            kematangan.label_kematangan if kematangan else "-",
            float(hasil.confidence_varietas) if hasil.confidence_varietas else 0,
            float(hasil.confidence_kematangan) if hasil.confidence_kematangan else 0,
            hasil.status_flag,
            hasil.created_at.strftime("%Y-%m-%d %H:%M:%S") if hasil.created_at else "-",
        ])

    output.seek(0)
    today = datetime.now().strftime("%Y%m%d")
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=riwayat_{today}.csv"},
    )
