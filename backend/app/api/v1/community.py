from typing import Optional, Any
from uuid import UUID

from fastapi import APIRouter, Query, Depends, HTTPException
from sqlalchemy import func, select, and_, Row, desc, union_all, delete
from sqlalchemy.orm import Session
from starlette import status

from app.core.security import get_current_user
from app.crud.crud_post import create_post as db_create_post, bookmark_post_for_user, retrieve_posts_with_stats, \
    retrieve_post_likes, get_post_stats_columns
from app.database import get_db
from app.models import Community, User, user_communities, Post, Tag, PostLikes, PostComments
from app.schemas.common import Message
from app.schemas.community import NeighborhoodResponseModel, Neighborhood
from app.schemas.core import CoordinateSchema
from app.schemas.post import CommunityPost, CommunityPostsResponse, PostCreationRequest, ExistingTagsResponseModel, \
    ExistingTag
from app.schemas.post import (
    PostBookmarkResponseModel, PostLikeResponseModel, PostUnlikeResponseModel,
    CommunityPostCommentRequest, PostComment
)
from app.services.feed_engine import generate_algorithmic_feed
from app.utils.formatting_utils import format_post_with_stats

router = APIRouter(
    prefix="/community",
    tags=["5.0 Community Hub & Tagging"]
)


@router.get(
    path="/new-feed",
    summary="Retrieve a user's feed based on post performance once they open the app"
)
async def retrieve_initial_feed(
        coords: CoordinateSchema = Depends(),
        current_user: User = Depends(get_current_user),
        session: Session = Depends(get_db)
):
    communities, raw_posts = generate_algorithmic_feed(
        session= session,
        current_user= current_user,
        coords= coords
    )

    return {
        "communities": communities,
        "posts": [format_post_with_stats(row) for row in raw_posts]
    }


@router.get(
    path= "/neighborhoods",
    summary="List available neighborhoods",
    response_model= NeighborhoodResponseModel
)
def get_neighborhoods(
        coords: CoordinateSchema = Depends(),
        current_user: User = Depends(get_current_user),
        session: Session = Depends(get_db)
):
    """
    DFD Action: Reads from D4: Community & Neighborhood Records.

    Task:
    - Receive validated latitude/longitude from CoordinateSchema.
    - Construct a PostGIS point using ST_SetSRID and ST_MakePoint.
    - Query the `Community` table and sort by proximity to the user's location.
    - Return a list of neighborhoods (id, name, description).
    """

    user_point: str = func.ST_SetSRID(
        func.ST_MakePoint(coords.longitude, coords.latitude),
        4326
    )

    communities = (
        session.query(Community)
        .order_by(func.ST_Distance(Community.geofence_boundary, user_point))
        .all()
    )

    serialized_neighborhoods = [
        Neighborhood(
            id= str(neighborhood.id),
            name= str(neighborhood.name),
            description= str(neighborhood.description)
        ) for neighborhood in communities
    ]

    return NeighborhoodResponseModel(
        neighborhoods= serialized_neighborhoods
    )


@router.post("/neighborhoods/{community_id}/join", summary="Join a neighborhood")
def join_neighborhood(
        community_id: UUID,
        current_user: User = Depends(get_current_user),
        session: Session = Depends(get_db)
) -> Message:
    current_user_id: UUID = current_user.id

    stmt = (
        select(
            Community,
            User,
            user_communities.c.user_id.label("is_member")
        )
        .select_from(Community)
        .outerjoin(User, User.id == current_user_id)
        .outerjoin(
            user_communities,
            and_(
                user_communities.c.community_id == Community.id,
                user_communities.c.user_id == User.id
            )
        )
        .where(Community.id == community_id)
    )

    result: Optional[Row[Any]] = session.execute(stmt).first()

    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Community not found"
        )

    community: Community
    user: Optional[User]
    is_member: Optional[UUID]
    community, user, is_member = result

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    if is_member is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You are already a member of this community"
        )

    user.joined_communities.append(community)

    try:
        session.commit()
    except Exception:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error"
        )

    return Message(
        message= f"Successfully joined {community.name}"
    )


@router.get(
    path="/posts",
    summary="List community posts"
)
async def get_posts(
        community_id: UUID,
        limit: int = Query(default=25, ge=1),
        offset: int = Query(default=1, ge=1),
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    if limit < offset:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="max_range cannot be less than min_range"
        )

    community_exists_stmt = select(Community.id).where(Community.id == community_id)
    if not session.execute(community_exists_stmt).scalar():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Community not found"
        )

    adjusted_limit: int = limit - offset + 1
    adjusted_offset: int = offset - 1

    post_rows = retrieve_posts_with_stats(
        session=session,
        limit=adjusted_limit,
        offset=adjusted_offset,
        community_id=community_id,
        current_user_id=current_user.id
    )

    formatted_posts = [
        format_post_with_stats(row) for row in post_rows
    ]

    return CommunityPostsResponse(
        posts= formatted_posts
    )

@router.post("/posts", summary="Create a new community post")
def create_post(
    payload: PostCreationRequest,
    session: Session = Depends(get_db)
):
    stmt = (
        union_all(
            select(User.id).where(User.id == payload.author_id),
            select(Community.id).where(Community.id == payload.community_id)
        )
    )

    combined_check = session.execute(stmt).scalars().all()

    if len(combined_check) < 2:
        author_exists = any(uid == payload.author_id for uid in combined_check)
        if not author_exists:
            raise HTTPException(status_code=404, detail="Author not found")
        raise HTTPException(status_code=404, detail="Community not found")

    # LOGIC TO BUILD: image upload to cloud storage → assign new_post.image_url
    # LOGIC TO BUILD: dispatch neighborhood alert notifications

    new_post: Post = db_create_post(
        session= session,
        payload= payload
    )

    return {
        "status": "success",
        "post_id": str(new_post.id),
        "message": "Post created successfully"
    }

@router.delete("/posts/{post_id}", summary="Delete a post")
def delete_post(
    post_id: UUID,
    session: Session = Depends(get_db)
):
    post = session.execute(
        select(Post).where(Post.id == post_id)
    ).scalars().first()

    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    session.delete(post)
    session.commit()
    return {"status": "success", "message": "Post deleted"}

# OLD CODE MIGHT REUSE DON'T DELETE

# @router.post("/posts", summary="Create a new community post")
# def create_post(
#     post_creation_request: PostCreationRequest,
#     session: Session = Depends(get_db)
# ):
#     results = session.execute(
#         select(User, Community)
#         .join(Community, Community.id == post_creation_request.community_id)
#         .where(User.id == post_creation_request.author_id)
#     ).first()
#
#     if not results:
#         raise HTTPException(
#             status_code=404,
#             detail="Author or Community not found"
#         )
#
#     author, community = results
#
#     existing_tags = session.execute(
#         select(Tag).where(Tag.name.in_(post_creation_request.tags))
#     ).scalars().all()
#
#     new_post = Post(
#         author_id=post_creation_request.author_id,
#         community_id=post_creation_request.community_id,
#         post_type=post_creation_request.post_type,
#         title=post_creation_request.title,
#         description=post_creation_request.description,
#         location=f"POINT({post_creation_request.location.longitude} {post_creation_request.location.latitude})",
#         tags= list(existing_tags)
#     )
#
#     # LOGIC TO BUILD: Handle image file validation and persistent cloud storage upload
#     # LOGIC TO BUILD: Assign the resulting permanent URL to new_post.image_url
#
#     try:
#         session.add(new_post)
#         session.commit()
#         session.refresh(new_post)
#
#         # LOGIC TO BUILD: Dispatch events for "Community Interaction Alerts" to notify nearby neighbors
#
#         return {
#             "status": "success",
#             "post_id": new_post.id,
#             "message": "Post created successfully"
#         }
#     except Exception as e:
#         session.rollback()
#         raise HTTPException(status_code=500, detail="Database commit failed")


@router.get(
    path="/posts/{post_id}",
    summary="Get a specific post",
    response_model= Optional[CommunityPost]
)
def get_post(
        post_id: UUID,
        session: Session = Depends(get_db)
) -> Optional[CommunityPost]:
    """
    DFD Action: Provides "Raw Post Data".
    Task:
    - Fetch the post from the database by ID.
    - Include the author's basic info and the associated tags.
    """

    stmt = (
        select(Post)
        .join(Post.author)
        .where(Post.id == post_id)
        .order_by(desc(Post.created_at))
    )

    post = session.execute(stmt).scalars().first()
    if not post: return None

    return format_post_with_stats(post)


@router.post(
    path= "/posts/{post_id}/bookmark",
    summary="Bookmark a post",
    response_model= PostBookmarkResponseModel
)
def bookmark_post(
    post_id: UUID,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    result: Optional[bool] = bookmark_post_for_user(
        session= session,
        post_id= post_id,
        user_id= current_user.id
    )

    if result is None:
        raise HTTPException(status_code=404, detail="Post not found")

    if not result:
        raise HTTPException(status_code=409, detail="Post already bookmarked")

    return PostBookmarkResponseModel(
        message= "Post bookmarked"
    )


@router.get(
    path="/tags",
    summary="Get all available tags",
    response_model=ExistingTagsResponseModel
)
def get_tags(
        search: Optional[str] = Query(None),
        session: Session = Depends(get_db)
) -> ExistingTagsResponseModel:
    stmt = select(Tag).limit(15)

    if search:
        stmt = stmt.where(Tag.name.contains(search))

    db_tags = session.execute(stmt).scalars().all()

    return ExistingTagsResponseModel(
        tags= [
            ExistingTag(
                tag_id= tag.id,
                name= tag.name,
                category= tag.category
            ) for tag in db_tags
        ]
    )


@router.post(
    path="/posts/{post_id}/like",
    summary="Like a post",
    response_model=PostLikeResponseModel
)
async def like_post(
        post_id: UUID,
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    stmt = select(
        select(Post.id).where(Post.id == post_id).exists(),
        select(PostLikes.post_id).where(
            PostLikes.post_id == post_id,
            PostLikes.user_id == current_user.id
        ).exists()
    )

    post_exists, like_exists = session.execute(stmt).first()

    if not post_exists:
        raise HTTPException(status_code=404, detail="Post not found")
    if like_exists:
        raise HTTPException(status_code=400, detail="You have already liked this post")

    new_like = PostLikes(
        post_id= post_id,
        user_id= current_user.id
    )

    session.add(new_like)
    session.commit()

    return PostLikeResponseModel(
        message= "Post liked successfully",
        post_id= post_id,
        new_like_count= retrieve_post_likes(
            session= session,
            post_id= post_id
        )
    )


@router.delete(
    path="/posts/{post_id}/like",
    summary="Unlike a post"
)
async def unlike_post(
        post_id: UUID,
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    stmt = (
        delete(PostLikes)
        .where(PostLikes.post_id == post_id, PostLikes.user_id == current_user.id)
    )

    result = session.execute(stmt)

    if result.rowcount == 0:
        raise HTTPException(status_code=404, detail="Like not found")

    session.commit()

    return PostUnlikeResponseModel(
        message= "Post unliked successfully",
        post_id= post_id,
        new_like_count= retrieve_post_likes(
            session= session,
            post_id= post_id
        )
    )


@router.post(
    path="/posts/{post_id}/comment",
    summary="Add a comment to a post",
    response_model= PostComment
)
async def add_comment(
        post_id: UUID,
        new_comment_request: CommunityPostCommentRequest,
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    query_items = [select(Post.id).where(Post.id == post_id).exists()]

    if new_comment_request.replying_to_id:
        query_items.append(
            select(PostComments.id).where(
                PostComments.id == new_comment_request.replying_to_id,
                PostComments.post_id == post_id
            ).exists()
        )

    stmt = select(*query_items)
    results = session.execute(stmt).first()

    if not results[0]:
        raise HTTPException(status_code=404, detail="Post not found")

    if new_comment_request.replying_to_id and not results[1]:
        raise HTTPException(status_code=404, detail="Parent comment not found")

    new_comment = PostComments(
        post_id= post_id,
        user_id= current_user.id,
        replying_to_id= new_comment_request.replying_to_id,
        content= new_comment_request.content
    )

    session.add(new_comment)
    session.commit()
    session.refresh(new_comment)

    return PostComment(
        post_id= post_id,
        user_id= current_user.id,
        replying_to_id= new_comment_request.replying_to_id,
        content= new_comment_request.content,
        created_at= new_comment.created_at.isoformat(),
        you_liked= False
    )


@router.get("/users/{user_id}/posts", summary="Get posts by a user")
def get_user_posts(
        user_id: UUID,
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    stmt = (
        select(*get_post_stats_columns(current_user.id))
        .join(Post.author)
        .where(Post.author_id == user_id)
        .order_by(desc(Post.created_at))
    )

    rows = session.execute(stmt).all()

    return CommunityPostsResponse(
        posts=[format_post_with_stats(row) for row in rows]
    )


@router.get("/bookmarks", summary="Get bookmarked posts for current user")
def get_user_bookmarks(
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    from app.models.user import bookmarks as bookmarks_table

    stmt = (
        select(*get_post_stats_columns(current_user.id))
        .join(bookmarks_table, bookmarks_table.c.post_id == Post.id)
        .join(Post.author)
        .where(bookmarks_table.c.user_id == current_user.id)
        .order_by(desc(Post.created_at))
    )

    rows = session.execute(stmt).all()

    return CommunityPostsResponse(
        posts=[format_post_with_stats(row) for row in rows]
    )


@router.delete("/posts/{post_id}/bookmark", summary="Remove a bookmark")
def remove_bookmark(
        post_id: UUID,
        session: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    from app.models.user import bookmarks as bookmarks_table

    result = session.execute(
        select(bookmarks_table).where(
            bookmarks_table.c.user_id == current_user.id,
            bookmarks_table.c.post_id == post_id
        )
    ).first()

    if not result:
        raise HTTPException(status_code=404, detail="Bookmark not found")

    session.execute(
        bookmarks_table.delete().where(
            bookmarks_table.c.user_id == current_user.id,
            bookmarks_table.c.post_id == post_id
        )
    )
    session.commit()

    return {"status": "success", "message": "Bookmark removed"}
