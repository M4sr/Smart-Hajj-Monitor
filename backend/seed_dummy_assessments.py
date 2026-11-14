import os
import sys
import datetime

# Tambahkan direktori saat ini ke sys.path agar bisa import modul
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from core.database import SessionLocal, engine
import models
from services.predictor import predictor

def seed_dummy_assessments():
    db: Session = SessionLocal()
    try:
        # Cari jemaah
        jemaah1 = db.query(models.User).filter(models.User.username == "jemaah1").first()
        jemaah2 = db.query(models.User).filter(models.User.username == "jemaah2").first()

        if not jemaah1 or not jemaah2:
            print("Gagal menemukan Jemaah di database. Harap jalankan seed_db.py dulu.")
            return

        print("Menambahkan dummy assessment untuk Jemaah...")

        # Data 1: Risiko Rendah
        a1 = models.SelfAssessment(
            id_user=jemaah1.id_user,
            gejala="Tidak Ada",
            kondisi="Sehat",
            suhu_tubuh=36.5,
            batuk="Tidak",
            sesak_napas="Tidak",
            riwayat_penyakit="Tidak Ada",
            lainnya="Tidak Ada"
        )
        db.add(a1)
        db.commit()
        db.refresh(a1)

        h1 = models.HasilKlasifikasi(
            id_assessment=a1.id_assessment,
            tingkat_risiko="Rendah",
            probabilitas=0.95,
            model="RandomForest-v2"
        )
        db.add(h1)

        # Data 2: Risiko Tinggi
        a2 = models.SelfAssessment(
            id_user=jemaah2.id_user,
            gejala="Pusing, Demam",
            kondisi="Sakit Parah",
            suhu_tubuh=39.0,
            batuk="Ya",
            sesak_napas="Ya",
            riwayat_penyakit="Hipertensi",
            lainnya="Tidak Ada"
        )
        db.add(a2)
        db.commit()
        db.refresh(a2)

        h2 = models.HasilKlasifikasi(
            id_assessment=a2.id_assessment,
            tingkat_risiko="Tinggi",
            probabilitas=0.88,
            model="RandomForest-v2"
        )
        db.add(h2)

        db.commit()
        print("Dummy assessments berhasil ditambahkan!")
        
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_dummy_assessments()
