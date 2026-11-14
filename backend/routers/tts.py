import os
import hashlib
from fastapi import APIRouter, Query, HTTPException
from fastapi.responses import FileResponse, StreamingResponse
from gtts import gTTS
import io

router = APIRouter(prefix="/tts", tags=["Text to Speech"])

# Cache directory inside backend/static/audio
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
CACHE_DIR = os.path.join(CURRENT_DIR, "..", "static", "audio")

try:
    os.makedirs(CACHE_DIR, exist_ok=True)
except Exception as e:
    print(f"Warning: Could not create cache directory: {e}")

@router.get("")
@router.get("/audio.mp3")
def text_to_speech(
    text: str = Query(..., description="Text to convert to speech"),
    lang: str = Query("ar", description="Language code (e.g. ar, id)")
):
    if not text.strip():
        raise HTTPException(status_code=400, detail="Text parameter cannot be empty")
        
    try:
        # Generate a unique filename using md5 of text + lang
        text_hash = hashlib.md5(f"{text}_{lang}".encode('utf-8')).hexdigest()
        filename = f"{text_hash}.mp3"
        filepath = os.path.join(CACHE_DIR, filename)
        
        # Check cache (file must exist and have size > 0)
        if os.path.exists(filepath) and os.path.getsize(filepath) > 0:
            return FileResponse(filepath, media_type="audio/mpeg")
            
        # Generate TTS if not cached
        try:
            # Generate speech from Google Translate TTS in specified language
            tts = gTTS(text=text, lang=lang, slow=False)
            tts.save(filepath)
            
            # Double check that file was written successfully and is not 0 bytes
            if not os.path.exists(filepath) or os.path.getsize(filepath) == 0:
                raise ValueError("Generated file is empty or missing")
                
            return FileResponse(filepath, media_type="audio/mpeg")
        except Exception as write_err:
            # Clean up the file if it was created but is empty/corrupt
            if os.path.exists(filepath):
                try:
                    os.remove(filepath)
                except Exception:
                    pass
                    
            print(f"Cache write error (falling back to dynamic stream): {write_err}")
            tts = gTTS(text=text, lang=lang, slow=False)
            fp = io.BytesIO()
            tts.write_to_fp(fp)
            fp.seek(0)
            return StreamingResponse(fp, media_type="audio/mpeg")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"TTS Generation failed: {str(e)}")
