from sqlalchemy import func
from sqlalchemy.orm import Session
from geoalchemy2.shape import from_shape
from shapely.geometry import Point

from app.models.post import Post, Tag
from app.models.user import User, bookmarks
from app.schemas.post import PostCreate, PostResponse

def create_post(db: Session, *, user: User, post_in: PostCreate) -> PostResponse:
    point = Point(post_in.location.longitude, post_in.location.latitude)

    tags = []
    if post_in.tag_ids:
        tags = db.query(Tag).filter(Tag.id.in_(post_in.tag_ids)).all()

    post = Post(
        author_id=user.id,
        post_type=post_in.post_type,
        title=post_in.title,
        description=post_in.description,
        image_url=post_in.image_url,
        location=from_shape(point, srid=4326),
        tags=tags,
    )
    db.add(post)
    db.commit()
    db.refresh(post)

    longitude = db.query(func.ST_X(post.location)).scalar()
    latitude = db.query(func.ST_Y(post.location)).scalar()

    return PostResponse(
        id=post.id,
        author_id=post.author_id,
        post_type=post.post_type,
        title=post.title,
        description=post.description,
        image_url=post.image_url,
        status=post.status,
        created_at=post.created_at,
        location={
            "longitude": longitude,
            "latitude": latitude,
        },
        tags=[tag.name for tag in post.tags],
    )

def get_post_by_id(db: Session, *, post_id) -> PostResponse | None:
    post = db.query(Post).filter(Post.id == post_id).first()
    if post is None:
        return None

    longitude = db.query(func.ST_X(post.location)).scalar()
    latitude = db.query(func.ST_Y(post.location)).scalar()

    return PostResponse(
        id=post.id,
        author_id=post.author_id,
        post_type=post.post_type,
        title=post.title,
        description=post.description,
        image_url=post.image_url,
        status=post.status,
        created_at=post.created_at,
        location={
            "longitude": longitude,
            "latitude": latitude,
        },
        tags=[tag.name for tag in post.tags],
    )

def bookmark_post(db: Session, *, user: User, post_id) -> Post | None:
    post = db.query(Post).filter(Post.id == post_id).first()
    if post is None:
        return None

    if any(saved_post.id == post.id for saved_post in user.saved_posts):
        return post

    user.saved_posts.append(post)
    db.add(user)
    db.commit()
    db.refresh(user)

    return post

def list_bookmarked_posts(db: Session, *, user: User) -> list[PostResponse]:
    bookmarked_posts = []

    for post in user.saved_posts:
        longitude = db.query(func.ST_X(post.location)).scalar()
        latitude = db.query(func.ST_Y(post.location)).scalar()

        bookmarked_posts.append(
            PostResponse(
                id=post.id,
                author_id=post.author_id,
                post_type=post.post_type,
                title=post.title,
                description=post.description,
                image_url=post.image_url,
                status=post.status,
                created_at=post.created_at,
                location={
                    "latitude": latitude,
                    "longitude": longitude,
                },
                tags=[tag.name for tag in post.tags],
            )
        )

    return bookmarked_posts

