from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session
from ...core.database import get_db
from ...models.user import User
from ..routes.auth import get_current_user
from ...services.websocket_manager import ConnectionManager
import json

router = APIRouter()

@router.post("/signaling")
async def send_signaling_message(
    message: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send WebRTC signaling message"""
    try:
        from main import app
        manager = app.state.connection_manager
        
        # Add sender info
        message['from'] = current_user.id
        
        # Send to target user
        target_user = message.get('to')
        if target_user:
            await manager.send_personal_message(
                json.dumps(message), 
                target_user
            )
        
        return {"success": True}
    except Exception as e:
        return {"success": False, "error": str(e)}