from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Query, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Community
from app.schemas.community import NeighborhoodResponseModel, Neighborhood
from app.schemas.core import CoordinateSchema

router = APIRouter(
    prefix="/community",
    tags=["5.0 Community Hub & Tagging"]
)


# --- NEIGHBORHOOD / COMMUNITY ENDPOINTS ---

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

    user_point = func.ST_SetSRID(
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
def join_neighborhood(community_id: UUID):
    """
    DFD Action: Processes "Topic Tags & Community Joins".
    Task:
    - Identify the current user (via JWT token).
    - Insert a record into the `user_communities` association table.
    """
    return {"message": f"Logic to join community {community_id} not implemented."}


# --- POST & TAGGING ENDPOINTS ---

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