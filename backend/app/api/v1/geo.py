from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.crud.crud_geo import (
    get_geo_feed,
    get_neighborhood_feed as get_neighborhood_feed_crud,
    search_posts_by_radius as search_posts_by_radius_crud,
)
from app.core.database import get_db
from app.models.user import User
from app.schemas.post import PostSearchResponse


router = APIRouter(
    prefix="/geo",
    tags=["2.0 Geo-Recommendation Engine"]
)


@router.get(
    "/feed",
    response_model=list[PostSearchResponse],
    summary="Get personalized geo-relevant feed",
)
def get_user_feed(
    radius_km: float = Query(8.0, gt=0, description="Feed radius in kilometers"),
    tags: Optional[List[str]] = Query(
        None,
        description="Optional category filters (e.g., 'Dog', 'Lost')",
    ),
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    DFD Action: Generates "Geo-Relevant Recommended Feed".

    Task:
    - Identify the current user and their `last_known_location`.
    - Query D4 (Posts) using PostGIS `ST_DWithin` to find posts within a dynamic radius (e.g., 5 miles).
    - Prioritize algorithms: Sort by a combination of `created_at` (urgency) and ST_Distance (proximity).
    """
    if current_user.last_known_location is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current user location is required before requesting the geo feed.",
        )

    return get_geo_feed(
        session,
        user=current_user,
        radius_km=radius_km,
        tags=tags,
    )


@router.get(
    "/search",
    response_model=list[PostSearchResponse],
    summary="Search posts by custom radius and tags",
)
def search_posts_by_radius(
    lat: float = Query(..., ge=-90, le=90, description="Latitude of search center"),
    lon: float = Query(..., ge=-180, le=180, description="Longitude of search center"),
    radius_km: float = Query(5.0, gt=0, description="Radius in kilometers"),
    tags: Optional[List[str]] = Query(
        None,
        description="Optional category filters (e.g., 'Dog', 'Lost')",
    ),
    session: Session = Depends(get_db),
):
    """
    DFD Action: Processes "Spatial & Tag Queries".

    Task:
    - Construct a PostGIS Geometry Point from the provided `lat` and `lon`.
    - Filter posts where `ST_DWithin(location, :search_point, :radius)` is true.
    - Join with the `post_tags` table if the user provides specific filtering tags.
    """
    return search_posts_by_radius_crud(
        session,
        lat=lat,
        lon=lon,
        radius_km=radius_km,
        tags=tags,
    )


@router.get(
    "/neighborhood/{community_id}/feed",
    response_model=list[PostSearchResponse],
    summary="Get posts strictly within a neighborhood",
)
def get_neighborhood_feed(community_id: UUID, session: Session = Depends(get_db)):
    """
    DFD Action: Intersects D4 Community bounds with D4 Posts.

    Task:
    - Fetch the `Community` by ID to retrieve its `geofence_boundary` (Polygon).
    - Use PostGIS `ST_Contains` or `ST_Intersects` to return ONLY posts that fall inside that specific polygon.
    """
    try:
        posts = get_neighborhood_feed_crud(
            session= session,
            community_id=community_id
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc

    if posts is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Community {community_id} was not found.",
        )
    return posts
