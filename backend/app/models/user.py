from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, Float
from sqlalchemy.sql import func
from datetime import datetime
from app.core.database import Base
import uuid

class User(Base):
    __tablename__ = "users"
    __table_args__ = {'extend_existing': True}
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    name = Column(String(100), nullable=False)
    age = Column(Integer, nullable=False)
    gender = Column(String(20), nullable=False)
    bio = Column(Text, default="")
    job = Column(String(100), default="")
    education = Column(String(100), default="")
    height = Column(Integer)
    latitude = Column(Float)
    longitude = Column(Float)
    photos = Column(Text, default="[]")
    interests = Column(Text, default="[]")
    is_verified = Column(Boolean, default=False)
    is_online = Column(Boolean, default=False)
    last_seen = Column(DateTime, default=func.now())
    is_active = Column(Boolean, default=True)
    boost_expires_at = Column(DateTime)
    boost_type = Column(String(20))
    verification_status = Column(String(20), default="unverified")  # unverified, pending, verified, rejected
    verification_requested_at = Column(DateTime)
    verification_badge_color = Column(String(10), default="blue")  # blue, pink, purple, gold
    verification_type = Column(String(20), default="basic")  # basic, donor
    profile_completion = Column(Integer, default=0)  # percentage
    show_in_feed = Column(Boolean, default=True)  # Show photos in feed
    incognito_mode = Column(Boolean, default=False)  # Only show to liked users
    show_me_on_amora = Column(Boolean, default=True)  # Discoverable in swipe
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)