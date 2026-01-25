from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db, User
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
    
    db.commit()
    db.refresh(current_user)
    
    return UserResponse.model_validate(current_user)