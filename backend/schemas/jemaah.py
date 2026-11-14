from pydantic import BaseModel, Field
from typing import Optional

class SelfAssessmentInput(BaseModel):
    """Schema validasi input dari mobile app"""
    id_user: int = Field(..., description="ID user jemaah yang login")
    gejala: str = Field(..., description="Pusing, Mual, Demam, Nyeri Dada, atau Tidak Ada")
    kondisi: str = Field(..., description="Sehat, Kelelahan, Sakit Ringan, atau Sakit Parah")
    suhu_tubuh: float = Field(..., ge=35.0, le=42.0)
    batuk: str = Field(..., description="Ya / Tidak")
    sesak_napas: str = Field(..., description="Ya / Tidak")
    riwayat_penyakit: str = Field(..., description="Hipertensi, Diabetes, Jantung, Asma, atau Tidak Ada")
    lainnya: str = Field("Tidak Ada", description="Keluhan tambahan")

class KlasifikasiResponse(BaseModel):
    """Schema response ke mobile app"""
    id_hasil: int
    tingkat_risiko: str        # Rendah / Sedang / Tinggi
    probabilitas: float        # Contoh: 0.85 (85%)
    rekomendasi: str           # Teks rekomendasi
    timestamp: str

class AssessmentListResponse(BaseModel):
    """Schema list untuk Dashboard Petugas"""
    id_assessment: int
    tanggal: str
    gejala: str
    kondisi: str
    suhu_tubuh: float
    batuk: str
    sesak_napas: str
    riwayat_penyakit: str
    lainnya: str
    nama_jemaah: str
    usia: int
    jenis_kelamin: str
    tingkat_risiko: str
    probabilitas: float
    rekomendasi: str
    no_hp: Optional[str] = None
    
    class Config:
        from_attributes = True
