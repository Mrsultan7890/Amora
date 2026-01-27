from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from pydantic import BaseModel
from typing import Optional
import json

from app.core.database import get_db
from app.models.user import User
from app.api.routes.auth import get_current_user
from app.core.telegram_admin import send_verification_request

router = APIRouter()

class VerificationRequest(BaseModel):
    badge_color: str  # blue, pink, purple
    
class VerificationResponse(BaseModel):
    eligible: bool
    message: str
    requirements: dict
    
class VerificationStatus(BaseModel):
    status: str
    badge_color: Optional[str] = None
    verification_type: Optional[str] = None
    requested_at: Optional[datetime] = None

def calculate_profile_completion(user: User) -> int:
    """Calculate profile completion percentage"""
    completion = 0
    
    # Basic info (40%)
    if user.name: completion += 10
    if user.age: completion += 10
    if user.gender: completion += 10
    if user.bio and len(user.bio) >= 20: completion += 10
    
    # Photos (30%)
    try:
        photos = json.loads(user.photos) if user.photos else []
        if len(photos) >= 1: completion += 10
        if len(photos) >= 2: completion += 10
        if len(photos) >= 3: completion += 10
    except:
        pass
    
    # Additional info (30%)
    if user.job: completion += 10
    if user.education: completion += 10
    if user.height: completion += 10
    
    return completion

def check_eligibility(user: User, db: Session) -> dict:
    """Check if user is eligible for verification"""
    requirements = {
        "profile_complete": False,
        "min_photos": False,
        "bio_length": False,
        "account_age": False,
        "no_reports": False,
        "job_education": False
    }
    
    # Profile completion
    completion = calculate_profile_completion(user)
    requirements["profile_complete"] = completion >= 80
    
    # Photos check
    try:
        photos = json.loads(user.photos) if user.photos else []
        requirements["min_photos"] = len(photos) >= 3
    except:
        requirements["min_photos"] = False
    
    # Bio length
    requirements["bio_length"] = user.bio and len(user.bio) >= 20
    
    # Account age (15 days)
    account_age = (datetime.utcnow() - user.created_at).days
    requirements["account_age"] = account_age >= 15
    
    # Job and education
    requirements["job_education"] = bool(user.job and user.education)
    
    # No reports check (placeholder - implement based on your reports system)
    requirements["no_reports"] = True
    
    eligible = all(requirements.values())
    
    return {
        "eligible": eligible,
        "requirements": requirements,
        "completion_percentage": completion,
        "account_age_days": account_age
    }

@router.get("/check-eligibility", response_model=VerificationResponse)
async def check_verification_eligibility(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Check if user is eligible for verification"""
    
    # Update profile completion
    completion = calculate_profile_completion(current_user)
    current_user.profile_completion = completion
    db.commit()
    
    eligibility = check_eligibility(current_user, db)
    
    if eligibility["eligible"]:
        message = "🎉 Congratulations! You're eligible for verification."
    else:
        missing = []
        reqs = eligibility["requirements"]
        
        if not reqs["profile_complete"]:
            missing.append(f"Complete your profile ({eligibility['completion_percentage']}% done)")
        if not reqs["min_photos"]:
            missing.append("Add at least 3 photos")
        if not reqs["bio_length"]:
            missing.append("Write a bio (minimum 20 characters)")
        if not reqs["account_age"]:
            missing.append(f"Account must be 15+ days old (currently {eligibility['account_age_days']} days)")
        if not reqs["job_education"]:
            missing.append("Add job and education information")
            
        message = "Complete these requirements: " + ", ".join(missing)
    
    return VerificationResponse(
        eligible=eligibility["eligible"],
        message=message,
        requirements=eligibility["requirements"]
    )

@router.post("/request")
async def request_verification(
    request: VerificationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Submit verification request"""
    
    # Check if already verified or pending
    if current_user.verification_status in ["verified", "pending"]:
        raise HTTPException(
            status_code=400,
            detail=f"Verification already {current_user.verification_status}"
        )
    
    # Check eligibility
    eligibility = check_eligibility(current_user, db)
    if not eligibility["eligible"]:
        raise HTTPException(
            status_code=400,
            detail="Not eligible for verification. Check requirements."
        )
    
    # Validate badge color
    valid_colors = ["blue", "pink", "purple"]
    if request.badge_color not in valid_colors:
        raise HTTPException(
            status_code=400,
            detail="Invalid badge color. Choose: blue, pink, purple"
        )
    
    # Update verification status
    current_user.verification_status = "pending"
    current_user.verification_requested_at = datetime.utcnow()
    current_user.verification_badge_color = request.badge_color
    current_user.verification_type = "basic"
    
    db.commit()
    
    # Send to Telegram admin bot
    try:
        await send_verification_request(current_user)
    except Exception as e:
        print(f"Failed to send Telegram notification: {e}")
    
    return {
        "message": "Verification request submitted! You'll receive a response within 3 days.",
        "status": "pending",
        "badge_color": request.badge_color
    }

@router.get("/status", response_model=VerificationStatus)
async def get_verification_status(
    current_user: User = Depends(get_current_user)
):
    """Get current verification status"""
    return VerificationStatus(
        status=current_user.verification_status,
        badge_color=current_user.verification_badge_color,
        verification_type=current_user.verification_type,
        requested_at=current_user.verification_requested_at
    )

@router.post("/approve/{user_id}")
async def approve_verification(
    user_id: str,
    db: Session = Depends(get_db)
):
    """Admin endpoint to approve verification"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.verification_status = "verified"
    user.is_verified = True
    db.commit()
    
    return {"message": "User verified successfully"}

@router.post("/reject/{user_id}")
async def reject_verification(
    user_id: str,
    reason: str = "Requirements not met",
    db: Session = Depends(get_db)
):
    """Admin endpoint to reject verification"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.verification_status = "rejected"
    user.verification_requested_at = None
    db.commit()
    
    return {"message": f"Verification rejected: {reason}"}

@router.get("/pending")
async def get_pending_verifications(db: Session = Depends(get_db)):
    """Admin endpoint to get pending verifications"""
    pending_users = db.query(User).filter(
        User.verification_status == "pending"
    ).all()
    
    return [
        {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "age": user.age,
            "gender": user.gender,
            "bio": user.bio,
            "job": user.job,
            "education": user.education,
            "photos": json.loads(user.photos) if user.photos else [],
            "badge_color": user.verification_badge_color,
            "requested_at": user.verification_requested_at,
            "profile_completion": user.profile_completion
        }
        for user in pending_users
    ]