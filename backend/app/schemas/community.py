from typing import List, Optional
from pydantic import BaseModel


class Neighborhood(BaseModel):
    id: str
    name: str
    description: str
    image_url: Optional[str] = None
    post_count: int = 0
    member_count: int = 0
    is_member: bool = False


class NeighborhoodResponseModel(BaseModel):
    neighborhoods: List[Neighborhood]


class CommunityCreateRequest(BaseModel):
    name: str
    description: str
    latitude: float
    longitude: float
    # image: ?? Need help with this


class CommunityCreateResponse(BaseModel):
    community: Neighborhood
    message: str
