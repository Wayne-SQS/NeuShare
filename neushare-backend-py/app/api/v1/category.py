from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success
from app.db.session import get_db
from app.services import category_service

router = APIRouter(prefix="/api/category", tags=["category"])


@router.get("/list")
async def list_categories(db: AsyncSession = Depends(get_db)):
    return success(await category_service.list_all(db))
