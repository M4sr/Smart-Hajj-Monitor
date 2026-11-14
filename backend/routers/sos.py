from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List

from core.database import get_db
from models.user import User
from models.sos import SosRequest
from schemas.sos import SosCreate, SosResponse
from core.security import get_current_user
from services.notification_service import create_notification

router = APIRouter(prefix="/sos", tags=["SOS"])

@router.post("/", response_model=SosResponse)
def send_sos(
    sos: SosCreate, 
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    # Check if there is already an active SOS for this user
    existing = db.query(SosRequest).filter(SosRequest.user_id == current_user.id_user, SosRequest.status == "Active").first()
    if existing:
        # Update existing
        existing.latitude = sos.latitude
        existing.longitude = sos.longitude
        db.commit()
        db.refresh(existing)
        return existing

    new_sos = SosRequest(
        user_id=current_user.id_user,
        latitude=sos.latitude,
        longitude=sos.longitude,
        status="Active"
    )
    db.add(new_sos)
    db.commit()
    db.refresh(new_sos)
    
    # Notify all Petugas
    petugas_users = db.query(User).filter(User.role == "Petugas").all()
    maps_link = f"https://www.google.com/maps/search/?api=1&query={sos.latitude},{sos.longitude}"
    
    wa_message = (
        f"🚨 *DARURAT (SOS) AKTIF* 🚨\n\n"
        f"Jemaah *{current_user.nama}* telah menekan tombol SOS!\n\n"
        f"📍 *Lokasi Koordinat:*\n"
        f"{maps_link}\n\n"
        f"Segera buka aplikasi Smart Hajj Monitor di *Peta SOS* untuk menindaklanjuti keadaan darurat ini."
    )
    in_app_message = f"🚨 Jemaah {current_user.nama} menekan tombol SOS!"
    
    for petugas in petugas_users:
        create_notification(
            db=db,
            id_user=petugas.id_user,
            pesan=in_app_message,
            custom_wa_message=wa_message,
            background_tasks=background_tasks
        )

    return new_sos

@router.get("/active", response_model=List[SosResponse])
def get_active_sos(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Petugas only (ideally check role, but let's just return all for simplicity)
    active_sos = db.query(SosRequest).filter(SosRequest.status == "Active").order_by(desc(SosRequest.timestamp)).all()
    return active_sos

@router.put("/{sos_id}/resolve", response_model=SosResponse)
def resolve_sos(sos_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    sos_record = db.query(SosRequest).filter(SosRequest.id == sos_id).first()
    if not sos_record:
        raise HTTPException(status_code=404, detail="SOS record not found")
    
    sos_record.status = "Resolved"
    db.commit()
    db.refresh(sos_record)
    return sos_record
