import uvicorn
from app.config import get_settings

settings = get_settings()

if __name__ == "__main__":
    print(f"🚀 Memulai Alpukat CNN API di http://0.0.0.0:{settings.app_port}")
    print(f"⚠️ Pastikan Firewall mengizinkan akses ke port {settings.app_port}")
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=settings.app_port,
        reload=False,
        log_level="info",
    )