# Alpukat CNN API

Backend REST API untuk klasifikasi varietas dan deteksi kematangan buah alpukat.

## Stack
- **FastAPI** (Python async)
- **SQLAlchemy 2.x** async + **aiomysql**
- **Alembic** (migration)
- **Pydantic v2**
- **TFLite Runtime** (inferensi model CNN di server)

## Setup

```bash
# 1. Buat virtual environment
python -m venv .venv

# Windows
.venv\Scripts\activate
# Linux/Mac
source .venv/bin/activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Salin dan isi file .env
cp .env.example .env
# Edit .env sesuai konfigurasi lokal Anda

# 4. Buat database MySQL
# CREATE DATABASE alpukat_cnn_db CHARACTER SET utf8mb4;

# 5. Jalankan migration
alembic upgrade head

# 6. Jalankan seeder (opsional)
python -m app.seeder

# 7. Letakkan file model TFLite
# models_tflite/model_varietas.tflite
# models_tflite/model_kematangan.tflite

# 8. Jalankan server
python run.py
```

## Akses API
- Swagger UI : http://localhost:8000/docs
- ReDoc      : http://localhost:8000/redoc
- Health     : http://localhost:8000/
