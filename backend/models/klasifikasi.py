from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from core.database import Base

class HasilKlasifikasi(Base):
    __tablename__ = "hasil_klasifikasi"

    id_hasil = Column(Integer, primary_key=True, index=True)
    id_assessment = Column(Integer, ForeignKey("self_assessments.id_assessment", ondelete="CASCADE"), unique=True, nullable=False)
    
    tingkat_risiko = Column(String(20), nullable=False) # Rendah, Sedang, Tinggi
    probabilitas = Column(Float, nullable=True)
    tanggal_proses = Column(DateTime, server_default=func.now())
    model = Column(String(50), nullable=True)

    # Relasi
    assessment = relationship("SelfAssessment", back_populates="hasil_klasifikasi")
    rekomendasi = relationship("Rekomendasi", back_populates="hasil", uselist=False, cascade="all, delete-orphan")
