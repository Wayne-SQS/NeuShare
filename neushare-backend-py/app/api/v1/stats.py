from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success
from app.db.session import get_db
from app.services import stats_service

router = APIRouter(prefix="/api/stats", tags=["stats"])


@router.get("/overview")
async def overview(db: AsyncSession = Depends(get_db)):
    return success(await stats_service.get_overview(db))
