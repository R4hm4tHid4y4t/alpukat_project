from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime, timezone
from app.database import get_db
from app.models.user import User
from app.models.master import Varietas, TingkatKematangan, ModelCnn
from app.models.deteksi import HasilDeteksi, RiwayatDeteksi
from app.dependencies.auth import get_current_user
from app.services.tflite_service import TFLiteInferenceService
from app.services import image_service
from app.utils.response import success_response
from app.config import get_settings

router = APIRouter()
settings = get_settings()

# Rekomendasi konsumsi per tingkat kematangan
REKOMENDASI = {
    "Mentah": "Tunggu 5–7 hari sebelum dikonsumsi.",
    "Setengah Matang": "Akan siap dikonsumsi dalam 2–3 hari.",
    "Matang": "Siap dikonsumsi! Segera nikmati.",
    "Terlalu Matang": "Segera konsumsi atau olah menjadi jus/guacamole.",
}


# ── UC-06, UC-07, UC-08, UC-09: DETEKSI ALPUKAT ──────────
@router.post("/deteksi")
async def deteksi_alpukat(
    gambar: UploadFile = File(..., description="Foto buah alpukat (JPG/PNG, max 5MB)"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # 1. Validasi & baca gambar
    try:
        image_bytes = await image_service.validate_image(gambar)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Gambar tidak valid: {str(e)}")

    # 2. Inferensi model varietas
    try:
        var_result = await TFLiteInferenceService.predict_varietas(image_bytes)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Gagal menganalisis varietas. Silakan coba lagi.")

    # 3. Inferensi model kematangan
    try:
        kem_result = await TFLiteInferenceService.predict_kematangan(image_bytes)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Gagal menganalisis kematangan. Silakan coba lagi.")

    # 4. Cari varietas_id dari database
    result = await db.execute(
        select(Varietas).where(
            func.lower(Varietas.nama_varietas) == var_result["class_name"].lower()
        )
    )
    varietas = result.scalar_one_or_none()

    # 5. Cari kematangan_id dari database
    result = await db.execute(
        select(TingkatKematangan).where(
            func.lower(TingkatKematangan.label_kematangan) == kem_result["display_name"].lower()
        )
    )
    kematangan = result.scalar_one_or_none()

    # 6. Ambil model CNN aktif
    result = await db.execute(
        select(ModelCnn).where(ModelCnn.status_aktif == 1).limit(1)
    )
    model_aktif = result.scalar_one_or_none()

    # 7. Tentukan status flag berdasarkan threshold 80%
    confidence_var = var_result["confidence"]
    confidence_kem = kem_result["confidence"]
    status_flag = (
        "perlu_ditinjau"
        if confidence_var < (settings.confidence_threshold * 100)
        or confidence_kem < (settings.confidence_threshold * 100)
        else "normal"
    )

    # 8. Simpan gambar ke storage
    try:
        gambar_path = await image_service.save_image(image_bytes, current_user.id)
    except Exception as e:
        raise HTTPException(status_code=500, detail="Gagal menyimpan gambar.")

    # 9. Simpan hasil deteksi ke database
    hasil = HasilDeteksi(
        user_id=current_user.id,
        model_id=model_aktif.id if model_aktif else None,
        varietas_id=varietas.id if varietas else None,
        kematangan_id=kematangan.id if kematangan else None,
        gambar_input=gambar_path,
        confidence_varietas=round(confidence_var, 2),
        confidence_kematangan=round(confidence_kem, 2),
        status_flag=status_flag,
    )
    db.add(hasil)
    await db.flush()

    # 10. Simpan ke riwayat deteksi
    riwayat = RiwayatDeteksi(
        user_id=current_user.id,
        hasil_id=hasil.id,
        aksi="deteksi",
    )
    db.add(riwayat)
    await db.commit()

    # 11. Susun response lengkap
    inference_total = (
        var_result["inference_time_ms"] + kem_result["inference_time_ms"]
    )

    return success_response(
        data={
            "id": hasil.id,
            "varietas": {
                "id": varietas.id if varietas else None,
                "nama": var_result["class_name"],
                "deskripsi": varietas.deskripsi if varietas else None,
            },
            "kematangan": {
                "id": kematangan.id if kematangan else None,
                "label": kem_result["display_name"],
                "deskripsi": kematangan.deskripsi if kematangan else None,
                "ciri_visual": kematangan.ciri_visual if kematangan else None,
                "rekomendasi": REKOMENDASI.get(kem_result["display_name"], ""),
            },
            "confidence_varietas": round(confidence_var, 2),
            "confidence_kematangan": round(confidence_kem, 2),
            "all_probs_varietas": var_result["all_probabilities"],
            "all_probs_kematangan": kem_result["all_probabilities"],
            "status_flag": status_flag,
            "gambar_url": image_service.get_image_url(gambar_path),
            "model_versi": model_aktif.versi if model_aktif else None,
            "inference_time_ms": round(inference_total, 2),
            "created_at": hasil.created_at.isoformat() if hasil.created_at else None,
        },
        message="Deteksi berhasil",
    )
