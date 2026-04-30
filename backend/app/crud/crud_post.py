from datetime import datetime
from uuid import UUID
from sqlalchemy.exc import IntegrityError
from geoalchemy2 import Geometry
from geoalchemy2.shape import from_shape
from shapely.geometry import Point
from sqlalchemy import select, desc, and_, func, cast
from sqlalchemy.orm import Session, defer

from app.models import Post, Tag, PostLikes, PostComments
from app.models.user import bookmarks
from app.schemas.post import PostCreationRequest, PostUpdateRequest


def get_post_stats_columns(current_user_id: UUID) -> list:
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
        you_liked.label("you_liked"),
        func.ST_X(cast(Post.location, Geometry)).label("lon"),
        func.ST_Y(cast(Post.location, Geometry)).label("lat"),
    ]


def retrieve_posts_with_stats(
        session: Session,
        community_id: UUID,
        current_user_id: UUID,
        limit: int,
        offset: int
):
    stmt = (
        select(*get_post_stats_columns(current_user_id))
        .join(Post.author)
        .where(Post.community_id == community_id)
        .order_by(desc(Post.created_at))
        .offset(offset)
        .limit(limit)
        .options(defer(Post.location))
    )
    return session.execute(stmt).all()


def _get_or_create_tags(session: Session, tag_names: list[str]) -> list[Tag]:
    existing_tags = session.execute(
        select(Tag).where(Tag.name.in_(tag_names))
    ).scalars().all()

    existing_tag_names = {tag.name for tag in existing_tags}
    new_tag_names = set(tag_names) - existing_tag_names
    final_tags = list(existing_tags)

    for name in new_tag_names:
        try:
            with session.begin_nested():
                new_tag = Tag(name=name, category="USER_CREATED")
                session.add(new_tag)
                session.flush()
                final_tags.append(new_tag)
        except IntegrityError:
            recovered_tag = session.execute(
                select(Tag).where(Tag.name == name)
            ).scalar_one_or_none()
            if recovered_tag:
                final_tags.append(recovered_tag)
            continue
    return final_tags


def _convert_to_geometry(longitude: float, latitude: float):
    return from_shape(Point(longitude, latitude), srid=4326)


def create_post(session: Session, payload: PostCreationRequest) -> Post:
    final_tags = _get_or_create_tags(
        session= session,
        tag_names= payload.tags
    )

    new_post = Post(
        author_id= payload.author_id,
        community_id= payload.community_id,
        post_type= payload.post_type,
        title= payload.title,
        description= payload.description,
        image_url= payload.image_url,
        location= _convert_to_geometry(payload.location.longitude, payload.location.latitude),
        tags= final_tags
    )

    session.add(new_post)
    session.flush()
    return new_post


def update_user_post(session: Session, payload: PostUpdateRequest, existing_post: Post) -> Post:
    update_data = payload.model_dump(exclude_unset=True, exclude={"tags", "location"})

    for field, value in update_data.items():
        setattr(existing_post, field, value)

    if payload.tags is not None:
        existing_post.tags = _get_or_create_tags(
            session= session,
            tag_names= payload.tags
        )

    if payload.location is not None:
        existing_post.location = _convert_to_geometry(
            payload.location.longitude,
            payload.location.latitude
        )

    existing_post.updated_at = func.now()
    existing_post.edited = True

    session.add(existing_post)

    return existing_post


def bookmark_post_for_user(
        session: Session,
        post_id: UUID,
        user_id: UUID
) -> bool | None:
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
    stmt = (
        select(func.count(PostLikes.post_id))
        .where(PostLikes.post_id == post_id)
    )
    return session.execute(stmt).scalar() or 0