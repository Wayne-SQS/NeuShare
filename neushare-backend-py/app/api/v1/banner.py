from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success
from app.db.session import get_db
from app.services import banner_service

router = APIRouter(prefix="/api/banner", tags=["banner"])


@router.get("/list")
async def list_banners(db: AsyncSession = Depends(get_db)):
    return success(await banner_service.get_active(db))
