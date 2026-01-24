import httpx
import aiofiles
from typing import Optional
import os
from app.core.config import settings

class TelegramService:
    def __init__(self):
        self.bot_token = settings.TELEGRAM_BOT_TOKEN
        self.chat_id = settings.TELEGRAM_CHAT_ID
        self.api_url = f"{settings.TELEGRAM_API_URL}/bot{self.bot_token}"

    async def upload_image(self, file_path: str, caption: str = "") -> Optional[str]:
        """Upload image to Telegram and return the file URL"""
        try:
            async with httpx.AsyncClient() as client:
                # Read file
                async with aiofiles.open(file_path, 'rb') as f:
                    file_content = await f.read()
                
                # Prepare form data
                files = {
                    'photo': ('image.jpg', file_content, 'image/jpeg')
                }
                data = {
                    'chat_id': self.chat_id,
                    'caption': caption
                }
                
                # Send to Telegram
                response = await client.post(
                    f"{self.api_url}/sendPhoto",
                    files=files,
                    data=data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    if result.get('ok'):
                        # Get the largest photo size
                        photos = result['result']['photo']
                        largest_photo = max(photos, key=lambda x: x['file_size'])
                        file_id = largest_photo['file_id']
                        
                        # Get file path
                        file_info = await self.get_file_info(file_id)
                        if file_info:
                            return f"{settings.TELEGRAM_API_URL}/file/bot{self.bot_token}/{file_info['file_path']}"
                
                return None
                
        except Exception as e:
            print(f"Error uploading to Telegram: {e}")
            return None
        finally:
            # Clean up local file
            if os.path.exists(file_path):
                os.remove(file_path)

    async def get_file_info(self, file_id: str) -> Optional[dict]:
        """Get file information from Telegram"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.api_url}/getFile",
                    params={'file_id': file_id}
                )
                
                if response.status_code == 200:
                    result = response.json()
                    if result.get('ok'):
                        return result['result']
                
                return None
                
        except Exception as e:
            print(f"Error getting file info: {e}")
            return None

    async def delete_message(self, message_id: int) -> bool:
        """Delete message from Telegram (if possible)"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.api_url}/deleteMessage",
                    json={
                        'chat_id': self.chat_id,
                        'message_id': message_id
                    }
                )
                
                if response.status_code == 200:
                    result = response.json()
                    return result.get('ok', False)
                
                return False
                
        except Exception as e:
            print(f"Error deleting message: {e}")
            return False

telegram_service = TelegramService()