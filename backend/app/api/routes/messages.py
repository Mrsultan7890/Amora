from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import uuid

from app.core.database import get_db, Match
from app.models.user import User
from app.api.routes.auth import get_current_user

router = APIRouter()

class MessageCreate(BaseModel):
    match_id: str
    content: str
    message_type: str = "text"
    image_url: Optional[str] = None

class MessageResponse(BaseModel):
    id: str
    match_id: str
    sender_id: str
    content: str
    message_type: str
    image_url: Optional[str] = None
    is_read: bool
    created_at: datetime
    sender_name: str

    class Config:
        from_attributes = True

class TypingIndicator(BaseModel):
    match_id: str
    is_typing: bool

@router.post("/", response_model=MessageResponse)
async def send_message(
    message_data: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify match exists and user is participant
    match = db.query(Match).filter(
        Match.id == message_data.match_id,
        (Match.user1_id == current_user.id) | (Match.user2_id == current_user.id),
        Match.is_active == True
    ).first()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found or you're not a participant"
        )
    
    # Create message
    from app.core.database import Message
    message = Message(
        match_id=message_data.match_id,
        sender_id=current_user.id,
        content=message_data.content,
        message_type=message_data.message_type,
        image_url=message_data.image_url
    )
    
    db.add(message)
    
    # Update match last message time
    match.last_message_at = datetime.utcnow()
    
    db.commit()
    db.refresh(message)
    
    # Prepare response
    response = MessageResponse(
        id=str(message.id),
        match_id=str(message.match_id),
        sender_id=str(message.sender_id),
        content=message.content,
        message_type=message.message_type,
        image_url=message.image_url,
        is_read=message.is_read,
        created_at=message.created_at,
        sender_name=current_user.name
    )
    
    return response

@router.get("/{match_id}", response_model=List[MessageResponse])
async def get_messages(
    match_id: str,
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify match access
    match = db.query(Match).filter(
        Match.id == match_id,
        (Match.user1_id == current_user.id) | (Match.user2_id == current_user.id)
    ).first()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    # Get messages
    from app.core.database import Message
    messages = db.query(Message).filter(
        Message.match_id == match_id
    ).order_by(
        Message.created_at.asc()
    ).offset(skip).limit(limit).all()
    
    print(f"Loading messages for match {match_id}: Found {len(messages)} messages")
    for msg in messages:
        print(f"Message: {msg.content[:50]}... Type: {msg.message_type} Sender: {msg.sender_id}")
    
    # Mark messages as read
    db.query(Message).filter(
        Message.match_id == match_id,
        Message.sender_id != current_user.id,
        Message.is_read == False
    ).update({"is_read": True})
    db.commit()
    
    result = []
    for msg in messages:
        # Handle system messages
        if msg.sender_id == "system":
            sender_name = "System"
        else:
            # Get sender user
            sender = db.query(User).filter(User.id == msg.sender_id).first()
            sender_name = sender.name if sender else "Unknown"
        
        result.append(MessageResponse(
            id=str(msg.id),
            match_id=str(msg.match_id),
            sender_id=str(msg.sender_id),
            content=msg.content,
            message_type=msg.message_type,
            image_url=msg.image_url,
            is_read=msg.is_read,
            created_at=msg.created_at,
            sender_name=sender_name
        ))
    
    return result

@router.post("/{match_id}/typing")
async def send_typing_indicator(
    match_id: str,
    typing_data: TypingIndicator,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify match access
    match = db.query(Match).filter(
        Match.id == match_id,
        (Match.user1_id == current_user.id) | (Match.user2_id == current_user.id)
    ).first()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    # Here you would send typing indicator via WebSocket
    # This is handled by the WebSocket manager
    
    return {"status": "typing indicator sent"}

@router.put("/{message_id}/read")
async def mark_message_read(
    message_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from app.core.database import Message
    message = db.query(Message).filter(Message.id == message_id).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    # Verify user is recipient
    match = db.query(Match).filter(Match.id == message.match_id).first()
    if not match or (match.user1_id != current_user.id and match.user2_id != current_user.id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized"
        )
    
    message.is_read = True
    db.commit()
    
    return {"status": "message marked as read"}

@router.get("/{match_id}/unread-count")
async def get_unread_count(
    match_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # Verify match access
    match = db.query(Match).filter(
        Match.id == match_id,
        (Match.user1_id == current_user.id) | (Match.user2_id == current_user.id)
    ).first()
    
    if not match:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Match not found"
        )
    
    from app.core.database import Message
    unread_count = db.query(Message).filter(
        Message.match_id == match_id,
        Message.sender_id != current_user.id,
        Message.is_read == False
    ).count()
    
    return {"unread_count": unread_count}