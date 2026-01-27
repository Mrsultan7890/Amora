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
        print(f"Uploading file: {file.filename}, type: {file.content_type}")
        
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Generate unique filename
        file_extension = Path(file.filename).suffix
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        
        # Read file content
        file_content = await file.read()
        print(f"File size: {len(file_content)} bytes")
        
        # Upload to Telegram Storage Bot
        if settings.TELEGRAM_STORAGE_BOT_TOKEN and settings.TELEGRAM_STORAGE_CHAT_ID:
            print(f"Uploading to Telegram Storage: {settings.TELEGRAM_STORAGE_CHAT_ID}")
            try:
                async with httpx.AsyncClient(timeout=30.0) as client:
                    files = {
                        'photo': (unique_filename, file_content, file.content_type)
                    }
                    data = {
                        'chat_id': settings.TELEGRAM_STORAGE_CHAT_ID
                    }
                    
                    response = await client.post(
                        f"https://api.telegram.org/bot{settings.TELEGRAM_STORAGE_BOT_TOKEN}/sendPhoto",
                        files=files,
                        data=data
                    )
                    
                    print(f"Telegram response: {response.status_code}")
                    if response.status_code == 200:
                        result = response.json()
                        print(f"Telegram result: {result}")
                        if result.get('ok'):
                            # Get file_id from Telegram response
                            file_id = result['result']['photo'][-1]['file_id']
                            # Get file info to get proper URL
                            file_info_response = await client.get(
                                f"https://api.telegram.org/bot{settings.TELEGRAM_STORAGE_BOT_TOKEN}/getFile",
                                params={'file_id': file_id}
                            )
                            if file_info_response.status_code == 200:
                                file_info = file_info_response.json()
                                if file_info.get('ok'):
                                    file_path = file_info['result']['file_path']
                                    telegram_url = f"https://api.telegram.org/file/bot{settings.TELEGRAM_STORAGE_BOT_TOKEN}/{file_path}"
                                    print(f"Returning Telegram URL: {telegram_url}")
                                    return {"url": telegram_url}
                    else:
                        print(f"Telegram error: {response.text}")
            except Exception as telegram_error:
                print(f"Telegram upload failed: {telegram_error}")
        
        # Fallback: save locally
        print("Using local storage fallback")
        static_dir = Path("static/uploads")
        static_dir.mkdir(parents=True, exist_ok=True)
        
        file_path = static_dir / unique_filename
        with open(file_path, "wb") as f:
            f.write(file_content)
        
        return {"url": f"/static/uploads/{unique_filename}"}
        
    except Exception as e:
        print(f"Upload error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

@router.delete("/image/{image_id}")
async def delete_image(image_id: str):
    return {"message": f"Delete image {image_id} endpoint"}