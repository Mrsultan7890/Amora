from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import redis.asyncio as redis
from contextlib import asynccontextmanager
import json
from typing import Dict, List

from app.core.config import settings
from app.core.database import engine, Base
from app.api.routes import auth, users, swipes, matches, messages, upload, notifications, emergency, support, features, verification, feed, games, calls, signaling
from app.services.websocket_manager import ConnectionManager

# Create tables
try:
    Base.metadata.create_all(bind=engine)
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

@app.get("/")
async def root():
    return {"message": "Amora Dating API", "version": "1.0.0"}

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