# ============================================================
# dev.ps1
# Menjalankan sekaligus: Backend FastAPI + Flutter Mobile (HP) + Flutter Web (Chrome)
# Setiap proses dibuka di window PowerShell terpisah supaya tidak saling mematikan.
#
# Cara pakai:
#   cd D:\alpukat_project
#   .\dev.ps1
#
# Kalau muncul error "execution policy", jalankan dulu:
#   powershell -ExecutionPolicy Bypass -File .\dev.ps1
# ============================================================

# --- KONFIGURASI: sesuaikan kalau perlu ---
$apiPath   = "D:\alpukat_project\alpukat_api"
$appPath   = "D:\alpukat_project\alpukat_app"
$deviceId  = "9HRGEUOJW4RKTCUO"   # cek device ID terbaru lewat: flutter devices

# --- 1. Jalankan Backend FastAPI ---
Write-Host "=== 1. Menjalankan backend FastAPI ===" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", `
    "cd '$apiPath'; .venv\Scripts\activate; python run.py"

# --- 2. Tunggu backend siap sebelum lanjut ---
Write-Host "=== 2. Menunggu backend siap (5 detik) ===" -ForegroundColor Cyan
Start-Sleep -Seconds 5

# --- 3. Pasang adb reverse (port forwarding USB) ---
Write-Host "=== 3. Setup adb reverse tcp:8000 ===" -ForegroundColor Cyan
adb reverse tcp:8000 tcp:8000

if ($LASTEXITCODE -ne 0) {
    Write-Host "  -> adb reverse gagal. Pastikan HP terkonek USB dan sudah 'Allow USB debugging'." -ForegroundColor Yellow
    Write-Host "  -> Cek dengan: adb devices" -ForegroundColor Yellow
}

# --- 4. Jalankan Flutter Mobile (HP) ---
Write-Host "=== 4. Menjalankan Flutter Mobile (HP: $deviceId) ===" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", `
    "cd '$appPath'; flutter run -d $deviceId"

# --- 5. Jalankan Flutter Web (Chrome) ---
Write-Host "=== 5. Menjalankan Flutter Web (Chrome) ===" -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", `
    "cd '$appPath'; flutter run -d chrome"

Write-Host ""
Write-Host "Semua proses sudah dijalankan di window terpisah." -ForegroundColor Green
Write-Host "Kalau HP sempat dicabut/colok ulang, jalankan manual: adb reverse tcp:8000 tcp:8000" -ForegroundColor Yellow