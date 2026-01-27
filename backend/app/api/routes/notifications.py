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
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user notifications based on matches and messages"""
    
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
                "title": "New Match!",
                "message": f"You have a new match with {other_user.name}",
                "timestamp": match[3],  # created_at
                "read": False
            })
            unread_count += 1
    
    # Add sample message notifications
    notifications.extend([
        {
            "id": "msg_1",
            "type": "message",
            "title": "New Message",
            "message": "Someone sent you a message",
            "timestamp": datetime.now().isoformat(),
            "read": False
        }
    ])
    unread_count += 1
    
    return {"notifications": notifications, "unread_count": unread_count}

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