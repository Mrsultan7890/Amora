from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db, User, Swipe
from app.api.routes.auth import get_current_user
from pydantic import BaseModel
from typing import List
import uuid

router = APIRouter()

class SwipeRequest(BaseModel):
    swiped_user_id: str
    is_like: bool
    is_super_like: bool = False

@router.post("/")
async def create_swipe(
    swipe_data: SwipeRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Check if already swiped
    existing_swipe = db.query(Swipe).filter(
        Swipe.swiper_id == current_user.id,
        Swipe.swiped_id == swipe_data.swiped_user_id
    ).first()
    
    if existing_swipe:
        raise HTTPException(status_code=400, detail="Already swiped on this user")
    
    # Create swipe
    swipe = Swipe(
        swiper_id=current_user.id,
        swiped_id=swipe_data.swiped_user_id,
        is_like=swipe_data.is_like,
        is_super_like=swipe_data.is_super_like
    )
    
    db.add(swipe)
    db.commit()
    
    # Check for match if it's a like
    is_match = False
    if swipe_data.is_like:
        reverse_swipe = db.query(Swipe).filter(
            Swipe.swiper_id == swipe_data.swiped_user_id,
            Swipe.swiped_id == current_user.id,
            Swipe.is_like == True
        ).first()
        
        if reverse_swipe:
            is_match = True
            # Create match logic here
    
    return {"is_match": is_match, "swipe_id": swipe.id}

@router.get("/discover")
async def discover_users(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Get users that haven't been swiped on
    swiped_user_ids = db.query(Swipe.swiped_id).filter(
        Swipe.swiper_id == current_user.id
    ).subquery()
    
    users = db.query(User).filter(
        User.id != current_user.id,
        ~User.id.in_(swiped_user_ids)
    ).limit(10).all()
    
    from app.api.routes.auth import UserResponse
    return [UserResponse.model_validate(u) for u in users]