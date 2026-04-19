from typing import List

from app.schemas.core import OutgoingBaseResponse


class Neighborhood(OutgoingBaseResponse):
    id: str
    name: str
    description: str


class NeighborhoodResponseModel(OutgoingBaseResponse):
    neighborhoods: List[Neighborhood]
