from fastapi import WebSocket
from typing import Dict, List
import json
import asyncio
from datetime import datetime

class ConnectionManager:
    def __init__(self):
        # Store active connections: user_id -> websocket
        self.active_connections: Dict[str, WebSocket] = {}
        # Store user matches for broadcasting: user_id -> [match_ids]
        self.user_matches: Dict[str, List[str]] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        
        # Send connection confirmation
        await self.send_personal_message({
            "type": "connection",
            "message": "Connected successfully",
            "timestamp": datetime.utcnow().isoformat()
        }, user_id)

    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
        if user_id in self.user_matches:
            del self.user_matches[user_id]

    async def send_personal_message(self, message: dict, user_id: str):
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_text(json.dumps(message))
            except:
                # Connection closed, remove it
                self.disconnect(user_id)

    async def broadcast_to_match(self, message: dict, match_id: str, sender_id: str):
        """Broadcast message to all participants in a match"""
        # Add metadata
        message.update({
            "timestamp": datetime.utcnow().isoformat(),
            "match_id": match_id,
            "sender_id": sender_id
        })
        
        # Send to all connected users in this match
        for user_id, websocket in self.active_connections.items():
            if user_id != sender_id:  # Don't send back to sender
                # Check if user is part of this match (you'd implement this logic)
                if await self.is_user_in_match(user_id, match_id):
                    try:
                        await websocket.send_text(json.dumps(message))
                    except:
                        self.disconnect(user_id)

    async def send_match_notification(self, user1_id: str, user2_id: str, match_data: dict):
        """Send match notification to both users"""
        notification = {
            "type": "new_match",
            "data": match_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        await self.send_personal_message(notification, user1_id)
        await self.send_personal_message(notification, user2_id)

    async def send_typing_indicator(self, match_id: str, user_id: str, is_typing: bool):
        """Send typing indicator to match participants"""
        message = {
            "type": "typing",
            "match_id": match_id,
            "user_id": user_id,
            "is_typing": is_typing,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        for connected_user_id, websocket in self.active_connections.items():
            if connected_user_id != user_id:  # Don't send to the typer
                if await self.is_user_in_match(connected_user_id, match_id):
                    try:
                        await websocket.send_text(json.dumps(message))
                    except:
                        self.disconnect(connected_user_id)

    async def send_online_status(self, user_id: str, is_online: bool):
        """Broadcast user online status to their matches"""
        message = {
            "type": "user_status",
            "user_id": user_id,
            "is_online": is_online,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Get user's matches and send status to them
        user_matches = self.user_matches.get(user_id, [])
        for match_id in user_matches:
            await self.broadcast_to_match(message, match_id, user_id)

    async def is_user_in_match(self, user_id: str, match_id: str) -> bool:
        """Check if user is participant in the match"""
        # This would query the database to check match participants
        # For now, returning True (implement proper logic)
        return True

    def get_connected_users(self) -> List[str]:
        """Get list of currently connected user IDs"""
        return list(self.active_connections.keys())

    async def broadcast_to_all(self, message: dict):
        """Broadcast message to all connected users"""
        message["timestamp"] = datetime.utcnow().isoformat()
        
        disconnected_users = []
        for user_id, websocket in self.active_connections.items():
            try:
                await websocket.send_text(json.dumps(message))
            except:
                disconnected_users.append(user_id)
        
        # Clean up disconnected users
        for user_id in disconnected_users:
            self.disconnect(user_id)