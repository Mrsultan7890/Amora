from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db, Report
from app.models.user import User
from app.api.routes.auth import get_current_user
from app.services.telegram_service import telegram_service
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

class ReportRequest(BaseModel):
    reported_user_id: str
    reason: str
    description: Optional[str] = None

class SupportRequest(BaseModel):
    subject: str
    message: str

@router.post("/report")
async def report_user(
    report_data: ReportRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Get reported user info
        reported_user = db.query(User).filter(User.id == report_data.reported_user_id).first()
        if not reported_user:
            raise HTTPException(status_code=404, detail="Reported user not found")
        
        # Save report to database
        new_report = Report(
            reporter_id=current_user.id,
            reported_id=report_data.reported_user_id,
            reason=report_data.reason,
            description=report_data.description
        )
        db.add(new_report)
        db.commit()
        
        # Send to Telegram
        telegram_service.send_report(
            reporter_name=current_user.name,
            reported_user=reported_user.name,
            reason=report_data.reason,
            description=report_data.description
        )
        
        return {"message": "Report submitted successfully"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to submit report: {str(e)}")

@router.post("/support")
async def support_request(
    support_data: SupportRequest,
    current_user: User = Depends(get_current_user)
):
    try:
        # Send to Telegram
        telegram_service.send_support_request(
            user_name=current_user.name,
            user_email=current_user.email,
            subject=support_data.subject,
            message=support_data.message
        )
        
        return {"message": "Support request sent successfully"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send support request: {str(e)}")

@router.get("/faq")
async def get_faq():
    """Get frequently asked questions"""
    faq_data = [
        {
            "question": "How do I delete my account?",
            "answer": "Go to Settings > Account > Delete Account. This action is permanent and cannot be undone."
        },
        {
            "question": "How does the matching system work?",
            "answer": "Our algorithm matches you with users based on location, age preferences, and mutual interests."
        },
        {
            "question": "What is the emergency feature?",
            "answer": "Shake your phone to send emergency alerts to your matches and emergency contacts with your location."
        },
        {
            "question": "How do I report inappropriate behavior?",
            "answer": "Tap the 3 dots on any user's profile and select 'Report User'. Choose a reason and provide details."
        },
        {
            "question": "Can I change my location?",
            "answer": "Your location updates automatically. You can control location sharing in your device settings."
        }
    ]
    
    return {"faq": faq_data}