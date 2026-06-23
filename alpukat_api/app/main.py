from contextlib import asynccontextmanager
import logging
from fastapi import FastAPI, Request, status, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
import os

from app.config import get_settings

settings = get_settings()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)

limiter = Limiter(key_func=get_remote_address)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── STARTUP ──
    print(f"🚀 Memulai {settings.app_name}...")

    # Load model TFLite ke memory
    try:
        from app.services.tflite_service import TFLiteInferenceService
        TFLiteInferenceService.initialize(settings)
        print("✅ Model TFLite berhasil dimuat")
    except FileNotFoundError as e:
        print(f"⚠️  Peringatan: {e} — letakkan file .tflite ke folder models_tflite/")
    except Exception as e:
        print(f"⚠️  Gagal memuat model: {e}")

    # Buat folder storage jika belum ada
    os.makedirs(settings.storage_path, exist_ok=True)
    os.makedirs("storage/avatars", exist_ok=True)

    yield

    # ── SHUTDOWN ──
    print("🛑 Menutup aplikasi...")


app = FastAPI(
    title=settings.app_name,
    description="REST API untuk klasifikasi varietas dan deteksi kematangan buah alpukat",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# ── Rate Limiter ──
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── CORS ──
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Static Files (gambar hasil deteksi) ──
os.makedirs("storage/uploads", exist_ok=True)
app.mount("/storage", StaticFiles(directory="storage/uploads"), name="storage")


# ── Global Exception Handlers ──
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = {}
    for error in exc.errors():
        field = ".".join(str(loc) for loc in error["loc"] if loc != "body")
        errors[field] = error["msg"]
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "success": False,
            "message": "Data yang dikirim tidak valid",
            "data": None,
            "errors": errors,
        },
    )


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    # Samakan format dengan success_response/error_response di utils/response.py
    # supaya Flutter (DioClient.extractErrorMessage -> data['message']) bisa
    # membaca pesan error custom dari HTTPException(detail=...) di seluruh app.
    message = exc.detail if isinstance(exc.detail, str) else "Terjadi kesalahan"
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "message": message,
            "data": None,
            "errors": None if isinstance(exc.detail, str) else exc.detail,
        },
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "message": "Terjadi kesalahan pada server. Silakan coba lagi.",
            "data": None,
            "errors": str(exc) if settings.app_env == "development" else None,
        },
    )


# ── Health Check ──
@app.get("/", tags=["Health"])
async def health_check():
    return {
        "success": True,
        "message": "Server berjalan",
        "data": {
            "app": settings.app_name,
            "version": "1.0.0",
            "status": "ok",
            "env": settings.app_env,
        },
        "errors": None,
    }


# ── Include Routers ──
from app.routers import auth, user, deteksi, riwayat, admin  # noqa: E402

app.include_router(auth.router,    prefix="/api/auth",   tags=["Authentication"])
app.include_router(user.router,    prefix="/api/user",   tags=["User"])
app.include_router(deteksi.router, prefix="/api",        tags=["Deteksi"])
app.include_router(riwayat.router, prefix="/api",        tags=["Riwayat"])
app.include_router(admin.router,   prefix="/api/admin",  tags=["Admin"])