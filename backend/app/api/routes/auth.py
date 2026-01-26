from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from jose import JWTError, jwt
import hashlib
from pydantic import BaseModel, EmailStr
from typing import Optional

from app.core.database import get_db
from app.models.user import User
from app.core.config import settings

router = APIRouter()

# Security
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return hashlib.sha256(plain_password.encode()).hexdigest() == hashed_password

def get_password_hash(password: str) -> str:
    return hashlib.sha256(password.encode()).hexdigest()

# Pydantic models
class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str
    age: int
    gender: str
    interests: list[str] = []

class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    age: int
    gender: str
    bio: str = ""
    job: Optional[str] = None
    education: Optional[str] = None
    photos: list[str] = []
    interests: list[str] = []
    is_verified: bool
    is_online: bool
    created_at: datetime
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    class Config:
        from_attributes = True
    
    @classmethod
    def model_validate(cls, user):
        import json
        photos = []
        interests = []
        
        try:
            if user.photos:
                if isinstance(user.photos, str):
                    photos = json.loads(user.photos)
                else:
                    photos = user.photos
        except Exception as e:
            print(f"Error parsing photos: {e}")
            photos = []
            
        # Get interests from database
        try:
            from app.core.database import SessionLocal, user_interests
            db = SessionLocal()
            interest_rows = db.execute(
                user_interests.select().where(user_interests.c.user_id == user.id)
            ).fetchall()
            interests = [row.interest for row in interest_rows]
            db.close()
        except Exception as e:
            print(f"Error loading interests: {e}")
            interests = []
        
        return cls(
            id=user.id,
            email=user.email,
            name=user.name,
            age=user.age,
            gender=user.gender,
            bio=user.bio or "",
            job=user.job,
            education=user.education,
            photos=photos,
            interests=interests,
            is_verified=user.is_verified,
            is_online=user.is_online,
            created_at=user.created_at,
            latitude=user.latitude,
            longitude=user.longitude
        )

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    return user

# Routes
@router.post("/register", response_model=Token)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    try:
        print(f"Registration attempt for: {user_data.email}")
        
        # Check if user exists
        db_user = db.query(User).filter(User.email == user_data.email).first()
        if db_user:
            print(f"User already exists: {user_data.email}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        # Create new user
        hashed_password = get_password_hash(user_data.password)
        print(f"Creating user with hashed password")
        
        db_user = User(
            email=user_data.email,
            hashed_password=hashed_password,
            name=user_data.name,
            age=user_data.age,
            gender=user_data.gender,
            is_online=True
        )
        
        print(f"Adding user to database")
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        print(f"User created successfully: {db_user.id}")
        
        # Add interests
        if user_data.interests:
            from app.core.database import user_interests
            for interest in user_data.interests:
                db.execute(
                    user_interests.insert().values(
                        user_id=db_user.id,
                        interest=interest
                    )
                )
            db.commit()
        
        # Create access token
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(db_user.id)}, expires_delta=access_token_expires
        )
        
        print(f"Token created, returning response")
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": UserResponse.model_validate(db_user)
        }
    except Exception as e:
        print(f"Registration error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    user.is_online = True
    user.last_seen = datetime.utcnow()
    db.commit()
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": UserResponse.model_validate(user)
    }

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: User = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)

@router.post("/logout")
async def logout(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    current_user.is_online = False
    current_user.last_seen = datetime.utcnow()
    db.commit()
    return {"message": "Successfully logged out"}