from pydantic import BaseModel, Field
from datetime import datetime

class AssessmentCreate(BaseModel):
    usia: int = Field(..., ge=0, le=120, example=65)
    jenis_kelamin: str = Field(..., pattern="^(Laki-laki|Perempuan)$", example="Laki-laki")
    suhu_tubuh: float = Field(..., ge=30.0, le=45.0, example=36.5)
    sistolik: int = Field(..., ge=50, le=250, example=130)
    diastolik: int = Field(..., ge=30, le=150, example=85)
    detak_jantung: int = Field(..., ge=30, le=200, example=76)
    laju_pernapasan: int = Field(..., ge=8, le=50, example=18)
    komorbid: str = Field(..., example="Hipertensi")
    gejala_utama: str = Field(..., example="Kelelahan ringan")

class AssessmentResponse(AssessmentCreate):
    id: int
    user_id: int
    tingkat_risiko: str
    rekomendasi_tindakan: str
    created_at: datetime

    class Config:
        from_attributes = True

class RecommendationUpdate(BaseModel):
    rekomendasi_tindakan: str = Field(..., min_length=3, example="Istirahat di posko medis.")
