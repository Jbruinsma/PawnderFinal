import uuid
from datetime import datetime
from typing import Optional, List, Dict
from uuid import UUID

from pydantic import BaseModel

from app.schemas.common import Message, Status


class ExistingTag(BaseModel):
    tag_id: str
    category: str
    name: str


class ExistingTagsResponseModel(BaseModel):
    tags: List[ExistingTag]


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


class PostCreationRequest(BaseModel):
    community_id: UUID
    author_id: UUID
    post_type: str
    title: str
    description: str
    image_url: Optional[str] = None
    location: PostLocation
    tags: list[str]


class BookmarkRequest(BaseModel):
    user_id: UUID


class CommunityPost(BaseModel):
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


class CommunityPostsResponse(BaseModel):
    posts: List[CommunityPost]


class PostBookmarkResponseModel(Message, Status):
    pass