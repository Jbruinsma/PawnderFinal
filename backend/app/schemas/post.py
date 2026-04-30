from datetime import datetime
from typing import Optional, List
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
    id: UUID
    author_id: UUID
    post_type: str
    title: str
    description: str
    image_url: Optional[str]
    status: str
    created_at: datetime
    location: PostLocation
    tags: List[str]


class BaseCommunityPost(BaseModel):
    community_id: UUID
    author_id: UUID
    post_type: str
    title: str
    description: str
    image_url: Optional[str] = None
    location: PostLocation
    tags: List[str]


class PostCreationRequest(BaseCommunityPost):
    community_id: UUID


class PostUpdateRequest(BaseCommunityPost):
    pass


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
    edited: bool = False


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
