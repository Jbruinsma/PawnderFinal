from typing import List

from pydantic import BaseModel


class Neighborhood(BaseModel):
    id: str
    name: str
    description: str
    post_count: int = 0
    member_count: int = 0


class NeighborhoodResponseModel(BaseModel):
    neighborhoods: List[Neighborhood]


class CommunityCreateRequest(BaseModel):
    name: str
    description: str
    latitude: float
    longitude: float


class CommunityCreateResponse(BaseModel):
    community: Neighborhood
    message: str
