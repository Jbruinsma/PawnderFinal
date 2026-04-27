from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select, desc, or_
from sqlalchemy.orm import Session, defer

from app.core.security import get_current_user
from app.crud.crud_community import get_community_stats_query
from app.crud.crud_post import get_post_stats_columns
from app.core.database import get_db
from app.models import User, Community, Post, Tag
from app.utils.formatting_utils import format_post_with_stats, format_neighborhood_with_stats

router = APIRouter(prefix="/search")

SIMILARITY_THRESHOLD = 0.15


def _community_search_clauses(q: str):
    name_vector = func.setweight(
        func.to_tsvector('english', Community.name), 'A'
    )
    description_vector = func.setweight(
        func.to_tsvector('english', func.coalesce(Community.description, '')), 'B'
    )
    community_vector = name_vector.op('||')(description_vector)
    ts_query = func.websearch_to_tsquery('english', q)

    name_similarity = func.similarity(Community.name, q)
    description_similarity = func.word_similarity(
        q, func.coalesce(Community.description, '')
    )

    fts_match = community_vector.op('@@')(ts_query)
    trigram_match = or_(
        name_similarity > SIMILARITY_THRESHOLD,
        description_similarity > SIMILARITY_THRESHOLD,
    )

    rank = (
            func.ts_rank_cd(community_vector, ts_query)
            + name_similarity * 2.0
            + description_similarity
    )

    return fts_match, trigram_match, rank


def _post_search_clauses(q: str):
    title_vector = func.setweight(
        func.to_tsvector('english', Post.title), 'A'
    )
    description_vector = func.setweight(
        func.to_tsvector('english', func.coalesce(Post.description, '')), 'B'
    )
    post_vector = title_vector.op('||')(description_vector)
    ts_query = func.websearch_to_tsquery('english', q)

    title_similarity = func.similarity(Post.title, q)
    description_similarity = func.word_similarity(
        q, func.coalesce(Post.description, '')
    )

    fts_match = post_vector.op('@@')(ts_query)
    trigram_match = or_(
        title_similarity > SIMILARITY_THRESHOLD,
        description_similarity > SIMILARITY_THRESHOLD,
    )

    rank = (
            func.ts_rank_cd(post_vector, ts_query)
            + title_similarity * 2.0
            + description_similarity
    )

    return fts_match, trigram_match, rank


def _tag_search_clauses(q: str):
    name_vector = func.setweight(
        func.to_tsvector('english', Tag.name), 'A'
    )
    category_vector = func.setweight(
        func.to_tsvector('english', Tag.category), 'B'
    )
    tag_vector = name_vector.op('||')(category_vector)
    ts_query = func.websearch_to_tsquery('english', q)

    name_similarity = func.similarity(Tag.name, q)
    category_similarity = func.similarity(Tag.category, q)

    fts_match = tag_vector.op('@@')(ts_query)
    trigram_match = or_(
        name_similarity > SIMILARITY_THRESHOLD,
        category_similarity > SIMILARITY_THRESHOLD,
    )

    rank = (
            func.ts_rank_cd(tag_vector, ts_query)
            + name_similarity * 2.0
            + category_similarity
    )

    return fts_match, trigram_match, rank


@router.get("/all")
async def general_search(
        q: Annotated[str, Query(min_length=1)],
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    c_fts, c_trgm, c_rank = _community_search_clauses(q)

    base_community_stmt = (
        select(Community)
        .where(or_(c_fts, c_trgm))
        .order_by(desc(c_rank))
        .limit(5)
    )

    community_stmt = get_community_stats_query(current_user.id, base_community_stmt)
    community_rows = session.execute(community_stmt).all()

    p_fts, p_trgm, p_rank = _post_search_clauses(q)

    post_stmt = (
        select(*get_post_stats_columns(current_user.id))
        .join(Post.author)
        .where(or_(p_fts, p_trgm))
        .order_by(desc(p_rank))
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
    c_fts, c_trgm, c_rank = _community_search_clauses(q)

    base_community_stmt = (
        select(Community)
        .where(or_(c_fts, c_trgm))
        .order_by(desc(c_rank))
        .offset(offset)
        .limit(limit)
    )

    community_stmt = get_community_stats_query(current_user.id, base_community_stmt)
    community_rows = session.execute(community_stmt).all()

    return [format_neighborhood_with_stats(row) for row in community_rows]


@router.get("/tags")
async def tag_search(
        q: Annotated[str, Query(min_length=1)],
        limit: Annotated[int, Query(ge=1, le=100)] = 5,
        offset: Annotated[int, Query(ge=0)] = 0,
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    t_fts, t_trgm, t_rank = _tag_search_clauses(q)

    tag_stmt = (
        select(Tag)
        .where(or_(t_fts, t_trgm))
        .order_by(desc(t_rank))
        .offset(offset)
        .limit(limit)
    )
    tags = session.execute(tag_stmt).scalars().all()

    return [
        {"id": tag.id, "name": tag.name, "category": tag.category}
        for tag in tags
    ]