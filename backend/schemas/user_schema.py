from datetime import datetime
from typing import Optional, Dict, List
from typing_extensions import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, StringConstraints, field_validator


class UserBase(BaseModel):
      email: Annotated[str, StringConstraints(strip_whitespace=True, min_length=6)]
      first_name: Optional[
            Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]
      ] = None
      last_name: Optional[
            Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]
      ] = None
      user_id: Optional[str] = None
      password: Optional[Annotated[str, StringConstraints(strip_whitespace=True, min_length=6)]] = None
      user_config: Optional[Dict] = None
      role_id: Optional[UUID] = None
      data_access: Optional[Dict] = None
      user_group_ids: Optional[List[str]] = None

      @field_validator("email", mode="before")
      def lowercase_email(cls, v: Optional[str]) -> Optional[str]:
            if v:
                  return v.strip().lower()
            return v
      @classmethod
      @field_validator("first_name", "last_name")
      def validate(cls, v):
            if v and not all(c.isalnum() or c in ("-","_","."," ") for c in v):
                  raise ValueError(
                        "Name can only contain letters, number, underscores, hyphens, and periods"
                  )
            return v
    
class UserCreate(UserBase):
      first_name: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]
      last_name: Annotated[str, StringConstraints(strip_whitespace=True, min_length=1)]
      password: Annotated[str, StringConstraints(strip_whitespace=True, min_length=6)]
      role_id: UUID

class UserUpdate(UserBase):
      email: Optional[Annotated[str, StringConstraints(strip_whitespace=True, min_length=6)]]

class UserDetail(UserBase):
      id: UUID
      role_key: Optional[str] = None
      user_group_keys: Optional[List[str]] = None
      account_status: Optional[str] = None
      last_login: Optional[datetime] = None
      created_at: Optional[datetime] = None
      updated_at: Optional[datetime] = None

      model_config = ConfigDict(
            from_attributes=True, protected_namespaces=(), exclude={"password"}
      )

class UserResponse(BaseModel):
      users: List[UserDetail]
      total: int

class UserLogin(BaseModel):
      email: Optional[str] = None
      password: Optional[str] = None
      db_schema: Optional[str] = None

      @field_validator("email", mode="before")
      def lowercase_email():        