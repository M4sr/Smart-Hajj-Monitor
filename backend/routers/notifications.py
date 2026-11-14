from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import models
from core.database import get_db
from core.security import require_role

router = APIRouter(prefix="/notifications", tags=["Notifications"])

@router.get("")
def get_my_notifications(
    current_user: models.User = Depends(require_role(["Admin", "Petugas", "Jemaah"])),
    db: Session = Depends(get_db)
):
    """
    Mendapatkan seluruh notifikasi milik user jemaah yang sedang login.
    """
    notifications = db.query(models.Notifikasi).filter(
        models.Notifikasi.id_user == current_user.id_user
    ).order_by(models.Notifikasi.tanggal.desc()).all()
    
    result = []
    for n in notifications:
        result.append({
            "id_notifikasi": n.id_notifikasi,
            "pesan": n.pesan,
            "status": n.status,
            "tanggal": n.tanggal.isoformat() if n.tanggal else None
        })
    return result

@router.put("/{id_notifikasi}/read")
def mark_notification_as_read(
    id_notifikasi: int,
    current_user: models.User = Depends(require_role(["Admin", "Petugas", "Jemaah"])),
    db: Session = Depends(get_db)
):
    """
    Menandai satu notifikasi tertentu milik user login sebagai 'Sudah dibaca'.
    """
    notification = db.query(models.Notifikasi).filter(
        models.Notifikasi.id_notifikasi == id_notifikasi,
        models.Notifikasi.id_user == current_user.id_user
    ).first()
    
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notifikasi tidak ditemukan"
        )
        
    notification.status = "Sudah dibaca"
    db.commit()
    return {"message": "Notifikasi berhasil ditandai sebagai dibaca"}

@router.put("/read-all")
def mark_all_notifications_as_read(
    current_user: models.User = Depends(require_role(["Admin", "Petugas", "Jemaah"])),
    db: Session = Depends(get_db)
):
    """
    Menandai semua notifikasi milik user login sebagai 'Sudah dibaca'.
    """
    db.query(models.Notifikasi).filter(
        models.Notifikasi.id_user == current_user.id_user
    ).update({models.Notifikasi.status: "Sudah dibaca"}, synchronize_session=False)
    
    db.commit()
    return {"message": "Semua notifikasi berhasil ditandai sebagai dibaca"}
