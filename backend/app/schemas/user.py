import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserBase(BaseModel):
    role: str
    email: EmailStr
    full_name: str


class UserCreate(UserBase):
    password: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserRegistrationResponseModel(BaseModel):
    token: Token
    email: str
    role: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(UserBase):
    id: uuid.UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class UserLocationUpdate(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)

class LocationPoint(BaseModel):
    latitude: float
    longitude: float

class UserLocationResponse(BaseModel):
    message: str
    last_known_location: LocationPoint