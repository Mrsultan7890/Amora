from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List
from pydantic import BaseModel
from ...core.database import get_db
from ...models.user import User
from ..routes.auth import get_current_user
from datetime import datetime

router = APIRouter()

@router.get("/photos")
async def get_feed_photos(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get photos for feed from users who enabled show_in_feed"""
    
    try:
        # Get users who have show_in_feed enabled and have photos
        users_query = db.execute(
            text("""
                SELECT id, name, age, photos, created_at 
                FROM users 
                WHERE show_in_feed = 1 
                AND photos IS NOT NULL 
                AND photos != '[]' 
                AND id != :current_user_id
                ORDER BY created_at DESC 
                LIMIT 20
            """),
            {"current_user_id": current_user.id}
        ).fetchall()
        
        feed_items = []
        
        for user in users_query:
            try:
                import json
                photos = json.loads(user[3]) if user[3] else []
                
                if photos:
                    # Create feed item for each photo
                    for i, photo_url in enumerate(photos[:3]):  # Max 3 photos per user
                        feed_items.append({
                            "id": f"{user[0]}_{i}",
                            "user_id": user[0],
                            "user_name": user[1],
                            "user_age": user[2],
                            "photo_url": photo_url,
                            "timestamp": user[4].isoformat() if hasattr(user[4], 'isoformat') else str(user[4]),
                            "likes_count": 5 + (i * 3),  # Mock likes for now
                            "is_liked": False
                        })
            except Exception as e:
                print(f"Error processing user {user[0]}: {e}")
                continue
        
        print(f"Feed API: Found {len(feed_items)} feed items")
        return {"feed_items": feed_items}
        
    except Exception as e:
        print(f"Error getting feed photos: {e}")
        return {"feed_items": []}

from pydantic import BaseModel

class LikeRequest(BaseModel):
    is_like: bool

@router.post("/photos/{photo_id}/like")
async def like_feed_photo(
    photo_id: str,
    request: LikeRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Like or unlike a feed photo"""
    
    try:
        # Extract user_id from photo_id (format: user_id_photo_index)
        user_id = photo_id.split('_')[0]
        
        # Get the photo owner's details
        photo_owner = db.query(User).filter(User.id == user_id).first()
        
        if photo_owner and request.is_like:
            # Create notification for photo owner
            db.execute(
                text("""
                    INSERT OR IGNORE INTO notifications (id, user_id, type, title, message, timestamp, read)
                    VALUES (:id, :user_id, :type, :title, :message, :timestamp, :read)
                """),
                {
                    "id": f"feed_like_{current_user.id}_{photo_id}_{int(datetime.now().timestamp())}",
                    "user_id": user_id,
                    "type": "feed_like",
                    "title": "Photo Liked! ❤️",
                    "message": f"{current_user.name} liked your photo",
                    "timestamp": datetime.now().isoformat(),
                    "read": False
                }
            )
            db.commit()
        
        return {"success": True, "liked": request.is_like}
        
    except Exception as e:
        print(f"Error in like_feed_photo: {e}")
        return {"success": True, "liked": request.is_like}  # Still return success even if notification fails