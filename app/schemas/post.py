import uuid
from datetime import datetime
from typing import Optional, List, Dict

from pydantic import BaseModel

from app.schemas.core import OutgoingBaseResponse


class PostLocation(BaseModel):
    latitude: float
    longitude: float


class PostSearchResponse(BaseModel):
    id: uuid.UUID
    author_id: uuid.UUID
    post_type: str
    title: str
    description: str
    image_url: str | None
    status: str
    created_at: datetime
    location: PostLocation
    tags: list[str]


class CommunityPost(OutgoingBaseResponse):
    post_id: str
    author_id: str
    author_username: Optional[str] = None
    community_id: str
    post_type: str
    title: str
    description: str
    image_url: Optional[str]
    location: Dict
    tags: list[str]
    status: str
    created_at: datetime


class CommunityPostsResponse(OutgoingBaseResponse):
    posts: List[CommunityPost]