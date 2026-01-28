from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from pydantic import BaseModel
from typing import Optional
from ...core.database import get_db
from ...models.user import User
from ..routes.auth import get_current_user
from datetime import datetime

class CallHistoryData(BaseModel):
    other_user_id: str
    call_type: str  # 'video' or 'audio'
    duration: Optional[int] = 0
    status: str  # 'completed', 'missed', 'declined'

router = APIRouter()

@router.get("/history")
async def get_call_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get call history for current user"""
    try:
        calls_query = db.execute(
            text("""
                SELECT ch.*, u.name, u.photos 
                FROM call_history ch
                JOIN users u ON (u.id = ch.caller_id OR u.id = ch.callee_id) AND u.id != :user_id
                WHERE ch.caller_id = :user_id OR ch.callee_id = :user_id
                ORDER BY ch.created_at DESC
                LIMIT 50
            """),
            {"user_id": current_user.id}
        ).fetchall()
        
        calls = []
        for call in calls_query:
            import json
            photos = json.loads(call[6]) if call[6] else []
            calls.append({
                "id": call[0],
                "other_user_id": call[1] if call[1] != current_user.id else call[2],
                "other_user_name": call[5],
                "other_user_photo": photos[0] if photos else None,
                "call_type": call[3],
                "duration": call[4],
                "status": call[7],
                "timestamp": call[8],
                "is_incoming": call[2] == current_user.id
            })
        
        return {"calls": calls}
    except Exception as e:
        return {"calls": []}

@router.post("/history")
async def save_call_history(
    call_data: CallHistoryData,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Save call history after P2P call ends"""
    try:
        db.execute(
            text("""
                INSERT INTO call_history (id, caller_id, callee_id, call_type, duration, status, created_at)
                VALUES (:id, :caller_id, :callee_id, :call_type, :duration, :status, :created_at)
            """),
            {
                "id": f"call_{current_user.id}_{call_data.other_user_id}_{int(datetime.now().timestamp())}",
                "caller_id": current_user.id,
                "callee_id": call_data.other_user_id,
                "call_type": call_data.call_type,
                "duration": call_data.duration,
                "status": call_data.status,
                "created_at": datetime.now().isoformat()
            }
        )
        db.commit()
        return {"success": True}
    except Exception as e:
        return {"success": False}