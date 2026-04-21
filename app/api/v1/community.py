from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.crud.crud_post import (
    bookmark_post as bookmark_post_crud,
    create_post as create_post_crud,
    get_post_by_id,
    list_bookmarked_posts,
)
from app.schemas.post import PostCreate, PostResponse
from app.crud.crud_community import join_community, list_communities, list_tags
from app.database import get_db
from app.models.user import User
from app.schemas.community import (
    BookmarkResponse,
    CommunityJoinResponse,
    CommunityResponse,
    TagResponse,
)

router = APIRouter(
    prefix="/community",
    tags=["5.0 Community Hub & Tagging"]
)


# --- NEIGHBORHOOD / COMMUNITY ENDPOINTS ---

@router.get(
    "/neighborhoods",
    response_model=list[CommunityResponse],
    summary="List available neighborhoods",
)
def get_neighborhoods(db: Session = Depends(get_db)):
    """
    DFD Action: Reads from D4: Community & Neighborhood Records.
    Task:
    - Query the `Community` table.
    - Return a list of neighborhoods (id, name, description).
    """
    return list_communities(db)

@router.post(
"/neighborhoods/{community_id}/join",
    response_model=CommunityJoinResponse,
    summary="Join a neighborhood",
)
def join_neighborhood(
    community_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    DFD Action: Processes "Topic Tags & Community Joins".
    Task:
    - Identify the current user (via JWT token).
    - Insert a record into the `user_communities` association table.
    """
    community, joined = join_community(
        db,
        user=current_user,
        community_id=community_id,
    )
    if community is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Community {community_id} was not found.",
        )

    message = (
        "Joined neighborhood successfully."
        if joined
        else "User is already a member of this neighborhood."
    )
    return {
        "message": message,
        "community": community,
    }

# --- POST & TAGGING ENDPOINTS ---

@router.post(
"/posts",
    response_model=PostResponse,
    summary="Create a new community post",
)
def create_post(
    post_in: PostCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    DFD Action: Processes "Create Post (Text, Image, Neighborhood Tag)".
    Writes to D4: Community & Neighborhood Records.

    Task:
    - Accept schemas.PostCreate (title, description, post_type, location, tags).
    - Save the core post to the `Post` table.
    - Link the selected tags in the `post_tags` association table.
    - Trigger any  necessary "Community Interaction Alerts" logic.
    """
    return create_post_crud(db, user=current_user, post_in=post_in)

@router.get(
    "/posts/{post_id}",
    response_model=PostResponse,
    summary="Get a specific post",
)
def get_post(post_id: UUID, db: Session = Depends(get_db)):
    """
    DFD Action: Provides "Raw Post Data".
    Task:
    - Fetch the post from the database by ID.
    - Include the author's basic info and the associated tags.
    """
    post = get_post_by_id(db, post_id=post_id)
    if post is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Post {post_id} was not found.",
        )
    return post


@router.post(
    "/posts/{post_id}/bookmark",
    response_model=BookmarkResponse,
    summary="Bookmark a post"
)
def bookmark_post(
    post_id: UUID,
    db:Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Task:
    - Insert a record into the `bookmarks` association table
     """
    post = bookmark_post_crud(db, user=current_user, post_id=post_id)
    if post is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Post {post_id} was not found.",
        )
    return {
        "message": "Post bookmarked successfully.",
        "post_id": post.id,
    }

@router.get(
"/bookmarks",
    response_model=list[PostResponse],
    summary="Get current user's bookmarked posts",
)
def get_bookmarked_posts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
        Task:
        - Return the posts bookmarked by the current user.
        """
    return list_bookmarked_posts(db, user=current_user)

        # --- UTILITY ENDPOINTS ---


@router.get(
    "/tags",
    response_model=list[TagResponse],
    summary="Get all available tags",
)
def get_tags(db: Session = Depends(get_db)):
    """
    Task:
    - Query the `Tag` table.
    - Return a list of all system tags (e.g., Category: Species, Name: Dog) for Matthew's frontend dropdowns.
    """
    return list_tags(db)
