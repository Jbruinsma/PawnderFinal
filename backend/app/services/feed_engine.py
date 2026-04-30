from geoalchemy2 import Geometry, Geography
from sqlalchemy import select, and_, func, cast, desc
from sqlalchemy.orm import defer, Session, joinedload

from app.models import PostLikes, Post, PostComments, Community, user_communities, User


def generate_algorithmic_feed(
        session: Session,
        current_user: User,
        coords
):
    user_point = func.ST_SetSRID(func.ST_MakePoint(coords.longitude, coords.latitude), 4326)
    user_geog = cast(user_point, Geography)

    intersects = func.ST_Intersects(Community.geofence_boundary, user_point)
    comm_distance = func.ST_Distance(Community.geofence_boundary, user_point)

    member_count_subq = select(func.count(user_communities.c.user_id)).where(
        user_communities.c.community_id == Community.id
    ).correlate(Community).scalar_subquery()

    post_count_subq = select(func.count(Post.id)).where(
        Post.community_id == Community.id
    ).correlate(Community).scalar_subquery()

    communities_stmt = (
        select(
            Community,
            user_communities.c.user_id.isnot(None).label("is_member"),
            func.coalesce(member_count_subq, 0).label("member_count"),
            func.coalesce(post_count_subq, 0).label("post_count")
        )
        .outerjoin(
            user_communities,
            and_(
                user_communities.c.community_id == Community.id,
                user_communities.c.user_id == current_user.id
            )
        )
        .order_by(
            desc(intersects),
            comm_distance,
            desc(func.coalesce(member_count_subq, 0))
        )
        .limit(10)
        .options(defer(Community.geofence_boundary))
    )
    communities = session.execute(communities_stmt).all()

    like_count = select(func.count(PostLikes.id)).where(
        PostLikes.post_id == Post.id
    ).correlate(Post).scalar_subquery()

    comment_count = select(func.count(PostComments.id)).where(
        PostComments.post_id == Post.id
    ).correlate(Post).scalar_subquery()

    age_in_hours = func.extract('epoch', func.now() - Post.created_at) / 3600

    post_geog = cast(Post.location, Geography)
    post_distance = func.ST_Distance(post_geog, user_geog)

    score_expr = (
            (func.coalesce(like_count, 0) * 1.5) +
            (func.coalesce(comment_count, 0) * 2.5) -
            (post_distance * 0.00005) -
            (age_in_hours * 1.2)
    ).label("feed_score")

    distance_filter = func.ST_DWithin(post_geog, user_geog, 80467)

    subq = (
        select(Post.id.label("subq_post_id"), score_expr)
        .where(and_(distance_filter, Post.author_id != current_user.id))
        .order_by(desc("feed_score"))
        .limit(25)
        .subquery()
    )

    you_liked = select(PostLikes.post_id).where(
        and_(PostLikes.post_id == Post.id, PostLikes.user_id == current_user.id)
    ).correlate(Post).exists()

    posts_stmt = (
        select(
            Post,
            func.coalesce(like_count, 0).label("like_count"),
            func.coalesce(comment_count, 0).label("comment_count"),
            you_liked.label("you_liked"),
            func.ST_X(cast(Post.location, Geometry)).label("lon"),
            func.ST_Y(cast(Post.location, Geometry)).label("lat")
        )
        .join(subq, Post.id == subq.c.subq_post_id)
        .join(Post.author)
        .options(
            joinedload(Post.tags),
            defer(Post.location)
        )
        .order_by(desc(subq.c.feed_score))
    )

    raw_posts = session.execute(posts_stmt).unique().all()

    return communities, raw_posts