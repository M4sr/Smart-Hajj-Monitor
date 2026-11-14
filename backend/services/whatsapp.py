import logging
import requests

logger = logging.getLogger(__name__)

FONNTE_TOKEN = "wtEzGmT4nuW6GnDtVT2c"
FONNTE_URL = "https://api.fonnte.com/send"

def send_whatsapp_notification(phone_number: str, message: str) -> bool:
    """
    Mengirim pesan notifikasi WhatsApp ke nomor jemaah menggunakan Fonnte API Gateway.
    """
    if not phone_number:
        logger.warning("WhatsApp send failed: Phone number is empty.")
        return False

    # Bersihkan nomor telepon (Fonnte menyukai format internasional seperti 628xxx atau 08xxx)
    cleaned_phone = phone_number.strip()
    
    headers = {
        "Authorization": FONNTE_TOKEN
    }
    
    payload = {
        "target": cleaned_phone,
        "message": message
    }
    
    try:
        logger.info(f"Mengirim WhatsApp ke {cleaned_phone} via Fonnte...")
        # Print to stdout for debugging/verification in uvicorn logs
        print(f"\n[WHATSAPP MOCK] Sending WhatsApp to {cleaned_phone}:\n{message}\n", flush=True)
        # Write to absolute local file path for automated integration testing
        try:
            with open(r"c:\laragon\www\Smart-Hajj-Monitor\backend\whatsapp_sent.txt", "w", encoding="utf-8") as f:
                f.write(message)
        except Exception as fe:
            print(f"Failed to write to whatsapp_sent.txt: {fe}", flush=True)
            
        response = requests.post(FONNTE_URL, headers=headers, data=payload, timeout=10)
        response_json = response.json()
        
        # Fonnte mengembalikan status: true jika sukses
        if response.status_code == 200 and response_json.get("status") is True:
            logger.info(f"WhatsApp berhasil terkirim ke {cleaned_phone}!")
            return True
        else:
            logger.error(f"Gagal mengirim WhatsApp. Status Code: {response.status_code}, Response: {response.text}")
            return False
    except Exception as e:
        logger.error(f"Error saat mengirim pesan WhatsApp: {str(e)}")
        return False
