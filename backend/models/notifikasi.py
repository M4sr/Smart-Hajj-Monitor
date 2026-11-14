from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from core.database import Base

class Notifikasi(Base):
    __tablename__ = "notifikasi"

    id_notifikasi = Column(Integer, primary_key=True, index=True)
    id_user = Column(Integer, ForeignKey("users.id_user", ondelete="CASCADE"), nullable=False)
    
    pesan = Column(Text, nullable=False)
    status = Column(String(20), default="Belum dibaca")
    tanggal = Column(DateTime, server_default=func.now())

    # Relasi
    user = relationship("User", back_populates="notifikasi")
