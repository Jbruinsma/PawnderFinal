from uuid import UUID

from sqlalchemy import func, select, and_
from sqlalchemy.orm import Session

from app.models.community import Community, user_communities
from app.models.post import Tag, Post
from app.models.user import User


def list_tags(db: Session) -> list[Tag]:
    return db.query(Tag).order_by(Tag.category.asc(), Tag.name.asc()).all()


def list_communities(db: Session) -> list[Community]:
    return db.query(Community).order_by(Community.name.asc()).all()


def get_community_by_id(db: Session, community_id) -> Community | None:
    return db.query(Community).filter(Community.id == community_id).first()


def join_community(
    db: Session,
    *,
    user: User,
    community_id,
) -> tuple[Community | None, bool]:
    community = get_community_by_id(db, community_id)
    if community is None:
        return None, False

    if any(joined.id == community.id for joined in user.joined_communities):
        return community, False

    user.joined_communities.append(community)
    db.add(user)
    db.commit()
    db.refresh(user)

    return community, True


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