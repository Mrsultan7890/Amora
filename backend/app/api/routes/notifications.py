from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List
from ...core.database import get_db
from ...models.user import User
from ..routes.auth import get_current_user
from datetime import datetime

router = APIRouter()

# In production, you'd have a notifications table
# For now, we'll generate notifications based on user activity

@router.get("/")
async def get_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get user notifications based on matches and messages"""
    
    try:
        # Get user's matches for match notifications
        matches_query = db.execute(
            text("SELECT * FROM matches WHERE user1_id = :user_id OR user2_id = :user_id ORDER BY created_at DESC LIMIT 5"),
            {"user_id": current_user.id}
        ).fetchall()
        
        notifications = []
        unread_count = 0
        
        # Add match notifications
        for match in matches_query:
            other_user_id = match[2] if match[1] == current_user.id else match[1]
            other_user = db.query(User).filter(User.id == other_user_id).first()
            
            if other_user:
                notifications.append({
                    "id": f"match_{match[0]}",
                    "type": "match",
                    "title": "New Match! 💕",
                    "message": f"You have a new match with {other_user.name}",
                    "timestamp": match[3].isoformat() if hasattr(match[3], 'isoformat') else str(match[3]),
                    "read": False
                })
                unread_count += 1
        
        # Add sample notifications if no matches
        if not notifications:
            notifications.extend([
                {
                    "id": "welcome_1",
                    "type": "general",
                    "title": "Welcome to Amora! 🌹",
                    "message": "Complete your profile to get more matches",
                    "timestamp": datetime.now().isoformat(),
                    "read": False
                },
                {
                    "id": "tip_1",
                    "type": "general",
                    "title": "Pro Tip 💡",
                    "message": "Add more photos to increase your match rate by 40%",
                    "timestamp": datetime.now().isoformat(),
                    "read": False
                }
            ])
            unread_count += 2
        
        return {"notifications": notifications, "unread_count": unread_count}
        
    except Exception as e:
        print(f"Error getting notifications: {e}")
        # Return empty notifications on error
        return {"notifications": [], "unread_count": 0}

@router.put("/{notification_id}/read")
async def mark_notification_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark notification as read"""
    # In production, update notification in database
    return {"message": "Notification marked as read"}

@router.get("/unread-count")
async def get_unread_count(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get unread notifications count"""
    # Get actual count from matches and messages
    matches_count = db.execute(
        text("SELECT COUNT(*) FROM matches WHERE (user1_id = :user_id OR user2_id = :user_id) AND created_at > datetime('now', '-1 day')"),
        {"user_id": current_user.id}
    ).fetchone()[0]
    
    return {"unread_count": matches_count + 1}  # +1 for sample message