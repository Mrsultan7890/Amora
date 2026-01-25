from fastapi import APIRouter

router = APIRouter()

@router.post("/swipe")
async def swipe_user():
    return {"message": "Swipe endpoint"}

@router.get("/discover")
async def discover_users():
    return {"message": "Discover users endpoint"}