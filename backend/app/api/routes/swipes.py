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
            # Create match
            from app.core.database import Match
            match = Match(
                user1_id=current_user.id,
                user2_id=swipe_data.swiped_user_id
            )
            db.add(match)
            db.commit()
    
    return {"is_match": is_match, "swipe_id": swipe.id}

@router.get("/discover")
async def discover_users(
    page: int = 1,
    limit: int = 10,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    print(f"Discover request - User: {current_user.id}, Page: {page}, Limit: {limit}")
    
    # Check total users in database
    total_all_users = db.query(User).count()
    print(f"Total users in database: {total_all_users}")
    
    # Get users that haven't been swiped on
    swiped_user_ids = [row[0] for row in db.query(Swipe.swiped_id).filter(
        Swipe.swiper_id == current_user.id
    ).all()]
    
    print(f"Swiped user IDs: {swiped_user_ids}")
    
    # Get all users except current user
    users_query = db.query(User).filter(
        User.id != current_user.id
    )
    
    # For testing - comment out swipe filter temporarily
    # if swiped_user_ids:
    #     users_query = users_query.filter(~User.id.in_(swiped_user_ids))
    
    total_users = users_query.count()
    print(f"Total available users: {total_users}")
    
    # Apply pagination
    offset = (page - 1) * limit
    users = users_query.offset(offset).limit(limit).all()
    
    print(f"Retrieved {len(users)} users for page {page}")
    for user in users:
        print(f"User: {user.name} ({user.id})")
    
    from app.api.routes.auth import UserResponse
    result = [UserResponse.model_validate(u) for u in users]
    
    print(f"Returning {len(result)} user profiles")
    return result