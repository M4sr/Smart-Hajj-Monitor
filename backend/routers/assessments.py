import logging
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session

from core.database import get_db
import models
from schemas.jemaah import SelfAssessmentInput, KlasifikasiResponse, AssessmentListResponse
from services.predictor import predictor
from core.security import get_current_user, require_role
from services.notification_service import create_notification

router = APIRouter(prefix="/assessments", tags=["Health Assessments"])
logger = logging.getLogger(__name__)

@router.post("/klasifikasi", response_model=KlasifikasiResponse, status_code=status.HTTP_201_CREATED)
async def create_assessment(
    data: SelfAssessmentInput,
    background_tasks: BackgroundTasks,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Endpoint menerima input dari jemaah, memprediksi menggunakan ML, 
    dan menyebarkan hasilnya ke tabel terkait.
    """
    # 1. Pastikan id_user menggunakan user yang terautentikasi (aman)
    data.id_user = current_user.id_user
    user = current_user


    try:
        # 2. Insert ke tabel SelfAssessment
        db_assessment = models.SelfAssessment(
            id_user=user.id_user,
            gejala=data.gejala,
            kondisi=data.kondisi,
            suhu_tubuh=data.suhu_tubuh,
            batuk=data.batuk,
            sesak_napas=data.sesak_napas,
            riwayat_penyakit=data.riwayat_penyakit,
            lainnya=data.lainnya
        )
        db.add(db_assessment)
        db.commit()
        db.refresh(db_assessment)

        # 3. Prediksi menggunakan ML Model (9 fitur)
        ml_input = {
            "usia": user.usia or 40, 
            "jenis_kelamin": user.jenis_kelamin or "Laki-laki",
            "gejala": data.gejala,
            "kondisi": data.kondisi,
            "suhu_tubuh": data.suhu_tubuh,
            "batuk": data.batuk,
            "sesak_napas": data.sesak_napas,
            "riwayat_penyakit": data.riwayat_penyakit,
            "lainnya": data.lainnya
        }
        
        result = predictor.predict(ml_input)

        # 4. Insert ke tabel HasilKlasifikasi
        db_hasil = models.HasilKlasifikasi(
            id_assessment=db_assessment.id_assessment,
            tingkat_risiko=result['tingkat_risiko'],
            probabilitas=result['probabilitas'],
            model="RandomForest-v2"
        )
        db.add(db_hasil)
        db.commit()
        db.refresh(db_hasil)

        # 5. Insert ke tabel Rekomendasi
        db_rekomendasi = models.Rekomendasi(
            id_hasil=db_hasil.id_hasil,
            deskripsi=f"Tingkat risiko kesehatan {result['tingkat_risiko']}.",
            saran=result['rekomendasi']
        )
        db.add(db_rekomendasi)
        db.commit()

        # 6. Kirim notifikasi kesehatan HANYA jika tingkat risiko "Tinggi"
        if result['tingkat_risiko'] == "Tinggi":
            pesan_notif = f"Cuaca Ekstrem / Kondisi Kritis: AI mendeteksi kondisi Anda berisiko TINGGI. Harap segera hubungi petugas medis."
            
            # Kirim notifikasi kesehatan menggunakan helper pusat (otomatis DB + WhatsApp)
            message_wa = (
                f"🚨 Smart Hajj Monitor - PERINGATAN MEDIS!\n\n"
                f"Hi {user.nama},\n\n"
                f"{pesan_notif}\n\n"
                f"📊 Detail Pemeriksaan:\n"
                f"- Suhu Tubuh: {data.suhu_tubuh}°C\n"
                f"- Keluhan Batuk: {data.batuk}\n"
                f"- Sesak Napas: {data.sesak_napas}\n"
                f"- Hasil Prediksi AI: Risiko {result['tingkat_risiko']}\n\n"
                f"Saran Medis: {result['rekomendasi']}\n\n"
                f"Mohon segera beristirahat atau meminta bantuan di posko kesehatan terdekat."
            )

            create_notification(
                db=db,
                id_user=user.id_user,
                pesan=pesan_notif,
                custom_wa_message=message_wa,
                background_tasks=background_tasks
            )

        return {
            "id_hasil": db_hasil.id_hasil,
            "tingkat_risiko": result['tingkat_risiko'],
            "probabilitas": result['probabilitas'],
            "rekomendasi": result['rekomendasi'],
            "timestamp": result['timestamp']
        }

    except Exception as e:
        db.rollback()
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Gagal memproses assessment: {str(e)}")


@router.get("/my")
def get_my_assessments(
    current_user: models.User = Depends(require_role(["Jemaah"])), 
    db: Session = Depends(get_db)
):
    """
    RBAC: Hanya Jemaah.
    Mendapatkan riwayat pemeriksaan khusus milik jemaah yang sedang login.
    """
    assessments = db.query(models.SelfAssessment).filter(models.SelfAssessment.id_user == current_user.id_user).order_by(models.SelfAssessment.tanggal.desc()).all()
    return assessments


@router.get("/all", response_model=list[AssessmentListResponse])
def get_all_assessments(
    current_user: models.User = Depends(require_role(["Admin", "Petugas"])), 
    db: Session = Depends(get_db)
):
    """
    RBAC: Hanya Admin dan Petugas Kesehatan.
    Mendapatkan seluruh riwayat pemeriksaan dari semua jemaah lengkap dengan info risikonya.
    """
    assessments = db.query(models.SelfAssessment).order_by(models.SelfAssessment.tanggal.desc()).all()
    
    result = []
    for a in assessments:
        user = a.user
        hasil = a.hasil_klasifikasi
        
        result.append({
            "id_assessment": a.id_assessment,
            "tanggal": a.tanggal.isoformat() if a.tanggal else "",
            "gejala": a.gejala or "Tidak Ada",
            "kondisi": a.kondisi or "Sehat",
            "suhu_tubuh": a.suhu_tubuh or 36.5,
            "batuk": a.batuk or "Tidak",
            "sesak_napas": a.sesak_napas or "Tidak",
            "riwayat_penyakit": a.riwayat_penyakit or "Tidak Ada",
            "lainnya": a.lainnya or "Tidak Ada",
            "nama_jemaah": user.nama if user else "Unknown",
            "usia": user.usia if user else 0,
            "jenis_kelamin": user.jenis_kelamin if user else "-",
            "tingkat_risiko": hasil.tingkat_risiko if hasil else "Belum Diklasifikasi",
            "probabilitas": hasil.probabilitas if hasil else 0.0,
            "rekomendasi": (hasil and hasil.rekomendasi) and hasil.rekomendasi.saran or "Tidak ada saran.",
            "no_hp": user.no_hp if user else "-"
        })
        
    return result

@router.get("/me", response_model=list[AssessmentListResponse])
def get_my_assessments(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Mendapatkan riwayat pemeriksaan untuk jemaah yang sedang login.
    """
    assessments = db.query(models.SelfAssessment).filter(models.SelfAssessment.id_user == current_user.id_user).order_by(models.SelfAssessment.tanggal.desc()).all()
    
    result = []
    for a in assessments:
        hasil = a.hasil_klasifikasi
        
        result.append({
            "id_assessment": a.id_assessment,
            "tanggal": a.tanggal.isoformat() if a.tanggal else "",
            "gejala": a.gejala or "Tidak Ada",
            "kondisi": a.kondisi or "Sehat",
            "suhu_tubuh": a.suhu_tubuh or 36.5,
            "batuk": a.batuk or "Tidak",
            "sesak_napas": a.sesak_napas or "Tidak",
            "riwayat_penyakit": a.riwayat_penyakit or "Tidak Ada",
            "lainnya": a.lainnya or "Tidak Ada",
            "nama_jemaah": current_user.nama,
            "usia": current_user.usia or 0,
            "jenis_kelamin": current_user.jenis_kelamin or "-",
            "tingkat_risiko": hasil.tingkat_risiko if hasil else "Belum Diklasifikasi",
            "probabilitas": hasil.probabilitas if hasil else 0.0,
            "rekomendasi": (hasil and hasil.rekomendasi) and hasil.rekomendasi.saran or "Tidak ada saran.",
            "no_hp": current_user.no_hp
        })
        
    return result


@router.get("/user/{id_user}", response_model=list[AssessmentListResponse])
def get_user_assessments(
    id_user: int,
    current_user: models.User = Depends(require_role(["Admin", "Petugas"])),
    db: Session = Depends(get_db)
):
    """
    RBAC: Hanya Admin dan Petugas Kesehatan.
    Mendapatkan riwayat pemeriksaan spesifik untuk satu jemaah.
    """
    assessments = db.query(models.SelfAssessment).filter(models.SelfAssessment.id_user == id_user).order_by(models.SelfAssessment.tanggal.desc()).all()
    
    result = []
    for a in assessments:
        user = a.user
        hasil = a.hasil_klasifikasi
        
        result.append({
            "id_assessment": a.id_assessment,
            "tanggal": a.tanggal.isoformat() if a.tanggal else "",
            "gejala": a.gejala or "Tidak Ada",
            "kondisi": a.kondisi or "Sehat",
            "suhu_tubuh": a.suhu_tubuh or 36.5,
            "batuk": a.batuk or "Tidak",
            "sesak_napas": a.sesak_napas or "Tidak",
            "riwayat_penyakit": a.riwayat_penyakit or "Tidak Ada",
            "lainnya": a.lainnya or "Tidak Ada",
            "nama_jemaah": user.nama if user else "Unknown",
            "usia": user.usia if user else 0,
            "jenis_kelamin": user.jenis_kelamin if user else "-",
            "tingkat_risiko": hasil.tingkat_risiko if hasil else "Belum Diklasifikasi",
            "probabilitas": hasil.probabilitas if hasil else 0.0,
            "rekomendasi": (hasil and hasil.rekomendasi) and hasil.rekomendasi.saran or "Tidak ada saran.",
            "no_hp": user.no_hp if user else "-"
        })
        
    return result
