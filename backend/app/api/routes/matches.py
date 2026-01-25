from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_matches():
    return {"message": "Get matches endpoint"}

@router.get("/{match_id}")
async def get_match():
    return {"message": "Get specific match endpoint"}