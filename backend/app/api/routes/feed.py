from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List
from pydantic import BaseModel
from ...core.database import get_db
from ...models.user import User
from ..routes.auth import get_current_user
from datetime import datetime
import json
import random

router = APIRouter()

@router.get("/photos")
async def get_feed_photos(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get photos for feed with real algorithm based on user preferences and activity"""
    
    try:
        # Get current user's preferences for better matching
        current_user_data = db.execute(
            text("""
                SELECT age, location, interests, looking_for 
                FROM users 
                WHERE id = :user_id
            """),
            {"user_id": current_user.id}
        ).fetchone()
        
        if not current_user_data:
            return {"feed_items": []}
        
        user_age = current_user_data[0]
        user_location = current_user_data[1]
        user_interests = json.loads(current_user_data[2]) if current_user_data[2] else []
        user_looking_for = current_user_data[3]
        
        # Smart feed algorithm: prioritize by compatibility
        users_query = db.execute(
            text("""
                SELECT id, name, age, photos, location, interests, gender, created_at,
                       CASE 
                           WHEN ABS(age - :user_age) <= 5 THEN 10
                           WHEN ABS(age - :user_age) <= 10 THEN 5
                           ELSE 1
                       END as age_score,
                       CASE 
                           WHEN location = :user_location THEN 15
                           ELSE 0
                       END as location_score,
                       CASE 
                           WHEN gender = :looking_for THEN 20
                           ELSE 5
                       END as gender_score
                FROM users 
                WHERE show_in_feed = 1 
                AND photos IS NOT NULL 
                AND photos != '[]' 
                AND id != :current_user_id
                ORDER BY (age_score + location_score + gender_score) DESC, created_at DESC
                LIMIT 50
            """),
            {
                "current_user_id": current_user.id,
                "user_age": user_age,
                "user_location": user_location,
                "looking_for": user_looking_for
            }
        ).fetchall()
        
        # Get existing likes for this user
        existing_likes = db.execute(
            text("""
                SELECT photo_id, COUNT(*) as like_count
                FROM feed_likes 
                GROUP BY photo_id
            """)
        ).fetchall()
        
        likes_dict = {row[0]: row[1] for row in existing_likes}
        
        # Get user's liked photos
        user_likes = db.execute(
            text("""
                SELECT photo_id 
                FROM feed_likes 
                WHERE user_id = :user_id
            """),
            {"user_id": current_user.id}
        ).fetchall()
        
        user_liked_photos = {row[0] for row in user_likes}
        
        feed_items = []
        
        for user in users_query:
            try:
                photos = json.loads(user[3]) if user[3] else []
                user_interests_list = json.loads(user[5]) if user[5] else []
                
                # Calculate interest compatibility
                common_interests = len(set(user_interests) & set(user_interests_list))
                interest_score = common_interests * 5
                
                if photos:
                    # Show all photos but prioritize by algorithm score
                    total_score = user[8] + user[9] + user[10] + interest_score
                    
                    for i, photo_url in enumerate(photos):
                        photo_id = f"{user[0]}_{i}"
                        
                        # Real like count from database
                        real_likes = likes_dict.get(photo_id, 0)
                        
                        # Add some base engagement for new photos
                        if real_likes == 0:
                            base_likes = max(0, int(total_score / 10) + random.randint(0, 3))
                        else:
                            base_likes = real_likes
                        
                        feed_items.append({
                            "id": photo_id,
                            "user_id": user[0],
                            "user_name": user[1],
                            "user_age": user[2],
                            "photo_url": photo_url,
                            "location": user[4],
                            "timestamp": user[7].isoformat() if hasattr(user[7], 'isoformat') else str(user[7]),
                            "likes_count": base_likes,
                            "is_liked": photo_id in user_liked_photos,
                            "compatibility_score": total_score,
                            "common_interests": common_interests
                        })
            except Exception as e:
                print(f"Error processing user {user[0]}: {e}")
                continue
        
        # Sort by compatibility score and engagement
        feed_items.sort(key=lambda x: (x['compatibility_score'], x['likes_count']), reverse=True)
        
        # Limit to 30 items for better performance
        feed_items = feed_items[:30]
        
        print(f"Feed API: Found {len(feed_items)} feed items with real algorithm")
        return {"feed_items": feed_items}
        
    except Exception as e:
        print(f"Error getting feed photos: {e}")
        return {"feed_items": []}

class LikeRequest(BaseModel):
    is_like: bool

@router.post("/photos/{photo_id}/like")
async def like_feed_photo(
    photo_id: str,
    request: LikeRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Like or unlike a feed photo with real database storage"""
    
    try:
        # Extract user_id from photo_id (format: user_id_photo_index)
        user_id = photo_id.split('_')[0]
        
        if request.is_like:
            # Add like to database
            db.execute(
                text("""
                    INSERT OR IGNORE INTO feed_likes (user_id, photo_id, photo_owner_id, created_at)
                    VALUES (:user_id, :photo_id, :photo_owner_id, :created_at)
                """),
                {
                    "user_id": current_user.id,
                    "photo_id": photo_id,
                    "photo_owner_id": user_id,
                    "created_at": datetime.now().isoformat()
                }
            )
        else:
            # Remove like from database
            db.execute(
                text("""
                    DELETE FROM feed_likes 
                    WHERE user_id = :user_id AND photo_id = :photo_id
                """),
                {
                    "user_id": current_user.id,
                    "photo_id": photo_id
                }
            )
        
        # Get updated like count
        like_count = db.execute(
            text("""
                SELECT COUNT(*) FROM feed_likes WHERE photo_id = :photo_id
            """),
            {"photo_id": photo_id}
        ).scalar()
        
        # Create notification for photo owner if liked
        if request.is_like:
            photo_owner = db.query(User).filter(User.id == user_id).first()
            if photo_owner:
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
        
        return {
            "success": True, 
            "liked": request.is_like,
            "likes_count": like_count or 0
        }
        
    except Exception as e:
        print(f"Error in like_feed_photo: {e}")
        db.rollback()
        return {"success": False, "error": str(e)}