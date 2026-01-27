import requests
import json
from app.core.config import settings

class TelegramService:
    def __init__(self):
        self.report_bot_token = settings.TELEGRAM_REPORT_BOT_TOKEN
        self.report_chat_id = settings.TELEGRAM_REPORT_CHAT_ID
        self.support_bot_token = settings.TELEGRAM_SUPPORT_BOT_TOKEN
        self.support_chat_id = settings.TELEGRAM_SUPPORT_CHAT_ID
        self.storage_bot_token = settings.TELEGRAM_STORAGE_BOT_TOKEN
        self.storage_chat_id = settings.TELEGRAM_STORAGE_CHAT_ID
    
    def _send_message(self, bot_token: str, chat_id: str, message: str, parse_mode: str = "HTML"):
        """Send message to specific Telegram bot"""
        try:
            url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
            data = {
                "chat_id": chat_id,
                "text": message,
                "parse_mode": parse_mode
            }
            response = requests.post(url, json=data)
            return response.json()
        except Exception as e:
            print(f"Failed to send Telegram message: {e}")
            return None
    
    def send_report(self, reporter_name: str, reported_user: str, reason: str, description: str = None):
        """Send user report to Report Bot"""
        message = f"""
🚨 <b>USER REPORT</b> 🚨

👤 <b>Reporter:</b> {reporter_name}
🎯 <b>Reported User:</b> {reported_user}
⚠️ <b>Reason:</b> {reason}
"""
        if description:
            message += f"📝 <b>Description:</b> {description}"
        
        message += f"\n\n⏰ <b>Time:</b> {self._get_current_time()}"
        
        return self._send_message(self.report_bot_token, self.report_chat_id, message)
    
    def send_support_request(self, user_name: str, user_email: str, subject: str, message: str):
        """Send support request to Support Bot"""
        support_message = f"""
💬 <b>SUPPORT REQUEST</b> 💬

👤 <b>User:</b> {user_name}
📧 <b>Email:</b> {user_email}
📋 <b>Subject:</b> {subject}
💭 <b>Message:</b> {message}

⏰ <b>Time:</b> {self._get_current_time()}
"""
        return self._send_message(self.support_bot_token, self.support_chat_id, support_message)
    
    def send_emergency_alert(self, user_name: str, location: str = None):
        """Send emergency alert to Report Bot"""
        message = f"""
🆘 <b>EMERGENCY ALERT</b> 🆘

👤 <b>User:</b> {user_name}
"""
        if location:
            message += f"📍 <b>Location:</b> {location}"
        
        message += f"\n\n⏰ <b>Time:</b> {self._get_current_time()}"
        message += "\n\n❗ <b>IMMEDIATE ATTENTION REQUIRED</b> ❗"
        
        return self._send_message(self.report_bot_token, self.report_chat_id, message)
    
    def _get_current_time(self):
        """Get current formatted time"""
        from datetime import datetime
        return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# Singleton instance
telegram_service = TelegramService()