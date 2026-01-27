from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from app.core.database import get_db
from app.models.user import User
from app.api.routes.auth import get_current_user
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

class BoostRequest(BaseModel):
    duration_minutes: int = 30
    boost_type: str = "free"  # free, premium

@router.post("/boost")
async def activate_boost(
    boost_data: BoostRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Activate profile boost"""
    
    # Check if user already has active boost
    if current_user.boost_expires_at and current_user.boost_expires_at > datetime.utcnow():
        raise HTTPException(status_code=400, detail="Boost already active")
    
    # Set boost expiry
    boost_expires = datetime.utcnow() + timedelta(minutes=boost_data.duration_minutes)
    current_user.boost_expires_at = boost_expires
    current_user.boost_type = boost_data.boost_type
    
    db.commit()
    
    return {
        "message": "Boost activated successfully",
        "boost_expires_at": boost_expires,
        "duration_minutes": boost_data.duration_minutes,
        "boost_type": boost_data.boost_type
    }

@router.get("/boost/status")
async def get_boost_status(
    current_user: User = Depends(get_current_user)
):
    """Get current boost status"""
    
    is_boosted = (current_user.boost_expires_at and 
                  current_user.boost_expires_at > datetime.utcnow())
    
    return {
        "is_boosted": is_boosted,
        "boost_expires_at": current_user.boost_expires_at,
        "boost_type": current_user.boost_type,
        "minutes_remaining": (
            int((current_user.boost_expires_at - datetime.utcnow()).total_seconds() / 60)
            if is_boosted else 0
        )
    }

@router.get("/matches/sorted")
async def get_sorted_matches(
    sort_by: str = "recent",  # recent, new, active, super
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get matches sorted by specified criteria"""
    
    from app.core.database import Match
    from app.api.routes.auth import UserResponse
    
    # Get user's matches
    matches_query = db.query(Match).filter(
        (Match.user1_id == current_user.id) | (Match.user2_id == current_user.id),
        Match.is_active == True
    )
    
    # Apply sorting
    if sort_by == "recent":
        matches_query = matches_query.order_by(Match.last_message_at.desc())
    elif sort_by == "new":
        matches_query = matches_query.order_by(Match.created_at.desc())
    elif sort_by == "active":
        # Sort by recent activity (placeholder)
        matches_query = matches_query.order_by(Match.last_message_at.desc())
    elif sort_by == "super":
        # Sort super likes first (placeholder)
        matches_query = matches_query.order_by(Match.created_at.desc())
    
    matches = matches_query.all()
    
    result = []
    for match in matches:
        other_user_id = match.user2_id if match.user1_id == current_user.id else match.user1_id
        other_user = db.query(User).filter(User.id == other_user_id).first()
        
        if other_user:
            result.append({
                "id": match.id,
                "other_user": UserResponse.model_validate(other_user),
                "created_at": match.created_at,
                "last_message_at": match.last_message_at,
                "is_active": match.is_active
            })
    
    return {
        "matches": result,
        "sort_by": sort_by,
        "total_count": len(result)
    }