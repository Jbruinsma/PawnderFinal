from typing import Annotated, Optional, Any, Dict, Sequence, List
from uuid import UUID

from fastapi import APIRouter, Query, Depends, HTTPException
from geoalchemy2.shape import to_shape
from sqlalchemy import func, select, and_, Row, desc
from sqlalchemy.orm import Session
from starlette import status

from app.database import get_db
from app.models import Community, User, user_communities, Post
from app.schemas.common import Message
from app.schemas.community import NeighborhoodResponseModel, Neighborhood
from app.schemas.core import CoordinateSchema
from app.schemas.post import CommunityPost, CommunityPostsResponse

router = APIRouter(
    prefix="/community",
    tags=["5.0 Community Hub & Tagging"]
)


@router.get(
    path= "/neighborhoods",
    summary="List available neighborhoods",
    response_model= NeighborhoodResponseModel
)
def get_neighborhoods(
        coords: Annotated[CoordinateSchema, Query()],
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
        current_user_id: UUID,
        session: Session = Depends(get_db)
) -> Message:
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
    path= "/posts",
    summary= "List community posts"
)
async def get_posts(
        community_id: UUID,
        limit: int = Query(default=10, ge=1),
        offset: int = Query(default=1, ge=1),
        session: Session = Depends(get_db)
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

    limit: int = limit - offset + 1
    offset: int = offset - 1

    stmt = (
        select(Post)
        .join(Post.author)
        .where(Post.community_id == community_id)
        .order_by(desc(Post.created_at))
        .offset(offset)
        .limit(limit)
    )

    posts = session.execute(stmt).scalars().all()

    formatted_posts = []
    for post in posts:
        formatted_posts.append(
            CommunityPost(
                post_id=str(post.id),
                author_id=str(post.author_id),
                author_username=post.author.full_name,
                community_id=str(post.community_id),
                post_type=post.post_type,
                title=post.title,
                description=post.description,
                image_url=post.image_url,
                tags=[tag.name for tag in post.tags],
                status=post.status,
                created_at=post.created_at,
                location={
                    "longitude": to_shape(post.location).x,
                    "latitude": to_shape(post.location).y
                }
            )
        )

    return CommunityPostsResponse(
        posts=formatted_posts
    )

@router.post("/posts", summary="Create a new community post")
def create_post():
    """
    DFD Action: Processes "Create Post (Text, Image, Neighborhood Tag)".
    Writes to D4: Community & Neighborhood Records.

    Task:
    - Accept schemas.PostCreate (title, description, post_type, location, tags).
    - Save the core post to the `Post` table.
    - Link the selected tags in the `post_tags` association table.
    - Trigger any necessary "Community Interaction Alerts" logic.
    """
    return {"message": "Endpoint not implemented yet."}


@router.get("/posts/{post_id}", summary="Get a specific post")
def get_post(post_id: UUID):
    """
    DFD Action: Provides "Raw Post Data".
    Task:
    - Fetch the post from the database by ID.
    - Include the author's basic info and the associated tags.
    """
    return {"message": f"Logic to fetch post {post_id} not implemented."}


@router.post("/posts/{post_id}/bookmark", summary="Bookmark a post")
def bookmark_post(post_id: UUID):
    """
    Task:
    - Insert a record into the `bookmarks` association table linking the current user to this post.
    """
    return {"message": f"Logic to bookmark post {post_id} not implemented."}


# --- UTILITY ENDPOINTS ---

@router.get("/tags", summary="Get all available tags")
def get_tags():
    """
    Task:
    - Query the `Tag` table.
    - Return a list of all system tags (e.g., Category: Species, Name: Dog) for Matthew's frontend dropdowns.
    """
    return {"message": "Endpoint not implemented yet."}