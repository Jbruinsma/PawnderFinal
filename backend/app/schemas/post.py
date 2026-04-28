import uuid
from datetime import datetime
from typing import Optional, List, Dict
from uuid import UUID

from pydantic import BaseModel, ConfigDict

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
    image_url: Optional[str]
    status: str
    created_at: datetime
    location: PostLocation
    tags: List[str]


class PostCreationRequest(BaseModel):
    community_id: UUID
    author_id: UUID
    post_type: str
    title: str
    description: str
    image_url: Optional[str] = None
    location: PostLocation
    tags: list[str]


class PostUpdateRequest(BaseModel):
    post_type: Optional[str] = None
    description: Optional[str] = None


class BookmarkRequest(BaseModel):
    user_id: UUID


class CommunityPost(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    post_id: UUID
    author_id: UUID
    author_username: str
    community_id: UUID
    post_type: str
    title: str
    description: str
    image_url: Optional[str] = None
    location: PostLocation
    tags: List[str] = []
    status: str
    created_at: datetime
    like_count: int = 0
    comment_count: int = 0
    you_liked: bool = False


class CommunityPostCommentRequest(BaseModel):
    replying_to_id: Optional[UUID] = None
    content: str


class CommunityPostsResponse(BaseModel):
    posts: List[CommunityPost]


class PostBookmarkResponseModel(Message, Status):
    pass


class PostLikeResponseModel(Message):
    post_id: UUID
    new_like_count: int = 0


class PostUnlikeResponseModel(PostLikeResponseModel):
    pass


class PostComment(BaseModel):
    comment_id: UUID
    post_id: UUID
    user_id: UUID
    author_name: str = ""
    replying_to_id: Optional[UUID] = None
    content: str
    created_at: datetime
    like_count: int = 0
    you_liked: bool = False


class PostCommentsResponse(BaseModel):
    comments: List[PostComment]
