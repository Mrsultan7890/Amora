from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from ...core.database import get_db, CallHistory, User
from ...models.user import User as UserModel
from ..routes.auth import get_current_user
from datetime import datetime
import uuid

class CallHistoryData(BaseModel):
    other_user_id: str
    call_type: str  # 'video' or 'audio'
    duration: Optional[int] = 0
    status: str  # 'completed', 'missed', 'declined'

router = APIRouter()

@router.get("/history")
async def get_call_history(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get call history for current user"""
    try:
        calls = db.query(CallHistory).filter(
            (CallHistory.caller_id == current_user.id) | 
            (CallHistory.callee_id == current_user.id)
        ).order_by(CallHistory.created_at.desc()).limit(50).all()
        
        call_list = []
        for call in calls:
            other_user_id = call.callee_id if call.caller_id == current_user.id else call.caller_id
            other_user = db.query(User).filter(User.id == other_user_id).first()
            
            call_list.append({
                "id": call.id,
                "other_user_id": other_user_id,
                "other_user_name": other_user.name if other_user else "Unknown",
                "other_user_photo": other_user.photos if other_user else None,
                "call_type": call.call_type,
                "duration": call.duration,
                "status": call.status,
                "timestamp": call.created_at.isoformat(),
                "is_incoming": call.callee_id == current_user.id
            })
        
        return {"calls": call_list}
    except Exception as e:
        return {"calls": []}

@router.post("/history")
async def save_call_history(
    call_data: CallHistoryData,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Save call history after P2P call ends"""
    try:
        call_history = CallHistory(
            id=str(uuid.uuid4()),
            caller_id=current_user.id,
            callee_id=call_data.other_user_id,
            call_type=call_data.call_type,
            duration=call_data.duration or 0,
            status=call_data.status,
            created_at=datetime.utcnow()
        )
        
        db.add(call_history)
        db.commit()
        return {"success": True}
    except Exception as e:
        return {"success": False, "error": str(e)}