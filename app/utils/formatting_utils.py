from geoalchemy2.shape import to_shape

from app.schemas.post import CommunityPost


def format_post(post) -> CommunityPost:
    return CommunityPost(
        post_id=str(post.id),
        author_id=str(post.author_id),
        author_username=post.author.full_name,
        community_id=str(post.community_id),
        post_type=post.post_type,
        title=post.title,
        description=post.description,
        image_url=post.image_url,
        tags=[
            tag.name for tag in post.tags
        ],
        status=post.status,
        created_at=post.created_at,
        location={
            "longitude": to_shape(post.location).x,
            "latitude": to_shape(post.location).y
        }
    )
