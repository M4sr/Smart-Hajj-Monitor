import logging
from sqlalchemy.orm import Session
import models
from services.whatsapp import send_whatsapp_notification
from fastapi import BackgroundTasks

logger = logging.getLogger(__name__)

def create_notification(
    db: Session,
    id_user: int,
    pesan: str,
    custom_wa_message: str = None,
    background_tasks: BackgroundTasks = None
) -> models.Notifikasi:
    """
    Membuat notifikasi baru di database (in-app) dan secara otomatis
    mengirimkannya via WhatsApp (jika jemaah mendaftarkan nomor HP).
    
    Argumen:
    - db: Sesi database.
    - id_user: ID User penerima.
    - pesan: Teks pesan notifikasi dalam aplikasi.
    - custom_wa_message: Teks pesan kustom untuk WhatsApp (opsional).
    - background_tasks: Instance FastAPI BackgroundTasks (opsional).
    """
    # 1. Simpan ke database (In-App Notification)
    db_notif = models.Notifikasi(
        id_user=id_user,
        pesan=pesan,
        status="Belum dibaca"
    )
    db.add(db_notif)
    db.commit()
    db.refresh(db_notif)

    # 2. Ambil informasi user untuk mendapatkan nama & nomor HP
    user = db.query(models.User).filter(models.User.id_user == id_user).first()
    if user and user.no_hp:
        # Tentukan pesan WhatsApp yang akan dikirim
        if custom_wa_message:
            message_wa = custom_wa_message
        else:
            # Format pesan default jika tidak menggunakan pesan kustom
            message_wa = (
                f"Smart Hajj Monitor - Pemberitahuan\n\n"
                f"Hi {user.nama},\n\n"
                f"📢 {pesan}\n\n"
                f"Selalu pantau informasi dan kondisi kesehatan Anda di Aplikasi Smart Hajj."
            )

        # Kirim secara asinkron lewat BackgroundTasks jika disediakan, atau langsung jika tidak
        if background_tasks:
            background_tasks.add_task(send_whatsapp_notification, user.no_hp, message_wa)
        else:
            # Menggunakan background thread tersendiri jika sinkron agar tidak blocking
            import threading
            threading.Thread(
                target=send_whatsapp_notification, 
                args=(user.no_hp, message_wa), 
                daemon=True
            ).start()
            
    return db_notif
