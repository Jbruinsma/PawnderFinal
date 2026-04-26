from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select, desc
from sqlalchemy.orm import Session, defer

from app.core.security import get_current_user
from app.crud.crud_community import get_community_stats_query
from app.crud.crud_post import get_post_stats_columns
from app.database import get_db
from app.models import User, Community, Post
from app.utils.formatting_utils import format_post_with_stats, format_neighborhood_with_stats

router = APIRouter(prefix="/search")


@router.get("/all")
async def general_search(
        q: Annotated[str, Query(min_length=1)],
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    ts_query = func.plainto_tsquery('english', q)

    community_vector = func.to_tsvector(
        'english',
        Community.name + ' ' + func.coalesce(Community.description, '')
    )

    base_community_stmt = (
        select(Community)
        .where(community_vector.op('@@')(ts_query))
        .order_by(desc(func.ts_rank(community_vector, ts_query)))
        .limit(5)
    )

    community_stmt = get_community_stats_query(current_user.id, base_community_stmt)
    community_rows = session.execute(community_stmt).all()

    post_vector = func.to_tsvector('english', Post.title + ' ' + Post.description)

    post_stmt = (
        select(*get_post_stats_columns(current_user.id))
        .join(Post.author)
        .where(post_vector.op('@@')(ts_query))
        .order_by(desc(func.ts_rank(post_vector, ts_query)))
        .limit(10)
        .options(defer(Post.location))
    )
    post_rows = session.execute(post_stmt).all()

    return {
        "communities": [format_neighborhood_with_stats(row) for row in community_rows],
        "posts": [format_post_with_stats(row) for row in post_rows]
    }


@router.get("/communities")
async def community_search(
        q: Annotated[str, Query(min_length=1)],
        limit: Annotated[int, Query(ge=1, le=100)] = 20,
        offset: Annotated[int, Query(ge=0)] = 0,
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    ts_query = func.plainto_tsquery('english', q)

    community_vector = func.to_tsvector(
        'english',
        Community.name + ' ' + func.coalesce(Community.description, '')
    )

    base_community_stmt = (
        select(Community)
        .where(community_vector.op('@@')(ts_query))
        .order_by(desc(func.ts_rank(community_vector, ts_query)))
        .offset(offset)
        .limit(limit)
    )

    community_stmt = get_community_stats_query(current_user.id, base_community_stmt)
    community_rows = session.execute(community_stmt).all()

    return [format_neighborhood_with_stats(row) for row in community_rows]