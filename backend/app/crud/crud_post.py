# Reusable DB functions for Post (Create, Read, Update, Delete)

from uuid import UUID
from sqlalchemy import select, desc, and_, exists, func
from sqlalchemy.orm import Session

from app.models import Post, Tag, User, Community, PostLikes, PostComments
from app.models.user import bookmarks
from app.schemas.post import PostCreationRequest


def get_post_by_id(session: Session, post_id: UUID) -> Post | None:
    """Fetch a single post by its ID, with author eagerly joined."""
    stmt = (
        select(Post)
        .join(Post.author)
        .where(Post.id == post_id)
    )
    return session.execute(stmt).scalars().first()


def get_posts_by_community(
    session: Session,
    community_id: UUID,
    limit: int,
    offset: int
) -> list[Post]:
    """Fetch a paginated list of posts for a given community, newest first."""
    stmt = (
        select(Post)
        .join(Post.author)
        .where(Post.community_id == community_id)
        .order_by(desc(Post.created_at))
        .offset(offset)
        .limit(limit)
    )
    return session.execute(stmt).scalars().all()


def create_post(
    session: Session,
    payload: PostCreationRequest
) -> Post:
    """
    Insert a new Post into the database.
    Resolves tag names to existing Tag rows — unknown tag names are ignored.
    """
    existing_tags = session.execute(
        select(Tag).where(Tag.name.in_(payload.tags))
    ).scalars().all()

    new_post = Post(
        author_id=payload.author_id,
        community_id=payload.community_id,
        post_type=payload.post_type,
        title=payload.title,
        description=payload.description,
        image_url=payload.image_url,
        location=f"POINT({payload.location.longitude} {payload.location.latitude})",
        tags=list(existing_tags)
    )

    session.add(new_post)
    session.commit()
    session.refresh(new_post)
    return new_post


def bookmark_post_for_user(
    session: Session,
    post_id: UUID,
    user_id: UUID
) -> bool:
    """
    Insert a row into the bookmarks association table.
    Returns False if the bookmark already exists, True if it was created.
    """
    # Check post exists
    post_exists = session.execute(
        select(Post.id).where(Post.id == post_id)
    ).scalar()
    if not post_exists:
        return None  # Signals 404 to caller

    # Check if already bookmarked
    already_saved = session.execute(
        select(bookmarks).where(
            bookmarks.c.user_id == user_id,
            bookmarks.c.post_id == post_id
        )
    ).first()
    if already_saved:
        return False  # Signals 409 to caller

    session.execute(
        bookmarks.insert().values(
            user_id= user_id,
            post_id= post_id
        )
    )
    session.commit()
    return True

def retrieve_posts(
        limit: int,
        offset: int,
        community_id: UUID,
        session: Session
):
    stmt = (
        select(Post)
        .join(Post.author)
        .where(Post.community_id == community_id)
        .order_by(desc(Post.created_at))
        .offset(offset)
        .limit(limit)
    )

    return session.execute(stmt).scalars().all()


def retrieve_posts_with_stats(
        session: Session,
        community_id: UUID,
        current_user_id: UUID,
        limit: int,
        offset: int
):
    like_count_sq = (
        select(func.count())
        .where(PostLikes.post_id == Post.id)
        .scalar_subquery()
    )

    comment_count_sq = (
        select(func.count())
        .where(PostComments.post_id == Post.id)
        .scalar_subquery()
    )

    you_liked_sq = (
        select(
            exists().where(
                and_(
                    PostLikes.post_id == Post.id,
                    PostLikes.user_id == current_user_id
                )
            )
        ).scalar_subquery()
    )

    stmt = (
        select(
            Post,
            like_count_sq.label("like_count"),
            comment_count_sq.label("comment_count"),
            you_liked_sq.label("you_liked")
        )
        .join(Post.author)
        .where(Post.community_id == community_id)
        .order_by(desc(Post.created_at))
        .offset(offset)
        .limit(limit)
    )

    return session.execute(stmt).all()

def retrieve_post_likes(
    post_id: UUID,
    session: Session
):
    stmt = (
        select(func.count(PostLikes.post_id))
        .where(PostLikes.post_id == post_id)
    )
    return session.execute(stmt).scalar() or 0
