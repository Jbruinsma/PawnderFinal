from uuid import UUID
from sqlalchemy import select, desc, and_, func
from sqlalchemy.orm import Session

from app.models import Post, Tag, PostLikes, PostComments
from app.models.user import bookmarks
from app.schemas.post import PostCreationRequest


def get_post_stats_columns(current_user_id: UUID) -> list:
    """Helper to generate consistent statistical columns for post queries."""
    like_count = select(func.count(PostLikes.post_id)).where(PostLikes.post_id == Post.id).correlate(
        Post).scalar_subquery()
    comment_count = select(func.count(PostComments.id)).where(PostComments.post_id == Post.id).correlate(
        Post).scalar_subquery()
    you_liked = select(PostLikes.post_id).where(
        and_(PostLikes.post_id == Post.id, PostLikes.user_id == current_user_id)
    ).correlate(Post).exists()

    return [
        Post,
        func.coalesce(like_count, 0).label("like_count"),
        func.coalesce(comment_count, 0).label("comment_count"),
        you_liked.label("you_liked")
    ]


def get_post_by_id(session: Session, post_id: UUID) -> Post | None:
    """Fetch a single post by its ID, with author eagerly joined."""
    stmt = (
        select(Post)
        .join(Post.author)
        .where(Post.id == post_id)
    )
    return session.execute(stmt).scalars().first()


def retrieve_posts(
        limit: int,
        offset: int,
        community_id: UUID,
        session: Session
):
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


def retrieve_posts_with_stats(
        session: Session,
        community_id: UUID,
        current_user_id: UUID,
        limit: int,
        offset: int
):
    """Fetch paginated community posts with aggregated likes, comments, and current user status."""
    stmt = (
        select(*get_post_stats_columns(current_user_id))
        .join(Post.author)
        .where(Post.community_id == community_id)
        .order_by(desc(Post.created_at))
        .offset(offset)
        .limit(limit)
    )
    return session.execute(stmt).all()


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
) -> bool | None:
    """
    Insert a row into the bookmarks association table.
    Returns False if the bookmark already exists, True if it was created.
    Returns None if the post does not exist.
    """
    post_exists = session.execute(
        select(Post.id).where(Post.id == post_id)
    ).scalar()

    if not post_exists:
        return None

    already_saved = session.execute(
        select(bookmarks).where(
            bookmarks.c.user_id == user_id,
            bookmarks.c.post_id == post_id
        )
    ).first()

    if already_saved:
        return False

    session.execute(
        bookmarks.insert().values(
            user_id=user_id,
            post_id=post_id
        )
    )
    session.commit()
    return True


def retrieve_post_likes(
        post_id: UUID,
        session: Session
) -> int:
    """Retrieve the total like count for a specific post."""
    stmt = (
        select(func.count(PostLikes.post_id))
        .where(PostLikes.post_id == post_id)
    )
    return session.execute(stmt).scalar() or 0