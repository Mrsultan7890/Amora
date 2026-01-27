import asyncio
import json
from datetime import datetime
import requests
from app.core.config import settings

# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN = settings.TELEGRAM_VERIFICATION_BOT_TOKEN
ADMIN_CHAT_ID = settings.TELEGRAM_VERIFICATION_CHAT_ID
API_BASE_URL = "http://localhost:8000/api"

async def send_verification_request(user):
    """Send verification request to admin via Telegram using HTTP API"""
    try:
        # Create user info message
        photos_count = len(json.loads(user.photos)) if user.photos else 0
        
        message = f"""
🔔 **New Verification Request**

👤 **User Details:**
• Name: {user.name}
• Age: {user.age}
• Gender: {user.gender}
• Email: {user.email}

📝 **Profile Info:**
• Bio: {user.bio[:100]}{'...' if len(user.bio) > 100 else ''}
• Job: {user.job or 'Not specified'}
• Education: {user.education or 'Not specified'}
• Photos: {photos_count}

🎨 **Verification Details:**
• Badge Color: {user.verification_badge_color.title()}
• Profile Completion: {user.profile_completion}%
• Account Age: {(datetime.utcnow() - user.created_at).days} days

⏰ **Requested:** {user.verification_requested_at.strftime('%Y-%m-%d %H:%M')}

**Actions:**
/approve_{user.id} - Approve verification
/reject_{user.id} - Reject verification
        """
        
        # Send message via Telegram HTTP API
        url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
        data = {
            "chat_id": ADMIN_CHAT_ID,
            "text": message,
            "parse_mode": "Markdown"
        }
        
        response = requests.post(url, json=data)
        if response.status_code == 200:
            print(f"Verification request sent to Telegram for user {user.id}")
        else:
            print(f"Failed to send Telegram message: {response.text}")
        
    except Exception as e:
        print(f"Error sending Telegram message: {e}")