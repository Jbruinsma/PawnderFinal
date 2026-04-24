from geoalchemy2.shape import to_shape

from app.schemas.post import CommunityPost, PostLocation


def format_post_with_stats(row) -> CommunityPost:
    post = row.Post
    like_count = row.like_count
    comment_count = row.comment_count
    you_liked = row.you_liked

    return CommunityPost(
        post_id= post.id,
        author_id= post.author_id,
        author_username=post.author.full_name,
        community_id= post.community_id,
        post_type=post.post_type,
        title=post.title,
        description=post.description,
        image_url=post.image_url,
        tags=[tag.name for tag in post.tags],
        status=post.status,
        created_at=post.created_at,
        location= PostLocation(
            longitude= row.lon,
            latitude= row.lat
        ),
        like_count=like_count,
        comment_count=comment_count,
        you_liked=you_liked
    )