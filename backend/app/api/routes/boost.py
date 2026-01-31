from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.database import get_db
from app.models.user import User
from app.api.routes.auth import get_current_user
from datetime import datetime, timedelta
from pydantic import BaseModel

router = APIRouter()

class BoostRequest(BaseModel):
    boost_type: str = "free"  # free, premium
    duration_minutes: int = 30

@router.post("/activate")
async def activate_boost(
    request: BoostRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Activate profile boost for increased visibility"""
    
    try:
        # Check if user already has active boost
        if current_user.boost_expires_at and current_user.boost_expires_at > datetime.utcnow():
            remaining_minutes = int((current_user.boost_expires_at - datetime.utcnow()).total_seconds() / 60)
            return {
                "success": False,
                "message": f"Boost already active for {remaining_minutes} more minutes",
                "boost_active": True,
                "expires_at": current_user.boost_expires_at.isoformat()
            }
        
        # Set boost expiration
        boost_duration = timedelta(minutes=request.duration_minutes)
        current_user.boost_expires_at = datetime.utcnow() + boost_duration
        current_user.boost_type = request.boost_type
        
        db.commit()
        
        # Log boost activation
        db.execute(
            text("""
                INSERT OR IGNORE INTO notifications (id, user_id, type, title, message, timestamp, read)
                VALUES (:id, :user_id, :type, :title, :message, :timestamp, :read)
            """),
            {
                "id": f"boost_activated_{current_user.id}_{int(datetime.now().timestamp())}",
                "user_id": current_user.id,
                "type": "boost_activated",
                "title": "🚀 Boost Activated!",
                "message": f"Your profile is boosted for {request.duration_minutes} minutes",
                "timestamp": datetime.now().isoformat(),
                "read": False
            }
        )
        
        db.commit()
        
        return {
            "success": True,
            "message": f"Boost activated for {request.duration_minutes} minutes!",
            "boost_active": True,
            "boost_type": request.boost_type,
            "expires_at": current_user.boost_expires_at.isoformat(),
            "duration_minutes": request.duration_minutes
        }
        
    except Exception as e:
        db.rollback()
        return {"success": False, "error": str(e)}

@router.get("/status")
async def get_boost_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current boost status"""
    
    is_active = (
        current_user.boost_expires_at and 
        current_user.boost_expires_at > datetime.utcnow()
    )
    
    if is_active:
        remaining_minutes = int((current_user.boost_expires_at - datetime.utcnow()).total_seconds() / 60)
        return {
            "boost_active": True,
            "boost_type": current_user.boost_type,
            "expires_at": current_user.boost_expires_at.isoformat(),
            "remaining_minutes": remaining_minutes
        }
    else:
        return {
            "boost_active": False,
            "boost_type": None,
            "expires_at": None,
            "remaining_minutes": 0
        }

@router.get("/history")
async def get_boost_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get boost usage history"""
    
    try:
        history = db.execute(
            text("""
                SELECT title, message, timestamp, type
                FROM notifications 
                WHERE user_id = :user_id AND type = 'boost_activated'
                ORDER BY timestamp DESC
                LIMIT 10
            """),
            {"user_id": current_user.id}
        ).fetchall()
        
        return {
            "boost_history": [
                {
                    "title": row[0],
                    "message": row[1], 
                    "timestamp": row[2],
                    "type": row[3]
                }
                for row in history
            ]
        }
        
    except Exception as e:
        return {"boost_history": [], "error": str(e)}