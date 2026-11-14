from core.database import Base
from models.user import User
from models.assessment import SelfAssessment
from models.klasifikasi import HasilKlasifikasi
from models.rekomendasi import Rekomendasi
from models.notifikasi import Notifikasi

__all__ = [
    "Base", 
    "User", 
    "SelfAssessment", 
    "HasilKlasifikasi", 
    "Rekomendasi", 
    "Notifikasi"
]
