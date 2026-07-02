# Dockerfile untuk backend Alpukat CNN API (FastAPI)
# Dipakai oleh Railway (atau platform Docker lain) untuk build & deploy.

FROM python:3.11-slim

WORKDIR /app

# Dependency sistem minimal (Pillow butuh ini untuk beberapa operasi image).
# Jika nanti ada error saat `pip install` terkait kompilasi native,
# tambahkan: build-essential
RUN apt-get update && apt-get install -y --no-install-recommends \
    libjpeg62-turbo \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY . .

# Folder ini WAJIB ada isinya sebelum deploy:
#   models_tflite/model_varietas.tflite
#   models_tflite/model_kematangan.tflite
# (Lihat DEPLOYMENT_GUIDE.md — file .gitignore sudah diubah supaya
# folder ini ikut ter-commit ke git, karena model wajib ada di server.)
RUN mkdir -p storage/uploads storage/avatars

# Railway (dan kebanyakan platform Docker) menyuntikkan PORT lewat env var.
# Fallback ke 8000 untuk testing container secara lokal.
ENV PORT=8000
EXPOSE 8000

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
