# Panduan Deploy Alpukat CNN — APK + Website Online

Panduan ini untuk repo: `https://github.com/R4hm4tHid4y4t/alpukat_project`

Alurnya: **Backend (Railway) → Database (Railway MySQL) → APK (GitHub Actions) → Web Admin (Firebase Hosting)**.
Ikuti berurutan — backend harus online dulu sebelum APK/Web di-build, karena URL-nya perlu di-inject saat build.

---

## 0. Terapkan file-file dari deployment kit ini ke repo Anda

File baru/berubah di paket ini:

```
.github/workflows/build-apk.yml       (baru)
.github/workflows/deploy-web.yml      (baru)
alpukat_api/Dockerfile                (baru)
alpukat_api/.dockerignore             (baru)
alpukat_api/requirements.txt          (diubah: tensorflow -> tensorflow-cpu)
alpukat_api/.gitignore                (diubah: model .tflite tidak di-ignore lagi)
alpukat_app/firebase.json             (baru)
alpukat_app/.firebaserc.example       (baru, copy jadi .firebaserc + isi project ID)
alpukat_app/lib/core/constants/app_constants.dart  (diubah: baseUrl bisa di-set saat build)
```

Extract/copy folder-folder di atas ke root repo lokal Anda (menimpa file lama yang namanya sama), lalu:

```bash
git add .
git commit -m "chore: setup deployment (Railway + GitHub Actions + Firebase Hosting)"
git push origin main
```

> ⚠️ **Jangan commit file `alpukat_cnn_db (2).sql`** ke GitHub — file itu berisi data user asli (email, hash password). Cukup dipakai untuk import manual ke database nanti (langkah 2.4). `.gitignore` backend sudah otomatis menolak semua `*.sql`.

---

## 1. Deploy Backend + Database ke Railway

### 1.1 Buat akun & project
1. Buka https://railway.app, daftar/login pakai akun **GitHub** Anda (memudahkan integrasi).
2. Klik **New Project** → **Deploy from GitHub repo** → pilih repo `alpukat_project`.
3. Railway akan mencoba auto-detect. Karena project ini monorepo (ada `alpukat_app` & `alpukat_api`), buka service yang baru dibuat → tab **Settings** → bagian **Source**:
   - **Root Directory**: isi `alpukat_api`
   - Railway akan otomatis mendeteksi `Dockerfile` di folder itu dan pakai itu untuk build (tidak perlu buildpack).

### 1.2 Tambah database MySQL
1. Di project yang sama, klik **New** → **Database** → **Add MySQL**.
2. Railway otomatis membuatkan service MySQL dengan variabel `MYSQLHOST`, `MYSQLPORT`, `MYSQLUSER`, `MYSQLPASSWORD`, `MYSQLDATABASE`.

### 1.3 Set Environment Variables di service backend
Buka service **backend** (bukan service MySQL) → tab **Variables** → tambahkan satu per satu:

| Key | Value |
|---|---|
| `APP_ENV` | `production` |
| `SECRET_KEY` | string acak panjang (generate: `openssl rand -hex 32`) |
| `JWT_SECRET_KEY` | string acak panjang lain (generate cara sama) |
| `DATABASE_URL` | `mysql+aiomysql://${{MySQL.MYSQLUSER}}:${{MySQL.MYSQLPASSWORD}}@${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}` |
| `BASE_URL` | isi setelah dapat domain publik di langkah 1.5 (sementara isi apa saja dulu) |
| `MAIL_SERVER` | `smtp.gmail.com` (rekomendasi, lihat catatan di bawah) |
| `MAIL_PORT` | `587` |
| `MAIL_USERNAME` | email Gmail Anda |
| `MAIL_PASSWORD` | App Password 16 digit Gmail (bukan password akun biasa) |
| `MAIL_FROM` | email Gmail yang sama |
| `MAIL_STARTTLS` | `True` |
| `MAIL_SSL_TLS` | `False` |

Catatan `DATABASE_URL`: sintaks `${{MySQL.MYSQLUSER}}` adalah fitur **variable reference** Railway — otomatis ambil nilai dari service MySQL yang barusan dibuat, ketik persis seperti itu (Railway akan kasih autocomplete saat Anda ketik `${{`).

Catatan email: fitur lupa password/OTP di app ini butuh SMTP asli supaya email sampai ke inbox (Mailtrap di `.env.example` cuma untuk testing lokal, tidak pernah sampai ke inbox asli). Aktifkan 2-Step Verification di akun Google, lalu buat App Password di `myaccount.google.com/apppasswords`.

### 1.4 Deploy
Klik **Deploy**. Railway akan build image Docker (±5–10 menit karena `tensorflow-cpu`). Pantau log di tab **Deployments**.

### 1.5 Ambil domain publik
1. Tab **Settings** → bagian **Networking** → klik **Generate Domain**.
2. Anda akan dapat domain seperti `https://alpukat-api-production.up.railway.app`.
3. Kembali ke tab **Variables**, update `BASE_URL` dengan domain ini, lalu redeploy.
4. Test: buka `https://domain-anda.up.railway.app/docs` di browser — harus muncul halaman Swagger UI.

### 1.6 Import database
Ambil kredensial MySQL dari service **MySQL** → tab **Variables** (`MYSQLHOST`, `MYSQLPORT`, `MYSQLUSER`, `MYSQLPASSWORD`, `MYSQLDATABASE`) — di Railway, service MySQL biasanya punya *public* connection URL juga di tab **Connect** (klik untuk lihat).

Import pakai `mysql` client dari komputer Anda:
```bash
mysql -h <MYSQLHOST> -P <MYSQLPORT> -u <MYSQLUSER> -p<MYSQLPASSWORD> <MYSQLDATABASE> < "alpukat_cnn_db (2).sql"
```
Atau pakai GUI client seperti **TablePlus**, **DBeaver**, atau **HeidiSQL** — buat koneksi baru dengan kredensial di atas, lalu jalankan/import file `.sql`-nya.

> Model TFLite (`models_tflite/*.tflite`) sudah otomatis ikut ter-deploy karena sudah ikut di-commit ke git (lihat langkah 0). Tidak perlu upload manual.

### 1.7 (Opsional tapi disarankan) Volume untuk foto upload
Tanpa ini, foto hasil deteksi yang di-upload user akan **hilang** setiap kali Railway redeploy container (filesystem-nya ephemeral). Untuk mencegah ini:
1. Tab **Settings** service backend → **Volumes** → **New Volume**.
2. Mount path: `/app/storage`
3. Redeploy.

---

## 2. Build APK lewat GitHub Actions (tanpa install Flutter sama sekali)

1. Di GitHub repo Anda → **Settings** → **Secrets and variables** → **Actions** → tab **Variables** → **New repository variable**.
   - Name: `API_BASE_URL`
   - Value: domain Railway dari langkah 1.5, contoh `https://alpukat-api-production.up.railway.app`
2. Buka tab **Actions** di repo → pilih workflow **Build APK** di sidebar kiri → klik **Run workflow** → **Run workflow** (branch `main`).
3. Tunggu ±5–10 menit. Setelah selesai (centang hijau), klik run tersebut → scroll ke bagian **Artifacts** → download **alpukat-app-release-apk** (berupa file `.zip` berisi `app-release.apk`).
4. Extract, lalu pindahkan `app-release.apk` ke HP Android (via kabel USB, Google Drive, dll) dan install (aktifkan "Install dari sumber tidak dikenal" jika diminta).

APK ini **debug-signed** (bukan untuk Play Store, tapi cukup untuk demo/sidang skripsi — bisa diinstall & dijalankan normal di HP manapun).

Setiap kali Anda push perubahan ke `alpukat_app/**` di branch `main`, APK baru otomatis ter-build lagi — tinggal ulangi langkah 3 untuk download versi terbaru.

---

## 3. Deploy Website Admin ke Firebase Hosting

1. Buka https://console.firebase.google.com → **Add project** → beri nama (misal `alpukat-cnn`) → ikuti wizard (boleh matikan Google Analytics, tidak perlu).
2. Di dalam project → sidebar **Build** → **Hosting** → klik **Get started** (cukup sampai langkah "Register app", tidak perlu jalankan command apapun di sini, GitHub Actions yang akan handle).
3. Ambil **Project ID**: ada di **Project Settings** (ikon gerigi) → **General**, field "Project ID" (bukan "Project name").
4. Di repo lokal: copy `alpukat_app/.firebaserc.example` → `alpukat_app/.firebaserc`, lalu isi `projectId` dengan Project ID tadi:
   ```json
   { "projects": { "default": "project-id-anda" } }
   ```
5. Generate Service Account key: **Project Settings** → tab **Service accounts** → **Generate new private key** → simpan file JSON yang terdownload.
6. Di GitHub repo → **Settings** → **Secrets and variables** → **Actions** → tab **Secrets** → **New repository secret**:
   - Name: `FIREBASE_SERVICE_ACCOUNT`
   - Value: **paste seluruh isi** file JSON tadi.
7. Commit & push `.firebaserc`:
   ```bash
   git add alpukat_app/.firebaserc
   git commit -m "chore: setup firebase hosting project id"
   git push origin main
   ```
8. Push ini otomatis memicu workflow **Deploy Web (Admin) ke Firebase Hosting** (pastikan variable `API_BASE_URL` di langkah 2.1 sudah diset — dipakai juga di sini). Pantau di tab **Actions**.
9. Setelah sukses, website live di: `https://project-id-anda.web.app`

Login sebagai admin di website itu menggunakan akun admin yang sudah ada di database hasil import (langkah 1.6).

---

## 4. Checklist Testing Akhir

- [ ] `https://domain-railway-anda.up.railway.app/docs` bisa dibuka, menampilkan Swagger UI
- [ ] Login admin berhasil di `https://project-id-anda.web.app`
- [ ] APK ter-install di HP, halaman splash/onboarding muncul normal
- [ ] Register/login user baru di APK berhasil (cek email OTP masuk)
- [ ] Upload foto alpukat di APK → hasil klasifikasi varietas & kematangan muncul
- [ ] Riwayat deteksi tersimpan dan muncul di halaman riwayat (APK) & admin (web)

## Catatan Biaya
- **GitHub Actions**: gratis (2.000 menit/bulan untuk repo private, tak terbatas untuk repo public).
- **Firebase Hosting**: gratis (plan Spark, cukup untuk skala capstone project).
- **Railway**: **tidak lagi punya tier selamanya-gratis** — pakai model trial credit lalu usage-based (kisaran mulai ~$5/bulan untuk beban sekecil ini). Cocok untuk kebutuhan sidang/demo. Jika ingin alternatif 100% gratis untuk backend, opsinya adalah Render (free web service, tapi "tidur" setelah ~15 menit idle sehingga request pertama lambat) dikombinasikan dengan MySQL gratis dari db4free.net (kapasitas kecil) — kualitasnya jauh di bawah Railway untuk demo langsung, jadi tidak direkomendasikan sebagai default.
