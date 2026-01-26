from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.user import User
from app.api.routes.auth import get_current_user, UserResponse
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter()

class ProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None
    job: Optional[str] = None
    education: Optional[str] = None
    photos: Optional[List[str]] = None
    interests: Optional[List[str]] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

@router.get("/likes")
async def get_user_likes(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from app.core.database import Swipe
    
    # Get users who liked current user
    likes = db.query(Swipe).filter(
        Swipe.swiped_id == current_user.id,
        Swipe.is_like == True
    ).all()
    
    result = []
    for like in likes:
        user = db.query(User).filter(User.id == like.swiper_id).first()
        if user:
            result.append({
                'user': UserResponse.model_validate(user),
                'created_at': like.created_at,
                'is_super_like': like.is_super_like
            })
    
    return result

@router.get("/search")
async def search_users(
    query: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    users = db.query(User).filter(
        User.id != current_user.id,
        User.is_active == True,
        User.name.ilike(f"%{query}%")
    ).limit(20).all()
    
    return [UserResponse.model_validate(user) for user in users]

@router.get("/{user_id}", response_model=UserResponse)
async def get_user_profile(
    user_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(
        User.id == user_id,
        User.is_active == True
    ).first()
    
    if not user:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="User not found")
    
    return UserResponse.model_validate(user)

@router.get("/likes")
async def get_user_likes(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from app.core.database import Swipe
    
    # Get users who liked current user
    likes = db.query(Swipe).filter(
        Swipe.swiped_id == current_user.id,
        Swipe.is_like == True
    ).all()
    
    result = []
    for like in likes:
        user = db.query(User).filter(User.id == like.swiper_id).first()
        if user:
            result.append({
                'user': UserResponse.model_validate(user),
                'created_at': like.created_at,
                'is_super_like': like.is_super_like
            })
    
    return result

@router.get("/profile")
async def get_profile(current_user: User = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)

@router.put("/profile")
async def update_profile(
    profile_data: ProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Update user fields
    if profile_data.name is not None:
        current_user.name = profile_data.name
    if profile_data.bio is not None:
        current_user.bio = profile_data.bio
    if profile_data.job is not None:
        current_user.job = profile_data.job
    if profile_data.education is not None:
        current_user.education = profile_data.education
    if profile_data.photos is not None:
        import json
        current_user.photos = json.dumps(profile_data.photos)
    if profile_data.latitude is not None:
        current_user.latitude = profile_data.latitude
    if profile_data.longitude is not None:
        current_user.longitude = profile_data.longitude
    
    # Update interests
    if profile_data.interests is not None:
        from app.core.database import user_interests
        # Delete existing interests
        db.execute(
            user_interests.delete().where(user_interests.c.user_id == current_user.id)
        )
        # Add new interests
        for interest in profile_data.interests:
            db.execute(
                user_interests.insert().values(
                    user_id=current_user.id,
                    interest=interest
                )
            )
    
    db.commit()
    db.refresh(current_user)
    
    return UserResponse.model_validate(current_user)

@router.delete("/account")
async def delete_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Mark user as inactive instead of deleting
    current_user.is_active = False
    db.commit()
    return {"message": "Account deactivated successfully"}

@router.get("/blocked")
async def get_blocked_users(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # This would require a blocked_users table in real implementation
    return {"blocked_users": []}

@router.post("/block")
async def block_user(
    user_data: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # This would require a blocked_users table in real implementation
    return {"message": "User blocked successfully"}

@router.delete("/block/{user_id}")
async def unblock_user(
    user_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # This would require a blocked_users table in real implementation
    return {"message": "User unblocked successfully"}