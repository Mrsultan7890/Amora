from fastapi import APIRouter

router = APIRouter()

@router.post("/image")
async def upload_image():
    return {"message": "Upload image endpoint"}

@router.delete("/image/{image_id}")
async def delete_image():
    return {"message": "Delete image endpoint"}