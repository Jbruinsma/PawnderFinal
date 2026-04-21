from sqlalchemy.orm import Session

from app.models.community import Community
from app.models.user import User
from app.models.post import Tag

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
