import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class PostLocation(BaseModel):
    latitude: float
    longitude: float

class PostCreate(BaseModel):
    post_type: str
    title: str
    description: str
    image_url: str | None = None
    location: PostLocation
    tag_ids: list[uuid.UUID] = Field(default_factory=list)


class PostResponse(BaseModel):
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

    model_config = ConfigDict(from_attributes=True)


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
