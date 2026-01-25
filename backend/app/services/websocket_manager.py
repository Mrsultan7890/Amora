from fastapi import WebSocket
from typing import Dict, List
from sqlalchemy.orm import Session
import json

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        print(f"User {user_id} connected to WebSocket")
    
    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            print(f"User {user_id} disconnected from WebSocket")
    
    async def send_personal_message(self, message: str, user_id: str):
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_text(message)
            except Exception as e:
                print(f"Error sending message to {user_id}: {e}")
                self.disconnect(user_id)
    
    async def broadcast_to_match(self, message: dict, match_id: str, sender_id: str):
        from app.core.database import SessionLocal, Match
        
        # Get match participants
        db = SessionLocal()
        try:
            match = db.query(Match).filter(Match.id == match_id).first()
            if match:
                # Send to the other participant
                recipient_id = match.user2_id if match.user1_id == sender_id else match.user1_id
                
                if recipient_id in self.active_connections:
                    message_text = json.dumps({
                        "type": "new_message",
                        "match_id": match_id,
                        "sender_id": sender_id,
                        "content": message.get("content", ""),
                        "timestamp": message.get("timestamp", ""),
                        "message_type": message.get("message_type", "text")
                    })
                    await self.send_personal_message(message_text, recipient_id)
        finally:
            db.close()
    
    async def send_typing_indicator(self, match_id: str, sender_id: str, is_typing: bool):
        from app.core.database import SessionLocal, Match
        
        db = SessionLocal()
        try:
            match = db.query(Match).filter(Match.id == match_id).first()
            if match:
                recipient_id = match.user2_id if match.user1_id == sender_id else match.user1_id
                
                if recipient_id in self.active_connections:
                    typing_message = json.dumps({
                        "type": "typing_indicator",
                        "match_id": match_id,
                        "sender_id": sender_id,
                        "is_typing": is_typing
                    })
                    await self.send_personal_message(typing_message, recipient_id)
        finally:
            db.close()