# ⚽ Football Community App

Backend & orkestrasi untuk aplikasi komunitas sepak bola berbasis **microservice architecture**. Setiap fitur besar dipisah menjadi service mandiri (polyrepo) yang berkomunikasi melalui sebuah **API Gateway** terpusat.

> 📌 **Repo ini adalah pusat/orkestrasi dari seluruh proyek.** Cukup buka repo ini untuk menemukan link ke semua repositori lain (frontend, tiap service, dan testing) — lihat tabel di bawah.

---

## 🔗 Repository Index

| No | Repositori | Peran | Link |
|---|---|---|---|
| 1 | **football-community-project** | Repo utama — orkestrasi Docker Compose, dokumentasi arsitektur & integration test | *(kamu di sini)* |
| 2 | kickoff | Frontend Mobile (React Native + Expo) | https://github.com/Bintangr191/kickoff |
| 3 | api-gateway | API Gateway — entry point & traffic router | https://github.com/Bintangr191/api-gateway |
| 4 | auth-service | Autentikasi, profil, biometric | https://github.com/Bintangr191/auth-service |
| 5 | football-service | Data liga, tim, jadwal, favorit | https://github.com/Bintangr191/football-service |
| 6 | forum-service | Post, komentar, voting | https://github.com/Bintangr191/forum-service |
| 7 | report-service | Laporan post/komentar/pengguna | https://github.com/Bintangr191/report-service |
| 8 | notification-service | Email OTP via RabbitMQ | https://github.com/Bintangr191/notification-service |
| 9 | football-community-testsappium | Automated testing mobile app (Appium) | https://github.com/Bintangr191/football-community-testsappium |

---

## 📑 Daftar Isi

- [Arsitektur Sistem](#-arsitektur-sistem)
- [Struktur Direktori (Polyrepo)](#️-struktur-direktori-polyrepo)
- [Deskripsi Service](#-deskripsi-service)
  - [Auth Service](#-auth-service-3001)
  - [Football Service](#-football-service-3002)
  - [Forum Service](#-forum-service-3003)
  - [Notification Service](#-notification-service-3004)
  - [Report Service](#-report-service-3005)
  - [API Gateway](#-api-gateway-3000)
- [Cara Menjalankan (Docker)](#-cara-menjalankan-docker--direkomendasikan)
- [Konfigurasi Environment](#️-konfigurasi-environment)
- [Port & Service Map](#-port--service-map)
- [Menjalankan Tests](#-menjalankan-tests)
- [Development Tanpa Docker](#-development-tanpa-docker--mode-manual)
- [Keamanan](#️-keamanan)
- [Contoh Alur Request](#-contoh-alur-request)
- [Tech Stack](#️-tech-stack)
- [Contributing](#-contributing)
- [License](#-license)

---

## 📐 Arsitektur Sistem

```
                        ┌───────────────────────────────┐
                        │       CLIENT (Mobile/Web)      │
                        └───────────────┬─────────────────┘
                                        │ HTTP Request
                                        ▼
                        ┌───────────────────────────────┐
                        │          API Gateway           │
                        │       (Hono · Port 3000)       │
                        │                                 │
                        │  • JWT Auth Middleware          │
                        │  • Rate Limiting (100/min)      │
                        │  • CORS Handling                │
                        │  • Reverse Proxy                │
                        └───┬──────────┬──────────┬───────┬──┘
                            │          │          │       │
              ┌─────────────┘          │          │       └───────────────┐
              │                        │          │                       │
              ▼                        ▼          ▼                       ▼
  ┌──────────────────┐   ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
  │   Auth Service    │   │ Football Service │  │  Forum Service    │  │  Report Service   │
  │   Port :3001      │   │  Port :3002      │  │  Port :3003       │  │  Port :3005       │
  │   DB: MySQL       │   │  DB: MongoDB     │  │  DB: MongoDB      │  │  DB: MongoDB      │
  │   + RabbitMQ       │   │  + External API │  │  + RabbitMQ       │  │                    │
  └─────────┬──────────┘   └──────────────────┘  └─────────┬─────────┘  └────────────────────┘
            │                                                │
            │ publish → otp_send                publish msgs │
            └──────────────────────┬────────────────────────┘
                                   ▼
                   ┌───────────────────────────────┐
                   │      Notification Service      │
                   │       Port :3004                │
                   │     (RabbitMQ Consumer)         │
                   │   Kirim email OTP via SMTP      │
                   └───────────────────────────────┘

  Infrastructure:
  ┌──────────────────────────────────────────────────────────┐
  │   MySQL :3306  |  MongoDB :27017  |  RabbitMQ :5672       │
  └──────────────────────────────────────────────────────────┘
```

---

## 🗂️ Struktur Direktori (Polyrepo)

Proyek ini menggunakan pendekatan **Polyrepo**, di mana setiap service berada di repositori terpisah. Repositori utama ini hanya berisi file orkestrasi (`docker-compose.yml`) dan integration test.

Struktur folder yang diharapkan saat di-clone di komputer Anda:

```text
parent-folder/
├── football-community-project/ ← Repositori UTAMA ini (docker-compose & tests)
├── kickoff/                    ← Repositori Frontend Mobile (Expo)
├── api-gateway/                ← Repositori API Gateway
├── auth-service/               ← Repositori Auth Service
├── football-service/           ← Repositori Football Service
├── forum-service/              ← Repositori Forum Service
├── report-service/             ← Repositori Report Service
├── notification-service/       ← Repositori Notification Service
└── football-community-testsappium/  ← Repositori Automated Testing (Appium)
```

> Semua file `.env` service berada langsung di root masing-masing repo (`auth-service/.env`, bukan `auth-service/services/.env`).

---

## 🧩 Deskripsi Service

### 🔐 Auth Service (`:3001`)

Repo: [auth-service](https://github.com/Bintangr191/auth-service)

Mengelola seluruh siklus autentikasi pengguna.

- **Database:** MySQL (via Prisma)
- **Message Broker:** RabbitMQ (publisher — queue `otp_send`)
- **File Storage:** Cloudinary (upload avatar)

| Fitur | Keterangan |
|---|---|
| Register | Daftar akun baru, kirim OTP verifikasi ke email |
| Login | Login email + password, kembalikan access & refresh token |
| OTP Verification | Verifikasi kode OTP 6 digit dari email |
| Resend OTP | Kirim ulang OTP jika belum diterima |
| Refresh Token | Perbarui access token menggunakan refresh token |
| Logout | Invalidasi refresh token |
| Delete Account | Hapus akun secara permanen |
| Get/Update Profile | Lihat & edit profil (nama, bio, avatar, favoriteTeam, dll.) |
| Biometric Login | Aktifkan, gunakan, dan nonaktifkan login biometrik per device |
| Upload Avatar | Dapatkan signed URL Cloudinary untuk upload foto profil |

**Database Schema (MySQL):**

| Model | Keterangan |
|---|---|
| `User` | Data akun, profil, role (USER / ADMIN), status verifikasi |
| `RefreshToken` | Refresh token (disimpan dalam bentuk hash) |
| `OtpVerification` | Kode OTP beserta expiry & jumlah percobaan |
| `BiometricCredential` | Token biometrik per perangkat |

---

### ⚽ Football Service (`:3002`)

Repo: [football-service](https://github.com/Bintangr191/football-service)

Menyediakan data sepak bola dari API eksternal dan menyimpan preferensi pengguna.

- **Database:** MongoDB (via Prisma)
- **External API:** [football-data.org](https://www.football-data.org/) & [thesportsdb.com](https://www.thesportsdb.com/)

| Endpoint | Method | Keterangan |
|---|---|---|
| `/football/leagues` | GET | Daftar semua liga |
| `/football/standings/:code` | GET | Klasemen liga (contoh: `PL`, `PD`, `SA`) |
| `/football/schedule` | GET | Jadwal pertandingan mendatang |
| `/football/matches/:code` | GET | Daftar pertandingan per liga |
| `/football/match/:id` | GET | Detail satu pertandingan |
| `/football/team/:id` | GET | Detail tim |
| `/football/search` | GET | Cari tim berdasarkan nama |
| `/football/scorers/:code` | GET | Top scorer liga |
| `/football/player/:id` | GET | Detail pemain |
| `/football/favorite` | POST | Simpan tim favorit |
| `/football/favorite` | GET | Daftar tim favorit pengguna |
| `/football/favorite/:id` | DELETE | Hapus tim favorit |
| `/football/recent-viewed` | POST | Catat tim yang baru dilihat |
| `/football/recent-viewed` | GET | Riwayat tim yang baru dilihat |

---

### 💬 Forum Service (`:3003`)

Repo: [forum-service](https://github.com/Bintangr191/forum-service)

Mengelola komunitas diskusi dengan fitur post, komentar, voting, dan penjadwalan post.

- **Database:** MongoDB (via Prisma — Replica Set wajib)
- **Message Broker:** RabbitMQ (consumer & publisher)

| Endpoint | Method | Keterangan |
|---|---|---|
| `/forum/posts` | POST | Buat post (DRAFT / SCHEDULED / PUBLISHED) |
| `/forum/posts` | GET | Feed semua post yang sudah dipublikasi |
| `/forum/posts/search` | GET | Cari post berdasarkan kata kunci |
| `/forum/posts/me` | GET | Post milik pengguna yang sedang login |
| `/forum/posts/:id` | GET | Detail satu post |
| `/forum/posts/:id` | PUT | Edit post |
| `/forum/posts/:id` | DELETE | Hapus post |
| `/forum/comments` | POST | Tambah komentar ke post |
| `/forum/posts/:postId/comments` | GET | Ambil semua komentar di sebuah post |
| `/forum/comments/:id` | PUT | Edit komentar |
| `/forum/comments/:id` | DELETE | Hapus komentar |
| `/forum/posts/vote` | POST | Upvote / downvote post |
| `/forum/comments/vote` | POST | Upvote / downvote komentar |

**Fitur Lanjutan:**
- **Scheduled Post** — Post bisa dijadwalkan untuk dipublikasi di waktu tertentu, diproses oleh background scheduler
- **RabbitMQ Worker** — Memproses post yang masuk queue untuk diterbitkan secara async
- **Internal Sync Endpoint** — `PATCH /internal/users/avatar` untuk sinkronisasi avatar dari auth-service (diakses antar service, bukan oleh klien)

---

### 📨 Notification Service (`:3004`)

Repo: [notification-service](https://github.com/Bintangr191/notification-service)

Mengirim notifikasi email (OTP) melalui antrian RabbitMQ. Service ini **tidak dipanggil langsung oleh klien** — ia mendengarkan pesan dari queue RabbitMQ yang dikirim oleh auth-service, kemudian mengirimkan email lewat Gmail SMTP.

- **Transport:** Nodemailer (SMTP Gmail)
- **Message Broker:** RabbitMQ (consumer — queue `otp_send`)

---

### 📊 Report Service (`:3005`)

Repo: [report-service](https://github.com/Bintangr191/report-service)

Mengelola laporan terkait postingan, komentar, atau pengguna dalam komunitas.

- **Database:** MongoDB (via Prisma)

| Endpoint | Method | Keterangan |
|---|---|---|
| `/reports` | POST | Buat laporan baru |
| `/reports` | GET | Ambil daftar laporan (feed) |
| `/reports/me` | GET | Laporan milik pengguna yang sedang login |
| `/reports/:id` | GET | Detail laporan |
| `/reports/:id` | PUT | Edit laporan |
| `/reports/:id` | DELETE | Hapus laporan |
| `/reports/:id/status` | PATCH | Update status laporan (contoh: resolved) |
| `/reports/:id/vote` | POST | Upvote / downvote laporan |
| `/reports/:id/comments` | POST | Tambah komentar ke laporan |
| `/reports/:id/comments` | GET | Ambil semua komentar di sebuah laporan |
| `/reports/comments/:commentId` | DELETE | Hapus komentar |

**Fitur Lanjutan:**
- **Internal Sync Endpoint** — `PATCH /internal/users/avatar` untuk sinkronisasi avatar dari auth-service.

---

### 🚦 API Gateway (`:3000`)

Repo: [api-gateway](https://github.com/Bintangr191/api-gateway)

Satu-satunya entry point bagi klien. Bertanggung jawab atas:

| Fitur | Keterangan |
|---|---|
| **JWT Verification** | Verifikasi Bearer token di semua route terproteksi |
| **Rate Limiting** | Maks 100 request/menit per IP |
| **CORS** | Mengizinkan request lintas origin |
| **Reverse Proxy** | Meneruskan request ke service yang tepat |
| **Header Injection** | Menyisipkan `x-user-id`, `x-user-role`, `x-user-email`, `x-internal-secret` ke setiap request internal |

**Peta Route:**

| Route Gateway | Diteruskan ke | Butuh JWT? |
|---|---|---|
| `/auth/*` | Auth Service `:3001` | ❌ Tidak |
| `/upload/*` | Auth Service `:3001` | ❌ Tidak |
| `/football/*` | Football Service `:3002` | ✅ Ya |
| `/forum/*` | Forum Service `:3003` | ✅ Ya |
| `/report/*` | Report Service `:3005` | ✅ Ya |

> ⚠️ Semua route yang butuh JWT wajib menyertakan header `Authorization: Bearer <token>`.

---

## 🚀 Cara Menjalankan (Docker — Direkomendasikan)

### Prasyarat
- **Windows / Mac:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) terinstal dan berjalan
- **Linux:** Docker Engine + Docker Compose plugin (Docker Desktop opsional, tidak wajib)

<details>
<summary>📦 Install Docker Engine di Linux (Ubuntu/Debian)</summary>

```bash
# Hapus paket Docker versi lama (jika ada)
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y $pkg
done

# Setup repository resmi Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine, CLI, dan Compose plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Jalankan Docker tanpa sudo (opsional, perlu logout/login ulang setelahnya)
sudo usermod -aG docker $USER

# Verifikasi instalasi
docker --version
docker compose version
```

> 💡 Untuk distro lain (Fedora, CentOS, Arch, dll.), ikuti panduan resmi di [docs.docker.com/engine/install](https://docs.docker.com/engine/install/).
>
> ⚠️ Perintah `docker-compose up -d` di bawah ini juga bisa ditulis sebagai `docker compose up -d` (tanpa strip) jika menggunakan Docker Compose plugin v2 di Linux.

</details>

### Langkah 1 — Clone Semua Repository Sejajar

Karena menggunakan polyrepo, pastikan Anda menaruh semua repositori di dalam **satu folder parent yang sama**:

```bash
mkdir football-app
cd football-app

# Clone repo utama ini
git clone https://github.com/Bintangr191/football-community-project.git

# Clone semua service & frontend
git clone https://github.com/Bintangr191/kickoff.git
git clone https://github.com/Bintangr191/api-gateway.git
git clone https://github.com/Bintangr191/auth-service.git
git clone https://github.com/Bintangr191/football-service.git
git clone https://github.com/Bintangr191/forum-service.git
git clone https://github.com/Bintangr191/report-service.git
git clone https://github.com/Bintangr191/notification-service.git
git clone https://github.com/Bintangr191/football-community-testsappium.git

# Masuk ke repo utama untuk menjalankan Docker
cd football-community-project
```

### Langkah 2 — Siapkan File Environment

Setiap repositori service memiliki file `.env.example`. Masuk ke masing-masing folder dan salin menjadi `.env`:

```bash
# Linux/Mac
cp ../kickoff/.env.example ../kickoff/.env
cp ../api-gateway/.env.example ../api-gateway/.env
cp ../auth-service/.env.example ../auth-service/.env
cp ../football-service/.env.example ../football-service/.env
cp ../forum-service/.env.example ../forum-service/.env
cp ../report-service/.env.example ../report-service/.env
cp ../notification-service/.env.example ../notification-service/.env

# Windows PowerShell
Copy-Item ../kickoff/.env.example ../kickoff/.env
Copy-Item ../api-gateway/.env.example ../api-gateway/.env
Copy-Item ../auth-service/.env.example ../auth-service/.env
Copy-Item ../football-service/.env.example ../football-service/.env
Copy-Item ../forum-service/.env.example ../forum-service/.env
Copy-Item ../report-service/.env.example ../report-service/.env
Copy-Item ../notification-service/.env.example ../notification-service/.env
```

Kemudian **edit setiap file `.env`** sesuai panduan di bagian [Konfigurasi Environment](#️-konfigurasi-environment).

### Langkah 3 — Jalankan Semua Service

```bash
docker-compose up -d
```

Docker akan menjalankan service sesuai urutan dependensinya secara otomatis:

```
MySQL + MongoDB + RabbitMQ  →  Auth + Football + Forum + Report + Notification  →  API Gateway  →  Expo Mobile
```

### Langkah 4 — Verifikasi

```bash
curl http://localhost:3000/health
# {"status":"ok","service":"api-gateway"}

curl http://localhost:3001/health
# {"service":"auth-service","status":"ok"}
```

Akses RabbitMQ Management UI: **http://localhost:15672**
- Username: `admin`
- Password: `admin123`

---

## ⚙️ Konfigurasi Environment

> ⚠️ **PENTING — `INTERNAL_SECRET`:** Nilai ini **harus identik** di semua file `.env` (api-gateway, auth-service, football-service, forum-service, report-service, notification-service). Nilai ini digunakan sebagai kunci keamanan komunikasi antar service internal.

### API Gateway (`api-gateway/.env`)

| Variabel | Contoh | Keterangan |
|---|---|---|
| `PORT` | `3000` | Port aplikasi |
| `JWT_SECRET` | `jwt_kuat_rahasia_123` | Secret verifikasi JWT — **harus sama dengan auth-service** |
| `INTERNAL_SECRET` | `internal_secret_kuat` | Kunci komunikasi antar service — **harus sama di semua service** |
| `AUTH_SERVICE_URL` | `http://auth-service:3001` | URL auth service (nama Docker container) |
| `FOOTBALL_SERVICE_URL` | `http://football-service:3002` | URL football service |
| `FORUM_SERVICE_URL` | `http://forum-service:3003` | URL forum service |
| `REPORT_SERVICE_URL` | `http://report-service:3005` | URL report service |

### Auth Service (`auth-service/.env`)

| Variabel | Contoh | Keterangan |
|---|---|---|
| `DATABASE_URL` | `mysql://football:football123@mysql:3306/football_auth` | Koneksi MySQL |
| `JWT_SECRET` | `jwt_kuat_rahasia_123` | **Harus sama dengan api-gateway** |
| `JWT_REFRESH_SECRET` | `refresh_kuat_123` | Secret untuk refresh token (boleh berbeda) |
| `MAX_LOGIN_ATTEMPTS` | `5` | Maks percobaan login sebelum akun dikunci |
| `LOCK_TIME_MINUTES` | `10` | Durasi kunci akun (menit) |
| `INTERNAL_SECRET` | `internal_secret_kuat` | **Harus sama di semua service** |
| `NOTIFICATION_SERVICE_URL` | `http://notification-service:3004` | URL notification service |
| `FORUM_SERVICE_URL` | `http://forum-service:3003` | URL forum service |
| `CLOUDINARY_CLOUD_NAME` | `my_cloud` | Nama cloud Cloudinary |
| `CLOUDINARY_API_KEY` | `123456789012345` | API Key Cloudinary |
| `CLOUDINARY_API_SECRET` | `cloudinary_secret_xxx` | API Secret Cloudinary |
| `RABBITMQ_URL` | `amqp://admin:admin123@rabbitmq:5672` | URL koneksi RabbitMQ |

### Football Service (`football-service/.env`)

| Variabel | Contoh | Keterangan |
|---|---|---|
| `PORT` | `3002` | Port aplikasi |
| `DATABASE_URL` | `mongodb://mongodb:27017/football_db?replicaSet=rs0` | Koneksi MongoDB |
| `FOOTBALL_API_KEY` | `abc123xyz456` | API Key dari football-data.org |
| `FOOTBALL_API_URL` | `https://api.football-data.org/v4` | Base URL football-data API |
| `SPORTSDB_API_URL` | `https://www.thesportsdb.com/api/v1/json/3` | Base URL thesportsdb API |
| `INTERNAL_SECRET` | `internal_secret_kuat` | **Harus sama di semua service** |

> 💡 Daftar gratis untuk `FOOTBALL_API_KEY` di: https://www.football-data.org/client/register

### Forum Service (`forum-service/.env`)

| Variabel | Contoh | Keterangan |
|---|---|---|
| `PORT` | `3003` | Port aplikasi |
| `DATABASE_URL` | `mongodb://mongodb:27017/forum_db?replicaSet=rs0` | Koneksi MongoDB |
| `INTERNAL_SECRET` | `internal_secret_kuat` | **Harus sama di semua service** |
| `RABBITMQ_URL` | `amqp://admin:admin123@rabbitmq:5672` | URL koneksi RabbitMQ |
| `AUTH_SERVICE_URL` | `http://auth-service:3001` | URL auth service |

### Report Service (`report-service/.env`)

| Variabel | Contoh | Keterangan |
|---|---|---|
| `PORT` | `3005` | Port aplikasi |
| `DATABASE_URL` | `mongodb://mongodb:27017/report_db?replicaSet=rs0` | Koneksi MongoDB |
| `INTERNAL_SECRET` | `internal_secret_kuat` | **Harus sama di semua service** |

### Notification Service (`notification-service/.env`)

| Variabel | Contoh | Keterangan |
|---|---|---|
| `PORT` | `3004` | Port aplikasi |
| `MAIL_USER` | `namaku@gmail.com` | Alamat email pengirim OTP |
| `MAIL_PASS` | `xxxx xxxx xxxx xxxx` | **Gmail App Password** (bukan password biasa Gmail) |
| `RABBITMQ_URL` | `amqp://admin:admin123@rabbitmq:5672` | URL koneksi RabbitMQ |
| `INTERNAL_SECRET` | `internal_secret_kuat` | **Harus sama di semua service** |

> 💡 **Cara mendapatkan Gmail App Password:**
> 1. Aktifkan 2-Step Verification di akun Google
> 2. Buka https://myaccount.google.com/apppasswords
> 3. Buat App Password baru → salin 16 karakter yang muncul

---

## 🔌 Port & Service Map

| Service | Port | Akses dari Klien |
|---|---|---|
| Frontend Mobile (Expo) | `8081` | ✅ Ya — developer/emulator |
| API Gateway | `3000` | ✅ Ya — satu-satunya endpoint API untuk klien |
| Auth Service | `3001` | ❌ Internal saja |
| Football Service | `3002` | ❌ Internal saja |
| Forum Service | `3003` | ❌ Internal saja |
| Notification Service | `3004` | ❌ Internal saja |
| Report Service | `3005` | ❌ Internal saja |
| MySQL | `3306` | ❌ Internal saja |
| MongoDB | `27017` | ❌ Internal saja |
| RabbitMQ AMQP | `5672` | ❌ Internal saja |
| RabbitMQ Dashboard | `15672` | ✅ Browser (dev only) |

---

## 🧪 Menjalankan Tests

### Unit Tests (per service)

```bash
# Football Service
cd ../football-service
bun test --coverage

# Forum Service
cd ../forum-service
bun test --coverage
```

### Integration Tests (Robot Framework — End-to-End)

> Pastikan semua service sudah berjalan via `docker-compose up -d` sebelum menjalankan integration test.

```bash
cd integration-tests

# Buat dan aktifkan virtual environment Python
python -m venv venv
venv\Scripts\activate       # Windows
# source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Jalankan semua test
robot tests/

# Atau jalankan per suite
robot tests/auth_service.robot
robot tests/forum_service.robot
robot tests/football_service.robot
```

Hasil test tersedia di:
- `integration-tests/report.html` — Ringkasan test
- `integration-tests/log.html` — Log detail per test case

### Automated Mobile Testing (Appium)

Pengujian end-to-end pada aplikasi mobile (Frontend `kickoff`) dilakukan secara terpisah menggunakan Appium. Lihat repositori:

📌 **[football-community-testsappium](https://github.com/Bintangr191/football-community-testsappium)**

---

## 💻 Development (Tanpa Docker — Mode Manual)

Jika ingin menjalankan service satu per satu untuk development lokal:

### Prasyarat
- [Bun](https://bun.sh/) v1.x terinstal (`curl -fsSL https://bun.sh/install | bash`)
- Infrastruktur berjalan (bisa tetap gunakan Docker hanya untuk database):

```bash
docker-compose up -d mysql mongodb mongodb-init rabbitmq
```

### Jalankan Setiap Service di Terminal Terpisah

```bash
# Terminal 1 — Auth Service
cd ../auth-service && bun install && bun run dev

# Terminal 2 — Football Service
cd ../football-service && bun install && bun run dev

# Terminal 3 — Forum Service
cd ../forum-service && bun install && bun run dev

# Terminal 4 — Report Service
cd ../report-service && bun install && bun run dev

# Terminal 5 — Notification Service
cd ../notification-service && bun install && bun run dev

# Terminal 6 — API Gateway
cd ../api-gateway && bun install && bun run dev

# Terminal 7 — Frontend Mobile
cd ../kickoff && bun install && bun run start
```

> ⚠️ **Saat development lokal,** ubah URL service di `.env` dari nama container Docker ke `localhost`:
> ```
> AUTH_SERVICE_URL=http://localhost:3001
> FOOTBALL_SERVICE_URL=http://localhost:3002
> FORUM_SERVICE_URL=http://localhost:3003
> REPORT_SERVICE_URL=http://localhost:3005
> ```

---

## 🛡️ Keamanan

| Mekanisme | Keterangan |
|---|---|
| **JWT** | Autentikasi stateless — token diverifikasi di API Gateway sebelum diteruskan |
| **Internal Secret** | Header `x-internal-secret` memastikan service internal hanya menerima request dari gateway |
| **Rate Limiting** | 100 request/menit per IP pada route terproteksi |
| **Password Hashing** | bcrypt digunakan di auth-service |
| **Refresh Token Hash** | Refresh token disimpan dalam bentuk hash, bukan plaintext |
| **Brute-force Protection** | Akun dikunci otomatis setelah N kali gagal login |
| **OTP Expiry** | Kode OTP memiliki batas waktu dan batas percobaan |

---

## 📡 Contoh Alur Request

### Alur Login + OTP

```
Client
  │
  ▼
POST /auth/login  →  API Gateway (:3000)
                       │ (Route /auth/* tidak butuh JWT)
                       ▼
                    Auth Service (:3001)
                       │ Validasi email + password
                       │ Publish pesan ke queue "otp_send"
                       ▼
                    RabbitMQ
                       │
                       ▼
                    Notification Service (:3004)
                       │ Consume dari queue "otp_send"
                       ▼
                    Gmail SMTP → 📧 Email OTP ke user
```

### Alur Request Terproteksi (contoh: ambil data liga)

```
Client
  │
  ├─ Header: Authorization: Bearer <access_token>
  │
  ▼
GET /football/leagues  →  API Gateway (:3000)
                            │ Verifikasi JWT
                            │ Inject header: x-user-id, x-user-role, x-internal-secret
                            ▼
                         Football Service (:3002)
                            │ Validasi x-internal-secret
                            │ Ambil data dari football-data.org API
                            ▼
                         Response JSON ke Client
```

---

## 🛠️ Tech Stack

| Komponen | Teknologi |
|---|---|
| Runtime | [Bun](https://bun.sh/) |
| Web Framework | [Hono](https://hono.dev/) |
| ORM | [Prisma](https://www.prisma.io/) |
| Database Auth | MySQL 8.4 |
| Database Football & Forum | MongoDB 8.0 (Replica Set) |
| Message Broker | RabbitMQ 3 |
| Email Transport | Nodemailer (Gmail SMTP) |
| File Storage | Cloudinary |
| External Football API | football-data.org, thesportsdb.com |
| Automated Mobile Testing | Appium ([football-community-testsappium](https://github.com/Bintangr191/football-community-testsappium)) |
| Containerization | Docker & Docker Compose |
| Integration Testing | Robot Framework (Python) |
| Language | TypeScript |

---
