from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # App
    app_name: str = "Alpukat CNN API"
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    secret_key: str

    # Database
    database_url: str

    # JWT
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 60
    jwt_refresh_token_expire_days: int = 7

    # OTP
    otp_length: int = 6
    otp_expire_minutes: int = 10

    # Email
    mail_username: str
    mail_password: str
    mail_from: str
    mail_port: int = 587
    mail_server: str
    mail_starttls: bool = True
    mail_ssl_tls: bool = False

    # Model TFLite
    model_varietas_path: str = "models_tflite/model_varietas.tflite"
    model_kematangan_path: str = "models_tflite/model_kematangan.tflite"

    # Storage
    storage_path: str = "storage/uploads"
    base_url: str = "http://localhost:8000"
    max_image_size_mb: int = 5

    # Confidence
    confidence_threshold: float = 0.80
    # Ambang batas reject (di bawah ini, dianggap BUKAN alpukat sama sekali).
    # Dipakai terhadap RATA-RATA confidence varietas + kematangan (lihat
    # routers/deteksi.py). Sengaja dibuat konservatif (rendah) — hasil
    # pengujian menunjukkan foto alpukat asli yang kondisinya kurang ideal
    # (beda pencahayaan/background dari data training) bisa saja cuma
    # mendapat confidence ~60%, jadi threshold terlalu tinggi berisiko
    # menolak foto alpukat yang sah. Heuristik ini TIDAK sempurna untuk
    # menyaring semua objek bukan-alpukat — solusi paling robust tetap
    # retrain model dengan kelas negatif "bukan_alpukat".
    reject_threshold_varietas: float = 0.50

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()