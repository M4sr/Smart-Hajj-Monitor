from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from core.database import Base

class Rekomendasi(Base):
    __tablename__ = "rekomendasi"

    id_rekomendasi = Column(Integer, primary_key=True, index=True)
    id_hasil = Column(Integer, ForeignKey("hasil_klasifikasi.id_hasil", ondelete="CASCADE"), unique=True, nullable=False)
    
    deskripsi = Column(Text, nullable=True)
    saran = Column(Text, nullable=True)

    # Relasi
    hasil = relationship("HasilKlasifikasi", back_populates="rekomendasi")
