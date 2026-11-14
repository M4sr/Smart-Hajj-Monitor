from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
import secrets
import string
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
import os

from core.database import get_db
import models
import schemas.user as user_schemas
from core.security import get_password_hash, verify_password, create_access_token
from services.whatsapp import send_whatsapp_notification

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=user_schemas.UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_in: user_schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.username == user_in.username).first()
    if db_user:
        raise HTTPException(
            status_code=400,
            detail="Nama pengguna sudah digunakan."
        )
        
    hashed_pwd = get_password_hash(user_in.password)
    new_user = models.User(
        username=user_in.username,
        nama=user_in.nama,
        password=hashed_pwd,
        usia=user_in.usia,
        jenis_kelamin=user_in.jenis_kelamin,
        no_hp=user_in.no_hp,
        role=user_in.role
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/login", response_model=user_schemas.Token)
def login_oauth_form(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """
    Standard OAuth2 password login endpoint. Accepts form-data.
    Required for the Swagger UI 'Authorize' button.
    """
    user = db.query(models.User).filter(models.User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nama pengguna atau kata sandi salah.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": user.username, "role": user.role})
    return user_schemas.Token(
        access_token=access_token,
        token_type="bearer",
        role=user.role,
        nama=user.nama,
        username=user.username,
        is_temporary_password=bool(user.is_temp_password),
        foto_profil=user.foto_profil
    )

@router.post("/login/json", response_model=user_schemas.Token)
def login_json(credentials: user_schemas.LoginRequest, db: Session = Depends(get_db)):
    """
    JSON login endpoint. Accepts application/json payloads.
    Recommended for Flutter/Dart mobile integration.
    """
    user = db.query(models.User).filter(models.User.username == credentials.username).first()
    if not user or not verify_password(credentials.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nama pengguna atau kata sandi salah."
        )
    access_token = create_access_token(data={"sub": user.username, "role": user.role})
    return user_schemas.Token(
        access_token=access_token,
        token_type="bearer",
        role=user.role,
        nama=user.nama,
        username=user.username,
        is_temporary_password=bool(user.is_temp_password),
        foto_profil=user.foto_profil
    )

@router.post("/forgot-password")
def forgot_password(data: user_schemas.ForgotPasswordRequest, db: Session = Depends(get_db)):
    """
    Mengatur ulang kata sandi pengguna dengan kata sandi sementara
    dan mengirimkannya via WhatsApp menggunakan Fonnte API Gateway.
    """
    user = db.query(models.User).filter(
        (models.User.username == data.identifier) | (models.User.no_hp == data.identifier)
    ).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Akun tidak ditemukan. Periksa kembali Username atau Nomor WhatsApp Anda."
        )
        
    if not user.no_hp:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Akun ini tidak memiliki nomor WhatsApp yang terdaftar."
        )
        
    # Generate temporary password (6 digits)
    temp_password = "".join(secrets.choice(string.digits) for _ in range(6))
    
    # Hash and update password
    user.password = get_password_hash(temp_password)
    user.is_temp_password = 1
    db.commit()
    
    # Send via WhatsApp
    message = (
        f"Halo {user.nama},\n\n"
        f"Kami menerima permintaan pemulihan kata sandi untuk akun Anda ({user.username}).\n"
        f"Kata sandi sementara Anda adalah: *{temp_password}*\n\n"
        f"Silakan masuk ke aplikasi menggunakan kata sandi sementara ini, dan segera ubah kata sandi Anda melalui menu Pengaturan Akun."
    )
    
    send_whatsapp_notification(user.no_hp, message)
        
    return {"message": "Kata sandi sementara telah dikirim ke nomor WhatsApp Anda."}

# Ambil dari .env (di VPS)
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")

@router.post("/google", response_model=user_schemas.Token)
def google_auth(request: user_schemas.GoogleLoginRequest, db: Session = Depends(get_db)):
    """
    Autentikasi menggunakan Google Sign-In id_token.
    Jika user belum ada, maka otomatis didaftarkan sebagai Jemaah.
    """
    try:
        # Verify token
        # PERHATIAN: Jika masih pengembangan dan belum ada Client ID, Anda bisa 
        # mematikan verifikasi audiens sementara dengan menambahkan `audience=None`
        idinfo = id_token.verify_oauth2_token(
            request.id_token, 
            google_requests.Request(), 
            GOOGLE_CLIENT_ID
        )
        
        email = idinfo.get("email")
        name = idinfo.get("name", "Google User")
        
        if not email:
            raise HTTPException(status_code=400, detail="Token tidak memiliki informasi email.")
            
        # Periksa apakah user dengan email tersebut sudah ada
        user = db.query(models.User).filter(models.User.email == email).first()
        
        if not user:
            # Register user baru
            base_username = email.split('@')[0]
            username = base_username
            
            # Pastikan username unik
            counter = 1
            while db.query(models.User).filter(models.User.username == username).first():
                username = f"{base_username}{counter}"
                counter += 1
                
            # Random password untuk user google
            random_pwd = "".join(secrets.choice(string.ascii_letters + string.digits) for _ in range(16))
            
            user = models.User(
                username=username,
                nama=name,
                password=get_password_hash(random_pwd),
                email=email,
                auth_provider="google",
                role="Jemaah"
            )
            db.add(user)
            db.commit()
            db.refresh(user)
            
        access_token = create_access_token(data={"sub": user.username, "role": user.role})
        return user_schemas.Token(
            access_token=access_token,
            token_type="bearer",
            role=user.role,
            nama=user.nama,
            username=user.username,
            is_temporary_password=bool(user.is_temp_password),
            foto_profil=user.foto_profil
        )
        
    except ValueError as ve:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token Google tidak valid atau kadaluarsa: {str(ve)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Terjadi kesalahan saat autentikasi Google: {str(e)}"
        )
