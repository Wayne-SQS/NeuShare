from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.response import success
from app.db.session import get_db
from app.services import formcard_service

router = APIRouter(prefix="/api/form-card", tags=["form-card"])


@router.get("/current")
async def get_current_card(db: AsyncSession = Depends(get_db)):
    return success(await formcard_service.get_current(db))
