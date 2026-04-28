from pydantic import BaseModel


class Message(BaseModel):
    message: str


class Status(BaseModel):
    status: str = "success"