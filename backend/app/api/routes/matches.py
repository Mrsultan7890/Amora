from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db, Match, Swipe
from app.models.user import User
from app.api.routes.auth import get_current_user, UserResponse
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import json

router = APIRouter()

class MatchResponse(BaseModel):
    id: str
    user1_id: str
    user2_id: str
    is_active: bool
    created_at: datetime
    last_message_at: datetime
    last_message: str = None
    other_user: UserResponse

@router.get("/", response_model=List[MatchResponse])
async def get_matches(
    search: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    matches_query = db.query(Match).filter(
        ((Match.user1_id == current_user.id) | (Match.user2_id == current_user.id)),
        Match.is_active == True
    )
    
    matches = matches_query.order_by(Match.last_message_at.desc()).all()
    
    result = []
    for match in matches:
        # Get other user
        other_user_id = match.user2_id if match.user1_id == current_user.id else match.user1_id
        other_user = db.query(User).filter(User.id == other_user_id).first()
        
        if other_user:
            # Apply search filter if provided
            if search and search.lower() not in other_user.name.lower():
                continue
                
            result.append(MatchResponse(
                id=match.id,
                user1_id=match.user1_id,
                user2_id=match.user2_id,
                is_active=match.is_active,
                created_at=match.created_at,
                last_message_at=match.last_message_at,
                other_user=UserResponse.model_validate(other_user)
            ))
    
    return result

@router.get("/{match_id}", response_model=MatchResponse)
async def get_match(
    match_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    match = db.query(Match).filter(
        Match.id == match_id,
        ((Match.user1_id == current_user.id) | (Match.user2_id == current_user.id))
    ).first()
    
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    
    # Get other user
    other_user_id = match.user2_id if match.user1_id == current_user.id else match.user1_id
    other_user = db.query(User).filter(User.id == other_user_id).first()
    
    return MatchResponse(
        id=match.id,
        user1_id=match.user1_id,
        user2_id=match.user2_id,
        is_active=match.is_active,
        created_at=match.created_at,
        last_message_at=match.last_message_at,
        other_user=UserResponse.model_validate(other_user)
    )