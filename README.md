# ⚽ Football Community App — Backend

Backend untuk aplikasi komunitas sepak bola berbasis **microservice architecture**. Setiap fitur besar dipisah menjadi service mandiri yang berkomunikasi melalui sebuah **API Gateway** terpusat.

---

## 📐 Arsitektur Sistem

```
                        ┌─────────────────────────────┐
                        │        CLIENT (Mobile/Web)   │
                        └──────────────┬──────────────┘
                                       │ HTTP Request
                                       ▼
                        ┌─────────────────────────────┐
                        │        API Gateway           │
                        │     (Hono · Port 3000)       │
                        │                              │
                        │  • JWT Auth Middleware        │
                        │  • Rate Limiting (100/min)   │
                        │  • CORS Handling             │
                        │  • Reverse Proxy             │
                        └──────┬──────┬──────┬─────────┘
                               │      │      │
              ┌────────────────┘      │      └─────────────────┐
              │                       │                         │
              ▼                       ▼                         ▼
  ┌─────────────────┐   ┌─────────────────────┐   ┌────────────────────┐
  │  Auth Service   │   │  Football Service   │   │   Forum Service    │
  │  Port :3001     │   │  Port :3002         │   │   Port :3003       │
  │  DB: MySQL      │   │  DB: MongoDB        │   │   DB: MongoDB      │
  │  + RabbitMQ     │   │  + External API     │   │   + RabbitMQ       │
  └────────┬────────┘   └─────────────────────┘   └──────────┬─────────┘
           │                                                   │
           │ publish → otp_send                  publish msgs │
           └────────────────────┬────────────────────────────┘
                                ▼
                ┌───────────────────────────────┐
                │     Notification Service       │
                │     Port :3004                 │
                │  (RabbitMQ Consumer)           │
                │  Kirim email OTP via SMTP      │
                └───────────────────────────────┘

  Infrastructure:
  ┌──────────────────────────────────────────────────────────┐
  │   MySQL :3306  |  MongoDB :27017  |  RabbitMQ :5672      │
  └──────────────────────────────────────────────────────────┘
```

---

## 🗂️ Struktur Direktori (Polyrepo)

Proyek ini menggunakan pendekatan **Polyrepo**, di mana setiap service berada di repositori terpisah. Repositori utama ini hanya berisi file orchestrasi (`docker-compose.yml`) dan integrasi tes.

Struktur folder yang diharapkan saat di-clone di komputer Anda:
```text
parent-folder/
├── football-community-be/      ← Repositori UTAMA ini (docker-compose & tests)
├── api-gateway/                ← Repositori API Gateway
├── auth-service/               ← Repositori Auth Service
├── football-service/           ← Repositori Football Service
├── forum-service/              ← Repositori Forum Service
└── notification-service/       ← Repositori Notification Service
```

---

## 🧩 Deskripsi Service

### 🔐 Auth Service (`:3001`)

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

Mengirim notifikasi email (OTP) melalui antrian RabbitMQ. Service ini **tidak dipanggil langsung oleh klien** — ia mendengarkan pesan dari queue RabbitMQ yang dikirim oleh auth-service, kemudian mengirimkan email lewat Gmail SMTP.

- **Transport:** Nodemailer (SMTP Gmail)
- **Message Broker:** RabbitMQ (consumer — queue `otp_send`)

---

### 🚦 API Gateway (`:3000`)

Satu-satunya entry point bagi klien. Bertanggung jawab atas:

| Fitur | Keterangan |
|---|---|
| **JWT Verification** | Verifikasi Bearer token di semua route terproteksi |
| **Rate Limiting** | Maks 100 request/menit per IP |
| **CORS** | Mengizinkan request lintas origin |
| **Reverse Proxy** | Meneruskan request ke service yang tepat |
| **Header Injection** | Menyisipkan `x-user-id`, `x-user-role`, `x-user-email`, `x-internal-secret` ke setiap request internal |

**Peta Route:**

| Route Gateway | Diteruskan ke |
|---|---|
| `/auth/*` | Auth Service `:3001` |
| `/upload/*` | Auth Service `:3001` |
| `/football/*` | Football Service `:3002` |
| `/forum/*` | Forum Service `:3003` |

> ⚠️ `/auth/*` dan `/upload/*` tidak memerlukan JWT. Semua route lain (`/football/*`, `/forum/*`) **wajib menyertakan** `Authorization: Bearer <token>`.

---

## 🚀 Cara Menjalankan (Docker — Direkomendasikan)

### Prasyarat
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) terinstal dan berjalan

### Langkah 1 — Clone Semua Repository Sejajar

Karena menggunakan polyrepo, pastikan Anda menaruh semua repositori di dalam **satu folder parent yang sama**:

```bash
mkdir football-app
cd football-app

# Clone repo utama ini
git clone <repo-url-utama> football-community-be

# Clone semua service
git clone <repo-api-gateway> api-gateway
git clone <repo-auth-service> auth-service
git clone <repo-football-service> football-service
git clone <repo-forum-service> forum-service
git clone <repo-notification-service> notification-service

# Masuk ke repo utama untuk menjalankan Docker
cd football-community-be
```

### Langkah 2 — Siapkan File Environment

Setiap repositori service memiliki file `.env.example`. Masuk ke masing-masing folder dan salin menjadi `.env`:

```bash
# Contoh (Linux/Mac)
cp ../api-gateway/.env.example ../api-gateway/.env
cp ../auth-service/.env.example ../auth-service/.env
cp ../football-service/.env.example ../football-service/.env
cp ../forum-service/.env.example ../forum-service/.env
cp ../notification-service/.env.example ../notification-service/.env

# Contoh (Windows PowerShell)
Copy-Item ../api-gateway/.env.example ../api-gateway/.env
Copy-Item ../auth-service/.env.example ../auth-service/.env
Copy-Item ../football-service/.env.example ../football-service/.env
Copy-Item ../forum-service/.env.example ../forum-service/.env
Copy-Item ../notification-service/.env.example ../notification-service/.env
```

Kemudian **edit setiap file `.env`** sesuai panduan di bagian [Konfigurasi Environment](#-konfigurasi-environment).

### Langkah 3 — Jalankan Semua Service

```bash
docker-compose up -d
```

Docker akan menjalankan service sesuai urutan dependensinya secara otomatis:

```
MySQL + MongoDB + RabbitMQ  →  Auth + Football + Forum + Notification  →  API Gateway
```

### Langkah 5 — Jalankan Database Migration

Setelah container berjalan, deploy migrasi Prisma untuk auth-service:

```bash
docker exec -it football-auth sh -c "npx prisma migrate deploy"
```

> ℹ️ **MongoDB** sudah dikonfigurasi dengan replica set (`rs0`) yang diperlukan oleh Prisma. Inisialisasi replica set dijalankan otomatis oleh container `mongodb-init`.

### Langkah 6 — Verifikasi

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

> ⚠️ **PENTING — `INTERNAL_SECRET`:** Nilai ini **harus identik** di semua file `.env` (api-gateway, auth-service, football-service, forum-service, notification-service). Nilai ini digunakan sebagai kunci keamanan komunikasi antar service internal.

---

### API Gateway (`api-gateway/.env`)

| Variabel | Contoh | Keterangan |
|---|---|---|
| `PORT` | `3000` | Port aplikasi |
| `JWT_SECRET` | `jwt_kuat_rahasia_123` | Secret verifikasi JWT — **harus sama dengan auth-service** |
| `INTERNAL_SECRET` | `internal_secret_kuat` | Kunci komunikasi antar service — **harus sama di semua service** |
| `AUTH_SERVICE_URL` | `http://auth-service:3001` | URL auth service (nama Docker container) |
| `FOOTBALL_SERVICE_URL` | `http://football-service:3002` | URL football service |
| `FORUM_SERVICE_URL` | `http://forum-service:3003` | URL forum service |

---

### Auth Service (`services/auth-service/.env`)

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

---

### Football Service (`services/football-service/.env`)

| Variabel | Contoh | Keterangan |
|---|---|---|
| `PORT` | `3002` | Port aplikasi |
| `DATABASE_URL` | `mongodb://mongodb:27017/football_db?replicaSet=rs0` | Koneksi MongoDB |
| `FOOTBALL_API_KEY` | `abc123xyz456` | API Key dari football-data.org |
| `FOOTBALL_API_URL` | `https://api.football-data.org/v4` | Base URL football-data API |
| `SPORTSDB_API_URL` | `https://www.thesportsdb.com/api/v1/json/3` | Base URL thesportsdb API |
| `INTERNAL_SECRET` | `internal_secret_kuat` | **Harus sama di semua service** |

> 💡 Daftar gratis untuk `FOOTBALL_API_KEY` di: https://www.football-data.org/client/register

---

### Forum Service (`services/forum-service/.env`)

| Variabel | Contoh | Keterangan |
|---|---|---|
| `PORT` | `3003` | Port aplikasi |
| `DATABASE_URL` | `mongodb://mongodb:27017/forum_db?replicaSet=rs0` | Koneksi MongoDB |
| `INTERNAL_SECRET` | `internal_secret_kuat` | **Harus sama di semua service** |
| `RABBITMQ_URL` | `amqp://admin:admin123@rabbitmq:5672` | URL koneksi RabbitMQ |
| `AUTH_SERVICE_URL` | `http://auth-service:3001` | URL auth service |

---

### Notification Service (`services/notification-service/.env`)

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
| **API Gateway** | `3000` | ✅ **Ya — satu-satunya endpoint untuk klien** |
| Auth Service | `3001` | ❌ Internal saja |
| Football Service | `3002` | ❌ Internal saja |
| Forum Service | `3003` | ❌ Internal saja |
| Notification Service | `3004` | ❌ Internal saja |
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

# Terminal 4 — Notification Service
cd ../notification-service && bun install && bun run dev

# Terminal 5 — API Gateway
cd ../api-gateway && bun install && bun run dev
```

> ⚠️ **Saat development lokal,** ubah URL service di `.env` dari nama container Docker ke `localhost`:
> ```
> AUTH_SERVICE_URL=http://localhost:3001
> FOOTBALL_SERVICE_URL=http://localhost:3002
> FORUM_SERVICE_URL=http://localhost:3003
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
| Containerization | Docker & Docker Compose |
| Integration Testing | Robot Framework (Python) |
| Language | TypeScript |
