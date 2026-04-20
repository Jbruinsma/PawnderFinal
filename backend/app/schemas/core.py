from pydantic import BaseModel, Field, ConfigDict
from pydantic.alias_generators import to_camel


class OutgoingBaseResponse(BaseModel):
    model_config = ConfigDict(
        alias_generator= to_camel,
        populate_by_name= True,
        from_attributes= True
    )


class CoordinateSchema(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
