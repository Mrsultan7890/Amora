from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from app.core.config import settings
import httpx
import os
import uuid
from pathlib import Path

router = APIRouter()

@router.post("/image")
async def upload_image(file: UploadFile = File(...)):
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Generate unique filename
        file_extension = Path(file.filename).suffix
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        
        # Read file content
        file_content = await file.read()
        
        # Upload to Telegram
        if settings.TELEGRAM_BOT_TOKEN and settings.TELEGRAM_CHAT_ID:
            async with httpx.AsyncClient() as client:
                files = {
                    'photo': (unique_filename, file_content, file.content_type)
                }
                data = {
                    'chat_id': settings.TELEGRAM_CHAT_ID
                }
                
                response = await client.post(
                    f"https://api.telegram.org/bot{settings.TELEGRAM_BOT_TOKEN}/sendPhoto",
                    files=files,
                    data=data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    if result.get('ok'):
                        # Get file_id from Telegram response
                        file_id = result['result']['photo'][-1]['file_id']
                        # Return Telegram file URL
                        return {"url": f"https://api.telegram.org/file/bot{settings.TELEGRAM_BOT_TOKEN}/{file_id}"}
        
        # Fallback: save locally
        static_dir = Path("static/uploads")
        static_dir.mkdir(parents=True, exist_ok=True)
        
        file_path = static_dir / unique_filename
        with open(file_path, "wb") as f:
            f.write(file_content)
        
        return {"url": f"/static/uploads/{unique_filename}"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@router.delete("/image/{image_id}")
async def delete_image(image_id: str):
    return {"message": f"Delete image {image_id} endpoint"}