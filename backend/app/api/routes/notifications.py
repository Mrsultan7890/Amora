from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from ...core.database import get_db
from ...models.user import User
from ...core.auth import get_current_user

router = APIRouter()

@router.get("/notifications")
async def get_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get user notifications"""
    # For now, return mock notifications
    # In production, you'd have a notifications table
    notifications = [
        {
            "id": "1",
            "type": "match",
            "title": "New Match!",
            "message": "You have a new match with Sarah",
            "timestamp": "2024-01-15T10:30:00Z",
            "read": False
        },
        {
            "id": "2", 
            "type": "message",
            "title": "New Message",
            "message": "Emma sent you a message",
            "timestamp": "2024-01-15T09:15:00Z",
            "read": False
        }
    ]
    
    return {"notifications": notifications, "unread_count": 2}

@router.put("/notifications/{notification_id}/read")
async def mark_notification_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark notification as read"""
    # In production, update notification in database
    return {"message": "Notification marked as read"}

@router.get("/notifications/unread-count")
async def get_unread_count(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get unread notifications count"""
    return {"unread_count": 2}