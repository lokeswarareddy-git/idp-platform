from datetime import datetime
from enum import Enum
from typing import Annotated, Literal, Union

from pydantic import BaseModel, Field, field_validator


class S3Config(BaseModel):
    resource_type: Literal["s3"]
    versioning_enabled: bool = False
    public_access_blocked: bool = True


class DynamoDBConfig(BaseModel):
    resource_type: Literal["dynamodb"]
    billing_mode: Literal["PAY_PER_REQUEST", "PROVISIONED"] = "PAY_PER_REQUEST"
    hash_key: str = Field(..., min_length=1)
    range_key: str | None = None


class ProvisionRequest(BaseModel):
    name: str = Field(
        ...,
        min_length=3,
        max_length=63,
        pattern=r"^[a-z][a-z0-9-]*$",
        description="Lowercase alphanumeric name with hyphens, starting with a letter",
    )
    environment: Literal["dev", "staging", "prod"]
    owner_team: str = Field(..., min_length=1)
    config: Annotated[
        Union[S3Config, DynamoDBConfig],
        Field(discriminator="resource_type"),
    ]
    tags: dict[str, str] = Field(default_factory=dict)

    @field_validator("tags")
    @classmethod
    def validate_tags_count(cls, v: dict[str, str]) -> dict[str, str]:
        if len(v) > 10:
            raise ValueError("Maximum 10 tags allowed")
        return v


class ProvisionStatus(str, Enum):
    ACCEPTED = "accepted"
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"


class ProvisionResponse(BaseModel):
    request_id: str
    name: str
    resource_type: str
    environment: str
    owner_team: str
    status: ProvisionStatus
    requested_at: datetime
    resource_arn: str | None = None
    message: str


class ErrorResponse(BaseModel):
    error: str
    detail: str | None = None
