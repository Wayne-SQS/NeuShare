from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.utils.common import to_entity_dict

_LIST_SQL = text("SELECT id, name, parent_id, sort, create_time FROM category ORDER BY sort ASC")


async def list_all(db: AsyncSession) -> list:
    res = await db.execute(_LIST_SQL)
    return [to_entity_dict(dict(r)) for r in res.mappings().all()]
