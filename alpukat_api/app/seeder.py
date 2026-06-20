"""
Seeder async untuk data awal database.
Jalankan dengan: python -m app.seeder
"""
import asyncio
from sqlalchemy import select
from app.database import AsyncSessionLocal, engine, Base
from app.models.user import User, ProfilPengguna
from app.models.master import Varietas, TingkatKematangan, ModelCnn
from app.utils.security import hash_password


async def seed():
    # Buat semua tabel jika belum ada
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        # ── Admin Default ──────────────────────────────────
        result = await db.execute(select(User).where(User.email == "admin@alpukat.id"))
        admin = result.scalar_one_or_none()

        if not admin:
            admin = User(
                nama="Admin Sistem",
                email="admin@alpukat.id",
                password=hash_password("Admin@123"),
                role="admin",
                status_verifikasi=1,
            )
            db.add(admin)
            await db.flush()

            profil = ProfilPengguna(user_id=admin.id, bio="Administrator sistem Alpukat CNN")
            db.add(profil)
            print("✅ Admin default dibuat: admin@alpukat.id / Admin@123")
        else:
            print("ℹ️  Admin sudah ada, dilewati")

        # ── Varietas ───────────────────────────────────────
        varietas_data = [
            {
                "nama_varietas": "Aligator",
                "deskripsi": (
                    "Alpukat Aligator memiliki kulit kasar dan bertekstur menyerupai kulit buaya. "
                    "Buah berukuran besar dengan daging tebal berwarna kuning kehijauan."
                ),
            },
            {
                "nama_varietas": "Miki",
                "deskripsi": (
                    "Alpukat Miki merupakan varietas lokal Indonesia dengan kulit halus dan mengkilap. "
                    "Ukuran buah sedang dengan rasa yang gurih dan creamy."
                ),
            },
        ]
        for data in varietas_data:
            result = await db.execute(
                select(Varietas).where(Varietas.nama_varietas == data["nama_varietas"])
            )
            if not result.scalar_one_or_none():
                db.add(Varietas(**data))
                print(f"✅ Varietas '{data['nama_varietas']}' ditambahkan")
            else:
                print(f"ℹ️  Varietas '{data['nama_varietas']}' sudah ada, dilewati")

        # ── Tingkat Kematangan (4 kelas) ───────────────────
        kematangan_data = [
            {
                "label_kematangan": "Mentah",
                "deskripsi": "Buah alpukat dalam kondisi mentah, belum siap dikonsumsi.",
                "ciri_visual": "Kulit berwarna hijau cerah dan keras saat ditekan.",
            },
            {
                "label_kematangan": "Setengah Matang",
                "deskripsi": "Buah alpukat setengah matang, perlu ditunggu 1-3 hari lagi.",
                "ciri_visual": "Kulit mulai melunak, warna hijau kecoklatan.",
            },
            {
                "label_kematangan": "Matang",
                "deskripsi": "Buah alpukat matang sempurna dan siap dikonsumsi.",
                "ciri_visual": "Kulit lunak merata, warna gelap kehitaman, daging kuning keemasan.",
            },
            {
                "label_kematangan": "Terlalu Matang",
                "deskripsi": "Buah terlalu matang. Segera konsumsi atau olah menjadi jus.",
                "ciri_visual": "Kulit sangat lunak, warna hampir hitam, mungkin ada bercak.",
            },
        ]
        for data in kematangan_data:
            result = await db.execute(
                select(TingkatKematangan).where(
                    TingkatKematangan.label_kematangan == data["label_kematangan"]
                )
            )
            if not result.scalar_one_or_none():
                db.add(TingkatKematangan(**data))
                print(f"✅ Kematangan '{data['label_kematangan']}' ditambahkan")
            else:
                print(f"ℹ️  Kematangan '{data['label_kematangan']}' sudah ada, dilewati")

        # ── Model CNN ──────────────────────────────────────
        await db.flush()
        result = await db.execute(select(User).where(User.email == "admin@alpukat.id"))
        admin_user = result.scalar_one_or_none()

        model_data = [
            {
                "versi": "v1.0-varietas",
                "akurasi": 100.00,
                "format_file": "tflite",
                "deskripsi": "MobileNetV2 varietas alpukat. Akurasi test 100% (32 sampel). 27 April 2026.",
                "status_aktif": 1,
                "uploaded_by": admin_user.id if admin_user else None,
            },
            {
                "versi": "v1.0-kematangan",
                "akurasi": 84.38,
                "format_file": "tflite",
                "deskripsi": "MobileNetV2 kematangan alpukat (4 kelas). Akurasi test 84.38% (27/32). 27 April 2026.",
                "status_aktif": 1,
                "uploaded_by": admin_user.id if admin_user else None,
            },
        ]
        for data in model_data:
            result = await db.execute(
                select(ModelCnn).where(ModelCnn.versi == data["versi"])
            )
            if not result.scalar_one_or_none():
                db.add(ModelCnn(**data))
                print(f"✅ Model CNN '{data['versi']}' ditambahkan")
            else:
                print(f"ℹ️  Model CNN '{data['versi']}' sudah ada, dilewati")

        await db.commit()
        print("\n🎉 Seeder selesai!")


if __name__ == "__main__":
    asyncio.run(seed())
