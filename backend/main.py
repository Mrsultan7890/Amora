from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, HTMLResponse
import redis.asyncio as redis
from contextlib import asynccontextmanager
import json
from typing import Dict, List
from datetime import datetime

from app.core.config import settings
from app.core.database import engine, Base
from app.api.routes import auth, users, swipes, matches, messages, upload, notifications, emergency, support, features, verification, feed, games, calls, signaling, boost
from app.services.websocket_manager import ConnectionManager

# Create tables
try:
    from sqlalchemy import text
    Base.metadata.create_all(bind=engine)
    
    # Create feed_likes table for real like system
    with engine.connect() as conn:
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS feed_likes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id TEXT NOT NULL,
                photo_id TEXT NOT NULL,
                photo_owner_id TEXT NOT NULL,
                created_at TEXT NOT NULL,
                UNIQUE(user_id, photo_id)
            )
        """))
        
        # Update existing users with sample interests (column already exists)
        try:
            conn.execute(text("""
                UPDATE users SET interests = 
                CASE 
                    WHEN name = 'shadow' THEN '["Gaming", "Technology", "Music"]'
                    WHEN name = 'Amora' THEN '["Travel", "Photography", "Art"]'
                    WHEN name = 'arpita' THEN '["Dancing", "Movies", "Fashion"]'
                    WHEN name = 'waishali' THEN '["Reading", "Cooking", "Nature"]'
                    ELSE '["Travel", "Music", "Movies"]'
                END
                WHERE interests IS NULL OR interests = '[]' OR interests = ''
            """))
            print("✅ Updated existing users with realistic interests")
        except Exception as e:
            print(f"Error updating interests: {e}")
        
        # Add incognito mode and show_me_on_amora columns if they don't exist
        try:
            conn.execute(text("""
                ALTER TABLE users ADD COLUMN incognito_mode BOOLEAN DEFAULT FALSE
            """))
            print("✅ Added incognito_mode column")
        except Exception as e:
            print(f"incognito_mode column already exists: {e}")
            
        try:
            conn.execute(text("""
                ALTER TABLE users ADD COLUMN show_me_on_amora BOOLEAN DEFAULT TRUE
            """))
            print("✅ Added show_me_on_amora column")
        except Exception as e:
            print(f"show_me_on_amora column already exists: {e}")
        
        conn.commit()
        print("✅ Feed likes table created successfully")
        
except Exception as e:
    print(f"Database tables already exist or error: {e}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    app.state.redis = redis.from_url(settings.REDIS_URL)
    app.state.connection_manager = ConnectionManager()
    yield
    # Shutdown
    await app.state.redis.close()

app = FastAPI(
    title="Amora Dating API",
    description="Modern dating app backend with real-time features",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Routes
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(swipes.router, prefix="/api/swipes", tags=["Swipes"])
app.include_router(matches.router, prefix="/api/matches", tags=["Matches"])
app.include_router(messages.router, prefix="/api/messages", tags=["Messages"])
app.include_router(upload.router, prefix="/api/upload", tags=["Upload"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["Notifications"])
app.include_router(emergency.router, prefix="/api/emergency", tags=["Emergency"])
app.include_router(support.router, prefix="/api/support", tags=["Support"])
app.include_router(features.router, prefix="/api/features", tags=["Features"])
app.include_router(verification.router, prefix="/api/verification", tags=["Verification"])
app.include_router(feed.router, prefix="/api/feed", tags=["Feed"])
app.include_router(games.router, prefix="/api/games", tags=["Games"])
app.include_router(calls.router, prefix="/api/calls", tags=["Calls"])
app.include_router(signaling.router, prefix="/api/calls", tags=["Signaling"])
app.include_router(boost.router, prefix="/api/boost", tags=["Boost"])

@app.get("/")
async def root():
    return FileResponse("static/index.html")

@app.get("/privacy")
async def privacy_policy():
    return FileResponse("static/privacy.html")

@app.get("/terms")
async def terms_of_service():
    return FileResponse("static/terms.html")

@app.get("/api/download/apk")
async def download_apk():
    # GitHub release link - update this with your actual release URL
    github_release_url = "https://github.com/yourusername/amora/releases/download/v1.0/amora.apk"
    
    # Track download
    try:
        # Log download attempt
        print(f"APK download requested at {datetime.now()}")
    except:
        pass
    
    # For now, return info page since APK not ready
    return HTMLResponse("""
    <html>
        <head>
            <title>Download Amora APK</title>
            <style>
                body { 
                    font-family: 'Poppins', sans-serif; 
                    background: linear-gradient(135deg, #E91E63 0%, #9C27B0 100%);
                    color: white;
                    text-align: center;
                    padding: 2rem;
                }
                .container {
                    max-width: 600px;
                    margin: 0 auto;
                    background: rgba(255,255,255,0.1);
                    padding: 2rem;
                    border-radius: 20px;
                    backdrop-filter: blur(10px);
                }
                .btn {
                    background: linear-gradient(45deg, #E91E63, #9C27B0);
                    color: white;
                    padding: 15px 30px;
                    border: none;
                    border-radius: 25px;
                    text-decoration: none;
                    display: inline-block;
                    margin: 1rem;
                    font-weight: bold;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📱 Amora APK Download</h1>
                <p>The APK will be available soon!</p>
                <p>We're preparing the final build for you.</p>
                
                <h3>📋 Installation Instructions:</h3>
                <ol style="text-align: left; max-width: 400px; margin: 0 auto;">
                    <li>Enable "Unknown Sources" in Android Settings</li>
                    <li>Download the APK file</li>
                    <li>Tap the downloaded file to install</li>
                    <li>Open Amora and create your account</li>
                </ol>
                
                <a href="/" class="btn">← Back to Home</a>
                <a href="#" class="btn" onclick="alert('APK will be available soon!')">📥 Download APK</a>
            </div>
        </body>
    </html>
    """)

@app.post("/api/analytics/download")
async def track_download():
    # Track download analytics
    print(f"Download tracked at {datetime.now()}")
    return {"status": "tracked"}

@app.get("/api/release/latest")
async def get_latest_release():
    """Get latest release info from GitHub"""
    return {
        "version": "1.0.0",
        "download_url": "https://github.com/yourusername/amora/releases/download/v1.0/amora-v1.0.apk",
        "size": "25 MB",
        "release_notes": "Initial release with all core features"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# WebSocket for real-time chat
@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    manager = app.state.connection_manager
    await manager.connect(websocket, user_id)
    
    try:
        while True:
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            message_type = message_data.get("type")
            
            if message_type == "new_message":
                # Chat message
                match_id = message_data.get("match_id")
                if match_id:
                    await manager.broadcast_to_match(message_data, match_id, user_id)
            
            elif message_type == "signaling":
                # WebRTC signaling
                signaling_data = message_data.get("data", {})
                target_user = signaling_data.get("to")
                if target_user:
                    signaling_data["from"] = user_id
                    await manager.send_personal_message(
                        json.dumps(signaling_data), 
                        target_user
                    )
            
            elif message_type == "game_update":
                # Game state update
                room_id = message_data.get("room_id")
                game_data = message_data.get("data", {})
                if room_id:
                    await manager.send_game_update(room_id, game_data)
            
            elif message_type == "voice_chat_signal":
                # Voice chat signaling for games
                room_id = message_data.get("room_id")
                signal_data = message_data.get("data", {})
                if room_id:
                    await manager.send_voice_chat_signal(room_id, signal_data, user_id)
                
    except WebSocketDisconnect:
        manager.disconnect(user_id)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level="debug"
    )