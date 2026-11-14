import joblib
import json
import pandas as pd
import numpy as np
from datetime import datetime
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_DIR = os.path.join(BASE_DIR, "model")

class RiskPredictor:
    def __init__(self):
        try:
            self.model = joblib.load(os.path.join(MODEL_DIR, "rf_model.pkl"))
            self.preprocessor = joblib.load(os.path.join(MODEL_DIR, "preprocessor.pkl"))
            self.le = joblib.load(os.path.join(MODEL_DIR, "label_encoder.pkl"))
            print("Model loaded successfully")
        except Exception as e:
            print(f"Error loading model: {e}")
            self.model = None

    def predict(self, input_data: dict) -> dict:
        if not self.model:
            raise ValueError("Model is not loaded")

        # input_data harus memiliki 9 keys: 
        # usia, jenis_kelamin, gejala, kondisi, suhu_tubuh, batuk, sesak_napas, riwayat_penyakit, lainnya
        df = pd.DataFrame([input_data])
        
        # Transform menggunakan ColumnTransformer (StandardScaler + OneHotEncoder)
        df_processed = self.preprocessor.transform(df)

        # Prediksi label dan probabilitas
        pred_encoded = self.model.predict(df_processed)[0]
        proba = self.model.predict_proba(df_processed)[0]

        label = self.le.inverse_transform([pred_encoded])[0]
        max_proba = float(np.max(proba))

        # Generate rekomendasi berdasarkan label dan input data secara dinamis
        rekomendasi = self._get_rekomendasi(label, input_data)

        return {
            "tingkat_risiko": label,
            "probabilitas": max_proba,
            "rekomendasi": rekomendasi,
            "timestamp": datetime.now().isoformat(),
        }

    def _get_rekomendasi(self, label: str, input_data: dict) -> str:
        # Base recommendations
        if label == "Tinggi":
            base = "🚨 BAHAYA: Sistem mendeteksi kondisi kesehatan Anda kritis / berisiko TINGGI. Jangan melanjutkan aktivitas fisik apapun!"
        elif label == "Sedang":
            base = "⚠️ PERINGATAN: Sistem mendeteksi kondisi kesehatan Anda berada dalam tingkat risiko SEDANG. Harap segera batasi aktivitas fisik berat Anda."
        else:
            base = "✅ STABIL: Kondisi kesehatan Anda terpantau berada dalam batas normal / risiko RENDAH."

        bullet_points = []

        # Parse specific symptoms and inputs to generate dynamic points
        suhu = input_data.get("suhu_tubuh", 36.5)
        kondisi = input_data.get("kondisi", "Sehat")
        gejala = input_data.get("gejala", "Tidak Ada")
        batuk = input_data.get("batuk", "Tidak")
        sesak = input_data.get("sesak_napas", "Tidak")
        riwayat = input_data.get("riwayat_penyakit", "Tidak Ada")
        lainnya = input_data.get("lainnya", "Tidak Ada")

        # 1. Temperature-based advice
        if suhu >= 38.5:
            bullet_points.append(f"Suhu tubuh Anda sangat tinggi ({suhu}°C). Segera kompres dahi dengan air biasa, konsumsi Paracetamol 500mg, dan laporkan segera ke dokter kloter.")
        elif suhu >= 37.5:
            bullet_points.append(f"Suhu tubuh Anda hangat ({suhu}°C). Perbanyak hidrasi air putih/oralit minimal 300ml setiap jam untuk mencegah dehidrasi parah.")

        # 2. Breathing/Shortness of breath
        if sesak == "Ya" or sesak == "YA":
            bullet_points.append("Anda mengalami sesak napas. Posisikan tubuh bersandar setengah duduk (semifowler) untuk melapangkan pernapasan, hindari kerumunan padat, dan segera hubungi petugas medis untuk bantuan tabung oksigen portable.")

        # 3. Cough advice
        if batuk == "Ya" or batuk == "YA":
            bullet_points.append("Keluhan batuk terdeteksi. Gunakan masker secara disiplin agar tidak menulari jemaah lain dan hindari minum air dingin/es.")

        # 4. Condition based
        if kondisi == "Sakit Parah":
            bullet_points.append("Kondisi fisik Anda sangat lemah. Segera laporkan ke ketua rombongan agar petugas medis dapat mendatangi maktab/tenda Anda.")
        elif kondisi == "Kelelahan":
            bullet_points.append("Kondisi lelah fisik. Istirahat total minimal 4-6 jam di dalam kamar maktab ber-AC, hindari keluar tenda di siang hari.")

        # 5. Symptom specific advice
        if gejala == "Nyeri Dada":
            bullet_points.append("Nyeri dada terdeteksi! Ini gejala krusial. Duduk tenang, atur napas secara santai, dan segera panggil bantuan medis darurat karena berisiko gejala jantung.")
        elif gejala == "Demam" and suhu < 37.5:
            bullet_points.append("Merasa demam: Periksa suhu tubuh secara berkala, perbanyak minum air hangat, dan istirahat.")
        elif gejala == "Pusing":
            bullet_points.append("Pusing/sakit kepala: Kemungkinan akibat sengatan panas atau kurang tidur. Istirahat di tempat teduh dan basahi handuk kecil untuk ditempelkan di kepala.")
        elif gejala == "Mual":
            bullet_points.append("Mual/muntah: Hindari makanan berlemak atau bersantan sementara waktu. Konsumsi air hangat sedikit demi sedikit secara bertahap.")

        # 6. Medical history advice
        if riwayat != "Tidak Ada":
            bullet_points.append(f"Jaga kondisi dengan meminum obat rutin untuk riwayat penyakit {riwayat} Anda sesuai anjuran dokter kloter.")

        # If no specific warning points are triggered, add general wellness advice
        if not bullet_points:
            if label == "Rendah":
                bullet_points.append("Tetap jaga stamina: Konsumsi air minimal 2-3 liter per hari, gunakan payung saat keluar tenda, dan semprotkan air ke wajah secara berkala.")
            else:
                bullet_points.append("Harap laporkan perkembangan kondisi Anda secara berkala jika merasakan keluhan baru.")

        # Combine into a clean structured recommendation
        points_str = "\n• " + "\n• ".join(bullet_points)
        return f"{base}\n\nLangkah Penanganan Medis:{points_str}"

# Singleton instance
predictor = RiskPredictor()
