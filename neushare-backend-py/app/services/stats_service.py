"""Stats overview — mirrors StatsServiceImpl.doGetOverview exactly.

All counts/distributions/top10 derive from the published resource set (status=1),
matching the Java logic. Cached for 5 min (Redis-degraded when unavailable).
"""
from datetime import datetime, timedelta

from sqlalchemy import text

from app.cache.decorator import cached


def _dist_item(name, count) -> dict:
    return {"name": name, "count": count}


def _top_item(row) -> dict:
    return {
        "id": row["id"],
        "title": row["title"],
        "type": row["type"],
        "viewCount": row["view_count"],
        "likeCount": row["like_count"],
        "favoriteCount": row["favorite_count"],
    }


@cached(key="stats:overview", ttl=300)
async def get_overview(db) -> dict:
    # ---- base counts ----
    total_resources = (await db.execute(text("SELECT COUNT(*) FROM resource WHERE status = 1"))).scalar() or 0
    total_users = (await db.execute(text("SELECT COUNT(*) FROM user"))).scalar() or 0
    total_comments = (await db.execute(text("SELECT COUNT(*) FROM comment WHERE deleted = 0"))).scalar() or 0
    pending = (await db.execute(text("SELECT COUNT(*) FROM resource WHERE status = 0"))).scalar() or 0

    # sums from published resource rows (Java uses these for totalViews/Likes/Favorites)
    sums = (await db.execute(text(
        "SELECT COALESCE(SUM(view_count),0) AS v, COALESCE(SUM(like_count),0) AS l, "
        "COALESCE(SUM(favorite_count),0) AS f FROM resource WHERE status = 1"
    ))).mappings().first()
    total_views = int(sums["v"])
    total_likes = int(sums["l"])
    total_favorites = int(sums["f"])

    # ---- category distribution (unknown category id -> "未知分类") ----
    cat_rows = (await db.execute(text(
        "SELECT r.category_id AS cid, c.name AS cname, COUNT(*) AS cnt "
        "FROM resource r LEFT JOIN category c ON r.category_id = c.id "
        "WHERE r.status = 1 AND r.category_id IS NOT NULL "
        "GROUP BY r.category_id, c.name ORDER BY cnt DESC, c.name ASC"
    ))).mappings().all()
    category_distribution = [
        _dist_item(r["cname"] if r["cname"] else "未知分类", int(r["cnt"])) for r in cat_rows
    ]

    # ---- type distribution ----
    type_rows = (await db.execute(text(
        "SELECT type, COUNT(*) AS cnt FROM resource WHERE status = 1 AND type IS NOT NULL "
        "GROUP BY type ORDER BY cnt DESC, type ASC"
    ))).mappings().all()
    type_distribution = [_dist_item(r["type"], int(r["cnt"])) for r in type_rows]

    # ---- source distribution (exclude empty source) ----
    src_rows = (await db.execute(text(
        "SELECT source, COUNT(*) AS cnt FROM resource "
        "WHERE status = 1 AND source IS NOT NULL AND source <> '' "
        "GROUP BY source ORDER BY cnt DESC, source ASC"
    ))).mappings().all()
    source_distribution = [_dist_item(r["source"], int(r["cnt"])) for r in src_rows]

    # ---- top 10 by hot score: view + like*2 + favorite*3 ----
    top_rows = (await db.execute(text(
        "SELECT id, title, type, view_count, like_count, favorite_count FROM resource "
        "WHERE status = 1 ORDER BY (COALESCE(view_count,0) + COALESCE(like_count,0)*2 + "
        "COALESCE(favorite_count,0)*3) DESC, id ASC LIMIT 10"
    ))).mappings().all()
    top_resources = [_top_item(dict(r)) for r in top_rows]

    # ---- recent uploads (last 7 days) ----
    seven_days_ago = datetime.now() - timedelta(days=7)
    recent = (await db.execute(
        text("SELECT COUNT(*) FROM resource WHERE status = 1 AND create_time > :ago"),
        {"ago": seven_days_ago},
    )).scalar() or 0

    return {
        "totalResources": int(total_resources),
        "totalUsers": int(total_users),
        "totalComments": int(total_comments),
        "totalFavorites": total_favorites,
        "totalLikes": total_likes,
        "totalViews": total_views,
        "pendingResources": int(pending),
        "categoryDistribution": category_distribution,
        "typeDistribution": type_distribution,
        "sourceDistribution": source_distribution,
        "topResources": top_resources,
        "recentUploads": int(recent),
    }


async def get_admin_statistics(db) -> dict:
    """管理端概览 — mirrors AdminController.getStatistics（4 个计数，无缓存）。"""
    row = (await db.execute(text(
        "SELECT (SELECT COUNT(*) FROM user) AS user_count, "
        "(SELECT COUNT(*) FROM resource) AS resource_count, "
        "(SELECT COUNT(*) FROM comment) AS comment_count, "
        "(SELECT COUNT(*) FROM resource WHERE status = 0) AS pending_resource_count"
    ))).mappings().first()
    return {
        "userCount": int(row["user_count"]),
        "resourceCount": int(row["resource_count"]),
        "commentCount": int(row["comment_count"]),
        "pendingResourceCount": int(row["pending_resource_count"]),
    }
