import uuid
from datetime import datetime

from pydantic import BaseModel


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
