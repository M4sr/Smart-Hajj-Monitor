from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class SosCreate(BaseModel):
    latitude: float
    longitude: float

class SosUserResponse(BaseModel):
    id_user: int
    nama: str
    no_hp: Optional[str] = None
    usia: Optional[int] = None
    jenis_kelamin: Optional[str] = None

    class Config:
        from_attributes = True

class SosResponse(BaseModel):
    id: int
    user_id: int
    latitude: float
    longitude: float
    status: str
    timestamp: datetime
    user: Optional[SosUserResponse] = None

    class Config:
        from_attributes = True
