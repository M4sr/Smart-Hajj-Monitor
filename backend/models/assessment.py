from sqlalchemy import Column, Integer, String, Float, Text, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from core.database import Base

class SelfAssessment(Base):
    __tablename__ = "self_assessments"

    id_assessment = Column(Integer, primary_key=True, index=True)
    id_user = Column(Integer, ForeignKey("users.id_user", ondelete="CASCADE"), nullable=False)
    
    gejala = Column(Text, nullable=True)
    kondisi = Column(String(100), nullable=True)
    suhu_tubuh = Column(Float, nullable=True)
    batuk = Column(String(50), nullable=True)
    sesak_napas = Column(String(50), nullable=True)
    riwayat_penyakit = Column(Text, nullable=True)
    lainnya = Column(Text, nullable=True)
    
    tanggal = Column(DateTime, server_default=func.now())

    # Relasi
    user = relationship("User", back_populates="assessments")
    hasil_klasifikasi = relationship("HasilKlasifikasi", back_populates="assessment", uselist=False, cascade="all, delete-orphan")
