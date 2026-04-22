import uuid

from geoalchemy2 import Geometry
from sqlalchemy import Column, String, ForeignKey, Table
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship, Mapped, mapped_column

from app.database import Base

user_communities = Table(
    "user_communities",
    Base.metadata,
    Column("user_id", UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True),
    Column("community_id", UUID(as_uuid=True), ForeignKey("communities.id"), primary_key=True),
)

class Community(Base):
    __tablename__ = "communities"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String, unique=True, nullable=False)
    description: Mapped[str] = mapped_column(String, nullable=True)

    geofence_boundary = mapped_column(Geometry(geometry_type='POLYGON', srid=4326))

    members = relationship("User", secondary=user_communities, back_populates="joined_communities")

