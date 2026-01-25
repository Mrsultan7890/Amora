from fastapi import WebSocket
from typing import Dict, List
import json

class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket
    
    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
    
    async def send_personal_message(self, message: str, user_id: str):
        if user_id in self.active_connections:
            await self.active_connections[user_id].send_text(message)
    
    async def broadcast_to_match(self, message: dict, match_id: str, sender_id: str):
        # Simple broadcast - in real app, you'd query match participants
        message_text = json.dumps(message)
        for user_id, connection in self.active_connections.items():
            if user_id != sender_id:  # Don't send back to sender
                await connection.send_text(message_text)