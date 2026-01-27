from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import redis.asyncio as redis
from contextlib import asynccontextmanager
import json
from typing import Dict, List

from app.core.config import settings
from app.core.database import engine, Base
from app.api.routes import auth, users, swipes, matches, messages, upload, notifications, emergency, support
from app.services.websocket_manager import ConnectionManager

# Create tables
Base.metadata.create_all(bind=engine)

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
            
            # Broadcast message to match participants
            match_id = message_data.get("match_id")
            if match_id:
                await manager.broadcast_to_match(message_data, match_id, user_id)
                
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