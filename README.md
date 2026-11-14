<div align="center">

# 🕋 Smart Hajj Monitor

[![GitHub license](https://img.shields.io/github/license/M4sr/Smart-Hajj-Monitor?style=for-the-badge&color=emerald)](https://github.com/M4sr/Smart-Hajj-Monitor/blob/master/LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)](https://www.python.org)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)

**Sistem Monitoring & Prediksi Kesehatan Jemaah Haji Berbasis AI & Cloud Real-Time**

[Fitur Utama](#-fitur-utama) • [Arsitektur Sistem](#️-arsitektur-sistem) • [Instalasi & Menjalankan](#-instalasi--menjalankan) • [Dokumentasi API](#-dokumentasi-api)

</div>

---

## 🌟 Tentang Proyek

**Smart Hajj Monitor** adalah solusi digital modern yang dirancang untuk memantau kondisi kesehatan, posisi, serta prediksi risiko medis jemaah haji secara *real-time*. Menggabungkan teknologi **Flutter** untuk antarmuka pengguna lintas platform (Mobile & PWA) yang responsif dan elegan dengan **FastAPI & Machine Learning (Random Forest)** di sisi *backend* untuk analisis prediktif kesehatan jemaah.

---

## ✨ Fitur Utama

- 📱 **Cross-Platform Mobile App**: Dibangun dengan Flutter untuk pengalaman pengguna yang mulus di Android, iOS, dan Web (PWA).
- 🤖 **Prediksi AI Kesehatan Jemaah**: Integrasi model Machine Learning (Random Forest) untuk mendeteksi dini potensi risiko kesehatan jemaah berdasarkan parameter biologis & riwayat medis.
- 🔄 **Real-Time Synchronisation**: Sinkronisasi data jemaah secara *live* melalui REST API berkinerja tinggi.
- 📊 **Dashboard Petugas & Keluarga**: Visualisasi data statistik, status jemaah (Aman, Perlu Perhatian, Darurat), serta lokasi terkini.
- 🛡️ **Keamanan & Skalabilitas Tinggi**: Autentikasi aman dan manajemen database berbasis PostgreSQL / Supabase dengan *Row Level Security* (RLS).

---

## 🛠️ Arsitektur Sistem

```text
┌─────────────────┐       REST API / JSON       ┌──────────────────┐
│  Flutter App    │ ──────────────────────────> │   FastAPI Backend│
│ (Mobile & PWA)  │ <────────────────────────── │  (Python & ML)   │
└─────────────────┘                             └────────┬─────────┘
                                                         │
                                                         ▼
                                                ┌──────────────────┐
                                                │  Supabase DB /   │
                                                │ Random Forest AI │
                                                └──────────────────┘
```

---

## 📂 Struktur Repositori

```tree
Smart-Hajj-Monitor/
├── backend/                  # FastAPI Backend & ML Models
│   ├── main.py               # API Endpoints & Business Logic
│   ├── model/                # Trained Random Forest Models (.pkl)
│   └── requirements.txt      # Python Dependencies
├── smart_hajj_monitor/       # Flutter Application
│   ├── lib/                  # UI screens, providers, & services
│   ├── assets/               # Images, logos, & configuration
│   └── pubspec.yaml          # Flutter Dependencies
└── landing-page/             # Promotional & Landing Page
```

---

## 🚀 Instalasi & Menjalankan

### 1. Menjalankan Backend (FastAPI)
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 2. Menjalankan Flutter App
```bash
cd smart_hajj_monitor
flutter pub get
flutter run
```

---

## 📚 Dokumentasi API
Setelah backend berjalan, dokumentasi interaktif dapat diakses melalui:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

---

## 👥 Kontributor
- **Abdul Rahman** (Lead Developer)

<div align="center">
<p>Dibuat dengan ❤️ untuk kemudahan & keselamatan Jemaah Haji Indonesia.</p>
</div>
