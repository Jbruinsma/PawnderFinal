from collections.abc import Sequence

from sqlalchemy import func
from sqlalchemy.orm import Query, Session

from app.models.community import Community
from app.models.post import Post, Tag
from app.models.user import User
from app.schemas.post import PostSearchResponse


def _apply_tag_filter(query: Query, tags: Sequence[str] | None) -> Query:
    if not tags:
        return query

    return query.filter(Post.tags.any(Tag.name.in_(tags)))


def _serialize_post(session: Session, post: Post) -> PostSearchResponse:
    longitude = session.query(func.ST_X(post.location)).scalar()
    latitude = session.query(func.ST_Y(post.location)).scalar()

    return PostSearchResponse(
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


def search_posts_by_radius(
    session: Session,
    *,
    lat: float,
    lon: float,
    radius_km: float,
    tags: Sequence[str] | None = None,
) -> list[PostSearchResponse]:
    search_point = func.ST_SetSRID(func.ST_MakePoint(lon, lat), 4326)
    radius_meters = radius_km * 1000
    distance_expr = func.ST_Distance(
        func.Geography(Post.location),
        func.Geography(search_point),
    )

    query = session.query(Post).filter(
        func.ST_DWithin(
            func.Geography(Post.location),
            func.Geography(search_point),
            radius_meters,
        )
    )
    query = _apply_tag_filter(query, tags)

    posts = query.order_by(distance_expr.asc(), Post.created_at.desc()).all()
    return [_serialize_post(session, post) for post in posts]


def get_geo_feed(
    session: Session,
    *,
    user: User,
    radius_km: float,
    tags: Sequence[str] | None = None,
) -> list[PostSearchResponse]:
    radius_meters = radius_km * 1000
    user_search_point = func.ST_SetSRID(
        func.ST_MakePoint(
            func.ST_X(user.last_known_location),
            func.ST_Y(user.last_known_location),
        ),
        4326,
    )
    distance_expr = func.ST_Distance(
        func.Geography(Post.location),
        func.Geography(user_search_point),
    )

    query = session.query(Post).filter(
        Post.status == "Active",
        Post.author_id != user.id,
        func.ST_DWithin(
            func.Geography(Post.location),
            func.Geography(user_search_point),
            radius_meters,
        ),
    )
    query = _apply_tag_filter(query, tags)

    posts = query.order_by(Post.created_at.desc(), distance_expr.asc()).all()
    return [_serialize_post(session, post) for post in posts]


def get_neighborhood_feed(
    session: Session,
    *,
    community_id,
) -> list[PostSearchResponse] | None:
    community = session.query(Community).filter(Community.id == community_id).first()
    if community is None:
        return None

    if community.geofence_boundary is None:
        raise ValueError("Community geofence boundary is not configured.")

    posts = (
        session.query(Post)
        .filter(
            Post.status == "Active",
            func.ST_Intersects(Post.location, community.geofence_boundary),
        )
        .order_by(Post.created_at.desc())
        .all()
    )
    return [_serialize_post(session, post) for post in posts]
