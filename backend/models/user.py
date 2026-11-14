from sqlalchemy import Column, Integer, String, DateTime, func
from sqlalchemy.orm import relationship
from core.database import Base

class User(Base):
    __tablename__ = "users"

    id_user = Column(Integer, primary_key=True, index=True)
    nama = Column(String(100), nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=False)
    password = Column(String(255), nullable=False)
    usia = Column(Integer, nullable=True)
    jenis_kelamin = Column(String(20), nullable=True)
    no_hp = Column(String(20), nullable=True)
    tanggal_daftar = Column(DateTime, server_default=func.now())
    status_akun = Column(String(20), default="Aktif")
    role = Column(String(20), default="Jemaah", nullable=False) # Jemaah atau Petugas
    is_temp_password = Column(Integer, default=0, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=True)
    auth_provider = Column(String(20), default="local", nullable=False)
    foto_profil = Column(String(255), nullable=True)

    # Relasi
    assessments = relationship("SelfAssessment", back_populates="user", cascade="all, delete-orphan")
    notifikasi = relationship("Notifikasi", back_populates="user", cascade="all, delete-orphan")
    sos_requests = relationship("SosRequest", back_populates="user", cascade="all, delete-orphan")
