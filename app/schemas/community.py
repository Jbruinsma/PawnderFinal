import uuid

from pydantic import BaseModel, ConfigDict


class CommunityResponse(BaseModel):
    id: uuid.UUID
    name: str
    description: str | None

    model_config = ConfigDict(from_attributes=True)


class CommunityJoinResponse(BaseModel):
    message: str
    community: CommunityResponse

class TagResponse(BaseModel):
    id: uuid.UUID
    category: str
    name: str

    model_config = ConfigDict(from_attributes=True)

class BookmarkResponse(BaseModel):
    message: str
    post_id: uuid.UUID
