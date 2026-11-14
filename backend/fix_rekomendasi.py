import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from core.database import SessionLocal
import models

def fix_missing_rekomendasi():
    db: Session = SessionLocal()
    try:
        # Cari semua HasilKlasifikasi yang belum punya rekomendasi
        hasil_list = db.query(models.HasilKlasifikasi).all()
        
        for hasil in hasil_list:
            if not hasil.rekomendasi:
                print(f"Menambahkan rekomendasi dummy untuk ID Hasil {hasil.id_hasil}")
                
                saran = ""
                if hasil.tingkat_risiko == "Rendah":
                    saran = "Kondisi Anda sangat baik. Tetap jaga pola makan, perbanyak minum air putih, dan istirahat yang cukup setelah beribadah."
                elif hasil.tingkat_risiko == "Sedang":
                    saran = "Harap waspada. Perbanyak istirahat di penginapan, minum oralit atau vitamin, dan kurangi aktivitas fisik berat di luar ruangan."
                else:
                    saran = "PERINGATAN: Kondisi Anda memerlukan penanganan medis segera! Petugas medis kami sedang melacak lokasi Anda. Segera hubungi kloter terdekat."

                rek = models.Rekomendasi(
                    id_hasil=hasil.id_hasil,
                    deskripsi=f"Hasil analisis risiko: {hasil.tingkat_risiko}",
                    saran=saran
                )
                db.add(rek)
        
        db.commit()
        print("Perbaikan rekomendasi selesai!")
        
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    fix_missing_rekomendasi()
