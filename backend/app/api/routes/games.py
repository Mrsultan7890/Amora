from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Dict, Any
from ...core.database import get_db
from ...models.user import User
from ..routes.auth import get_current_user
from datetime import datetime
import json
import uuid

router = APIRouter()

# In-memory storage for game rooms (in production, use Redis or database)
game_rooms: Dict[str, Dict[str, Any]] = {}

@router.post("/rooms/create")
async def create_game_room(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new game room"""
    
    try:
        room_id = str(uuid.uuid4())[:8]  # Short room ID
        
        room_data = {
            "id": room_id,
            "creator_id": current_user.id,
            "players": [
                {
                    "id": current_user.id,
                    "name": current_user.name,
                    "avatar": current_user.photos[0] if current_user.photos else None,
                    "is_connected": True,
                    "is_muted": False
                }
            ],
            "state": "waiting",
            "current_question": None,
            "selected_player": None,
            "round": 1,
            "created_at": datetime.now().isoformat()
        }
        
        game_rooms[room_id] = room_data
        
        return {
            "room_id": room_id,
            "players": room_data["players"],
            "state": room_data["state"]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create room: {str(e)}")

@router.post("/rooms/{room_id}/join")
async def join_game_room(
    room_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Join an existing game room"""
    
    try:
        if room_id not in game_rooms:
            raise HTTPException(status_code=404, detail="Room not found")
        
        room = game_rooms[room_id]
        
        # Check if user already in room
        if any(p["id"] == current_user.id for p in room["players"]):
            return {
                "players": room["players"],
                "state": room["state"]
            }
        
        # Check room capacity (max 4 players)
        if len(room["players"]) >= 4:
            raise HTTPException(status_code=400, detail="Room is full")
        
        # Add player to room
        new_player = {
            "id": current_user.id,
            "name": current_user.name,
            "avatar": current_user.photos[0] if current_user.photos else None,
            "is_connected": True,
            "is_muted": False
        }
        
        room["players"].append(new_player)
        
        return {
            "players": room["players"],
            "state": room["state"]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to join room: {str(e)}")

@router.post("/rooms/{room_id}/leave")
async def leave_game_room(
    room_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Leave a game room"""
    
    try:
        if room_id not in game_rooms:
            return {"success": True}
        
        room = game_rooms[room_id]
        
        # Remove player from room
        room["players"] = [p for p in room["players"] if p["id"] != current_user.id]
        
        # Delete room if empty
        if not room["players"]:
            del game_rooms[room_id]
        
        return {"success": True}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to leave room: {str(e)}")

@router.put("/rooms/{room_id}/state")
async def update_game_state(
    room_id: str,
    state_data: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update game room state"""
    
    try:
        if room_id not in game_rooms:
            raise HTTPException(status_code=404, detail="Room not found")
        
        room = game_rooms[room_id]
        
        # Update room state
        if "state" in state_data:
            room["state"] = state_data["state"]
        
        if "selected_player" in state_data:
            room["selected_player"] = state_data["selected_player"]
        
        if "question" in state_data:
            room["current_question"] = state_data["question"]
        
        if "round" in state_data:
            room["round"] = state_data["round"]
        
        return {"success": True}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update state: {str(e)}")

@router.get("/rooms/{room_id}")
async def get_game_room(
    room_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get game room details"""
    
    try:
        if room_id not in game_rooms:
            raise HTTPException(status_code=404, detail="Room not found")
        
        room = game_rooms[room_id]
        
        return {
            "id": room["id"],
            "players": room["players"],
            "state": room["state"],
            "current_question": room.get("current_question"),
            "selected_player": room.get("selected_player"),
            "round": room.get("round", 1)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get room: {str(e)}")