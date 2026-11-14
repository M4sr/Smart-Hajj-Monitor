from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
import models
from core.database import get_db
from core.security import require_role
import schemas.user

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/jemaah")
def get_all_jemaah(
    current_user: models.User = Depends(require_role(["Admin", "Petugas"])), 
    db: Session = Depends(get_db)
):
    """
    Mendapatkan daftar seluruh Jemaah (Master List)
    """
    jemaah_list = db.query(models.User).filter(models.User.role == "Jemaah").all()
    
    result = []
    for j in jemaah_list:
        result.append({
            "id_user": j.id_user,
            "nama": j.nama,
            "username": j.username,
            "usia": j.usia,
            "jenis_kelamin": j.jenis_kelamin,
            "no_hp": j.no_hp,
            "foto_profil": j.foto_profil
        })
        
    return result

@router.get("/me")
def get_my_profile(current_user: models.User = Depends(require_role(["Admin", "Petugas", "Jemaah"]))):
    """
    Mendapatkan data profil lengkap dari user yang sedang login.
    """
    return {
        "id_user": current_user.id_user,
        "nama": current_user.nama,
        "username": current_user.username,
        "usia": current_user.usia,
        "jenis_kelamin": current_user.jenis_kelamin,
        "no_hp": current_user.no_hp,
        "role": current_user.role,
        "tanggal_daftar": current_user.tanggal_daftar.isoformat() if current_user.tanggal_daftar else None,
        "status_akun": current_user.status_akun,
        "foto_profil": current_user.foto_profil
    }

@router.put("/me")
def update_my_profile(
    user_update: schemas.user.UserUpdate, 
    current_user: models.User = Depends(require_role(["Admin", "Petugas", "Jemaah"])),
    db: Session = Depends(get_db)
):
    """
    Memperbarui data profil dari user yang sedang login.
    Hanya mengizinkan pembaruan nama, usia, jenis_kelamin, dan no_hp.
    """
    if user_update.nama is not None:
        current_user.nama = user_update.nama
    if user_update.usia is not None:
        current_user.usia = user_update.usia
    if user_update.jenis_kelamin is not None:
        current_user.jenis_kelamin = user_update.jenis_kelamin
    if user_update.no_hp is not None:
        current_user.no_hp = user_update.no_hp
        
    db.commit()
    db.refresh(current_user)
    
    return {"message": "Profil berhasil diperbarui"}

@router.post("/change-password")
def change_password(
    data: schemas.user.ChangePasswordSchema,
    current_user: models.User = Depends(require_role(["Admin", "Petugas", "Jemaah"])),
    db: Session = Depends(get_db)
):
    """
    Mengubah kata sandi pengguna yang sedang login.
    """
    from core.security import verify_password, get_password_hash
    from fastapi import HTTPException
    
    if not verify_password(data.old_password, current_user.password):
        raise HTTPException(status_code=400, detail="Kata sandi lama salah")
    
    current_user.password = get_password_hash(data.new_password)
    current_user.is_temp_password = 0
    db.commit()
    
    return {"message": "Kata sandi berhasil diperbarui"}

import os
import uuid
from fastapi import UploadFile, File

@router.post("/me/upload-photo")
async def upload_profile_photo(
    file: UploadFile = File(...),
    current_user: models.User = Depends(require_role(["Admin", "Petugas", "Jemaah"])),
    db: Session = Depends(get_db)
):
    """
    Mengunggah foto profil pengguna.
    """
    if not file.content_type.startswith("image/"):
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="File harus berupa gambar.")
        
    uploads_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads", "profiles")
    if not os.path.exists(uploads_dir):
        os.makedirs(uploads_dir)
        
    # Generate unique filename
    ext = file.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    file_path = os.path.join(uploads_dir, filename)
    
    with open(file_path, "wb") as f:
        f.write(await file.read())
        
    # Relative path to save in DB
    relative_path = f"uploads/profiles/{filename}"
    
    # Update DB
    current_user.foto_profil = relative_path
    db.commit()
    
    return {"message": "Foto profil berhasil diunggah", "foto_profil": relative_path}
