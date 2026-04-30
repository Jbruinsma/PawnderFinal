from uuid import UUID

from sqlalchemy import func, select, and_
from sqlalchemy.orm import Session

from app.models.community import Community, user_communities
from app.models.post import Post


def get_community_by_id(db: Session, community_id) -> Community | None:
    return db.query(Community).filter(Community.id == community_id).first()


def get_community_stats_query(current_user_id: UUID, base_stmt):
    member_count_subq = select(func.count(user_communities.c.user_id)).where(
        user_communities.c.community_id == Community.id
    ).correlate(Community).scalar_subquery()

    post_count_subq = select(func.count(Post.id)).where(
        Post.community_id == Community.id
    ).correlate(Community).scalar_subquery()

    return base_stmt.add_columns(
        user_communities.c.user_id.isnot(None).label("is_member"),
        func.coalesce(member_count_subq, 0).label("member_count"),
        func.coalesce(post_count_subq, 0).label("post_count")
    ).outerjoin(
        user_communities,
        and_(
            user_communities.c.community_id == Community.id,
            user_communities.c.user_id == current_user_id
        )
    )