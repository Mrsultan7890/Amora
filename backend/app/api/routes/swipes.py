from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db, Swipe, Match
from app.models.user import User
from app.api.routes.auth import get_current_user
from pydantic import BaseModel
from typing import List
import uuid
import math

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
    
    # For testing - allow re-swiping by commenting out this check
    # if existing_swipe:
    #     raise HTTPException(status_code=400, detail="Already swiped on this user")
    
    # If already swiped, update the swipe instead
    if existing_swipe:
        existing_swipe.is_like = swipe_data.is_like
        existing_swipe.is_super_like = swipe_data.is_super_like
        db.commit()
        swipe = existing_swipe
    else:
        # Create new swipe
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
    max_distance: int = 50,  # km
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    print(f"Discover request - User: {current_user.id}, Page: {page}, Limit: {limit}, Max Distance: {max_distance}km")
    
    # Get users that haven't been swiped on
    swiped_user_ids = [row[0] for row in db.query(Swipe.swiped_id).filter(
        Swipe.swiper_id == current_user.id
    ).all()]
    
    # Base query - exclude current user and swiped users
    users_query = db.query(User).filter(
        User.id != current_user.id,
        User.is_active == True,
        User.show_me_on_amora == True  # Only show users who want to be discovered
    )
    
    # Apply incognito mode logic
    if current_user.incognito_mode:
        # In incognito mode, only show users that current user has liked
        liked_user_ids = [row[0] for row in db.query(Swipe.swiped_id).filter(
            Swipe.swiper_id == current_user.id,
            Swipe.is_like == True
        ).all()]
        
        if liked_user_ids:
            users_query = users_query.filter(User.id.in_(liked_user_ids))
        else:
            # No liked users, return empty
            return []
    else:
        # Normal mode - exclude users in incognito mode unless they liked current user
        incognito_user_ids = [row[0] for row in db.query(User.id).filter(
            User.incognito_mode == True
        ).all()]
        
        if incognito_user_ids:
            # Get incognito users who liked current user
            liked_by_incognito = [row[0] for row in db.query(Swipe.swiper_id).filter(
                Swipe.swiped_id == current_user.id,
                Swipe.is_like == True,
                Swipe.swiper_id.in_(incognito_user_ids)
            ).all()]
            
            # Exclude incognito users except those who liked current user
            exclude_incognito = [uid for uid in incognito_user_ids if uid not in liked_by_incognito]
            if exclude_incognito:
                users_query = users_query.filter(~User.id.in_(exclude_incognito))
    
    if swiped_user_ids:
        users_query = users_query.filter(~User.id.in_(swiped_user_ids))
    
    # Apply location filtering if current user has location
    if current_user.latitude and current_user.longitude:
        # Calculate distance using Haversine formula in SQL
        # This is approximate but efficient for filtering
        lat_diff = func.abs(User.latitude - current_user.latitude)
        lon_diff = func.abs(User.longitude - current_user.longitude)
        
        # Rough distance filter (1 degree ≈ 111km)
        max_lat_diff = max_distance / 111.0
        max_lon_diff = max_distance / (111.0 * func.cos(func.radians(current_user.latitude)))
        
        users_query = users_query.filter(
            User.latitude.isnot(None),
            User.longitude.isnot(None),
            lat_diff <= max_lat_diff,
            lon_diff <= max_lon_diff
        )
        
        print(f"Applied location filter: max distance {max_distance}km")
    else:
        print("No location data for current user, showing all users")
    
    # Apply pagination
    offset = (page - 1) * limit
    users = users_query.offset(offset).limit(limit).all()
    
    print(f"Retrieved {len(users)} users for page {page}")
    
    from app.api.routes.auth import UserResponse
    result = []
    
    for user in users:
        user_data = UserResponse.model_validate(user)
        
        # Add distance if both users have location
        if (current_user.latitude and current_user.longitude and 
            user.latitude and user.longitude):
            distance = calculate_distance(
                current_user.latitude, current_user.longitude,
                user.latitude, user.longitude
            )
            # Add distance to response (you might need to modify UserResponse model)
            user_dict = user_data.model_dump()
            user_dict['distance'] = round(distance, 1)
            result.append(user_dict)
        else:
            result.append(user_data.model_dump())
    
    print(f"Returning {len(result)} user profiles with location data")
    return result

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two points using Haversine formula"""
    R = 6371  # Earth's radius in kilometers
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = (math.sin(delta_lat / 2) ** 2 + 
         math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c