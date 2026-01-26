from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db, Match
from app.models.user import User
from app.api.routes.auth import get_current_user
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import asyncio

router = APIRouter()

class EmergencyAlertRequest(BaseModel):
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    timestamp: str

@router.post("/alert")
async def send_emergency_alert(
    alert_data: EmergencyAlertRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Send emergency alert to all matched users"""
    
    try:
        # Get all matches for current user
        matches = db.query(Match).filter(
            ((Match.user1_id == current_user.id) | (Match.user2_id == current_user.id)),
            Match.is_active == True
        ).all()
        
        alert_count = 0
        
        for match in matches:
            # Get the other user in the match
            other_user_id = match.user2_id if match.user1_id == current_user.id else match.user1_id
            other_user = db.query(User).filter(User.id == other_user_id).first()
            
            if other_user:
                # Create emergency notification
                await _create_emergency_notification(
                    db=db,
                    user_id=other_user.id,
                    sender_id=current_user.id,
                    sender_name=current_user.name,
                    latitude=alert_data.latitude,
                    longitude=alert_data.longitude,
                    timestamp=alert_data.timestamp
                )
                alert_count += 1
        
        print(f"Emergency alert sent to {alert_count} matches for user {current_user.name}")
        
        return {
            "message": "Emergency alert sent successfully",
            "alerts_sent": alert_count,
            "timestamp": alert_data.timestamp
        }
        
    except Exception as e:
        print(f"Error sending emergency alert: {e}")
        raise HTTPException(status_code=500, detail="Failed to send emergency alert")

async def _create_emergency_notification(
    db: Session,
    user_id: str,
    sender_id: str,
    sender_name: str,
    latitude: Optional[float],
    longitude: Optional[float],
    timestamp: str
):
    """Create emergency notification for user"""
    
    # Location text
    location_text = ""
    if latitude and longitude:
        location_text = f" at location {latitude:.6f}, {longitude:.6f}"
    
    # Create emergency message in chat
    from app.core.database import Message
    
    # Find match between sender and receiver
    match = db.query(Match).filter(
        ((Match.user1_id == user_id) & (Match.user2_id == sender_id)) |
        ((Match.user1_id == sender_id) & (Match.user2_id == user_id)),
        Match.is_active == True
    ).first()
    
    if match:
        # Create emergency message in chat
        emergency_message = Message(
            match_id=match.id,
            sender_id="system",  # System message
            content=f"🚨 EMERGENCY ALERT: {sender_name} needs help{location_text}. Please check on them immediately!",
            message_type="emergency",
            is_read=False
        )
        
        db.add(emergency_message)
        
        # Update match last message time
        match.last_message_at = func.now()
        
        db.commit()
        
        print(f"Emergency message added to chat for match {match.id}")
    
    return True

@router.get("/test")
async def test_emergency():
    """Test endpoint for emergency system"""
    return {"message": "Emergency system is working"}