from datetime import datetime
from typing import Optional, Dict, List
from typing_extensions import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class UserBase(BaseModel):
    username: Annotated[str, Field(min_length=1, max_length=150)]
    full_name: Optional[Annotated[str, Field(min_length=1, max_length=255)]] = None
    roles: List[str] = Field(default_factory=list)
    metadata: Dict[str, str] = Field(default_factory=dict)


class UserCreate(UserBase):
    password: Annotated[str, Field(min_length=8)]


class UserUpdate(BaseModel):
    full_name: Optional[Annotated[str, Field(min_length=1, max_length=255)]] = None
    roles: Optional[List[str]] = None
    metadata: Optional[Dict[str, str]] = None


class UserSchema(UserBase):
    id: UUID
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
