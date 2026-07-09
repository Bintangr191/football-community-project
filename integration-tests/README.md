<div align="center">
  <h1>🤖 Integration Tests</h1>
  <p><em>Automated End-to-End Testing menggunakan Robot Framework</em></p>
  <img src="https://img.shields.io/badge/Framework-Robot%20Framework-000000" />
  <img src="https://img.shields.io/badge/Language-Python-blue?logo=python" />
</div>

---

## 📖 Overview

Direktori ini berisi skrip pengujian otomatis (integration tests / end-to-end) untuk backend Football Community App. 
Testing ini akan melakukan *hit* langsung ke API Gateway layaknya klien sungguhan, sehingga membutuhkan seluruh microservice berjalan bersamaan.

## ⚙️ Prasyarat

- Python 3.8 atau lebih baru
- Semua microservice backend dalam keadaan berjalan (jalankan `docker-compose up -d` di folder root repo ini)

## 🚀 Persiapan (Setup)

1. **Buat Virtual Environment** (Sangat disarankan agar tidak mengotori Python global):
   ```bash
   python -m venv venv
   ```

2. **Aktifkan Virtual Environment**:
   - Di Windows (PowerShell/CMD):
     ```bash
     venv\Scripts\activate
     ```
   - Di Linux / Mac:
     ```bash
     source venv/bin/activate
     ```

3. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

## 🧪 Cara Menjalankan Test

Pastikan virtual environment sudah aktif (biasanya ada tulisan `(venv)` di terminal Anda).

**Jalankan semua test sekaligus:**
```bash
robot tests/
```

**Jalankan test per modul/service tertentu:**
```bash
robot tests/auth_service.robot
robot tests/forum_service.robot
robot tests/football_service.robot
robot tests/report_service.robot
```

## 📊 Melihat Hasil Test

Setelah perintah selesai berjalan, Robot Framework akan menghasilkan 3 file di direktori ini:
- `report.html` — Ringkasan hasil test (Lulus/Gagal) dengan tampilan UI yang mudah dibaca. Buka di browser Anda.
- `log.html` — Log eksekusi yang sangat detail, langkah demi langkah. Cocok untuk menelusuri di mana letak errornya.
- `output.xml` — Data mentah hasil test (biasanya digunakan oleh CI/CD pipeline).