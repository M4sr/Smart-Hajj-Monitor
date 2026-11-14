from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, example="jemaah1")
    nama: str = Field(..., min_length=3, max_length=100, example="Ahmad Fauzi")
    usia: Optional[int] = Field(None, example=65)
    jenis_kelamin: Optional[str] = Field(None, example="Laki-laki")
    no_hp: Optional[str] = Field(None, example="08123456789")
    email: Optional[str] = Field(None, example="user@example.com")
    auth_provider: Optional[str] = Field("local", example="local")
    foto_profil: Optional[str] = Field(None, example="uploads/profiles/user_1.jpg")

class UserCreate(UserBase):
    password: str = Field(..., min_length=6, example="password123")
    role: Optional[str] = Field("Jemaah", pattern="^(Admin|Petugas|Jemaah)$", example="Jemaah")

class UserUpdate(BaseModel):
    nama: Optional[str] = Field(None, min_length=3, max_length=100, example="Ahmad Fauzi")
    usia: Optional[int] = Field(None, example=65)
    jenis_kelamin: Optional[str] = Field(None, example="Laki-laki")
    no_hp: Optional[str] = Field(None, example="08123456789")

class UserResponse(UserBase):
    id_user: int
    role: str
    status_akun: str
    tanggal_daftar: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    role: str
    nama: str
    username: str
    is_temporary_password: bool = False
    foto_profil: Optional[str] = None

class TokenData(BaseModel):
    username: Optional[str] = None
    role: Optional[str] = None

class LoginRequest(BaseModel):
    username: str
    password: str

class ChangePasswordSchema(BaseModel):
    old_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=6, example="newpassword123")

class ForgotPasswordRequest(BaseModel):
    identifier: str = Field(..., min_length=3, example="jemaah1")

class GoogleLoginRequest(BaseModel):
    id_token: str = Field(...)
