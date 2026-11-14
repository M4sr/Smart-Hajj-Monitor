import os
import sys

# Tambahkan direktori saat ini ke sys.path agar bisa import modul
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from core.database import SessionLocal, engine
import models
from core.security import get_password_hash

def seed_database():
    # Pastikan semua tabel ter-create
    models.Base.metadata.create_all(bind=engine)
    
    db: Session = SessionLocal()
    
    try:
        # Cek apakah sudah ada data
        if db.query(models.User).first():
            print("Database sudah berisi data. Seeding dibatalkan.")
            return

        print("Memulai proses seeding data User...")

        # Data Petugas Kesehatan
        petugas1 = models.User(
            username="petugas1",
            password=get_password_hash("password123"),
            nama="Dr. Ahmad Petugas",
            usia=40,
            jenis_kelamin="Laki-laki",
            no_hp="081234567890",
            role="Petugas"
        )

        # Data Jemaah
        jemaah1 = models.User(
            username="jemaah1",
            password=get_password_hash("password123"),
            nama="Bapak Budi Jemaah",
            usia=65,
            jenis_kelamin="Laki-laki",
            no_hp="089876543210",
            role="Jemaah"
        )
        
        jemaah2 = models.User(
            username="jemaah2",
            password=get_password_hash("password123"),
            nama="Ibu Siti Jemaah",
            usia=60,
            jenis_kelamin="Perempuan",
            no_hp="085544332211",
            role="Jemaah"
        )

        db.add(petugas1)
        db.add(jemaah1)
        db.add(jemaah2)
        
        db.commit()
        db.refresh(jemaah1)
        db.refresh(jemaah2)

        # Seeding Notifikasi
        notif1 = models.Notifikasi(
            id_user=jemaah1.id_user,
            pesan="Hasil Analisis Tersedia: AI mendeteksi sedikit gejala kelelahan. Harap perbanyak minum air putih.",
            status="Belum dibaca"
        )
        notif2 = models.Notifikasi(
            id_user=jemaah1.id_user,
            pesan="Cuaca Ekstrem (42°C): Suhu di Mekkah saat ini sangat panas. Gunakan payung jika keluar ruangan.",
            status="Belum dibaca"
        )
        notif3 = models.Notifikasi(
            id_user=jemaah1.id_user,
            pesan="Jadwal Minum Obat: Waktunya meminum obat hipertensi (Amlodipine 5mg).",
            status="Sudah dibaca"
        )
        notif4 = models.Notifikasi(
            id_user=jemaah2.id_user,
            pesan="Selamat Datang!: Akun Anda berhasil terdaftar di Smart Hajj Monitor. Semoga ibadah Anda lancar.",
            status="Sudah dibaca"
        )

        db.add_all([notif1, notif2, notif3, notif4])
        db.commit()

        print("Seeding berhasil!")
        print("-" * 30)
        print("Akun Petugas: petugas1 / password123")
        print("Akun Jemaah: jemaah1 / password123")
        print("Akun Jemaah: jemaah2 / password123")
        print("-" * 30)

    except Exception as e:
        db.rollback()
        print(f"Error saat seeding: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
