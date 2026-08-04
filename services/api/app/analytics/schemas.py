from datetime import datetime
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


JsonUuid = Annotated[UUID, Field(strict=False)]
JsonDateTime = Annotated[datetime, Field(strict=False)]


class InstallationRequest(StrictModel):
    installation_id: JsonUuid
    anonymous_actor_id: JsonUuid
    platform: Literal["android", "ios"]
    app_version: Annotated[str, Field(min_length=1, max_length=32)]


class InstallationResponse(StrictModel):
    installation_token: Annotated[str, Field(min_length=32, max_length=256)]


class SessionStartRequest(StrictModel):
    session_id: JsonUuid
    started_at: JsonDateTime


class SessionEndRequest(StrictModel):
    session_id: JsonUuid
    ended_at: JsonDateTime


PropertyValue = bool | int | Annotated[str, Field(max_length=40)]


class EventItem(StrictModel):
    event_id: JsonUuid
    event_name: Annotated[str, Field(min_length=1, max_length=64)]
    session_id: JsonUuid
    occurred_at: JsonDateTime
    schema_version: Literal[1]
    properties: dict[str, PropertyValue] = Field(default_factory=dict, max_length=8)

    @field_validator("properties")
    @classmethod
    def validate_properties(cls, value: dict[str, PropertyValue]) -> dict[str, PropertyValue]:
        allowed = {
            "entry_method",
            "result",
            "failure_kind",
            "view_mode",
            "message_count",
            "has_image",
        }
        if not set(value).issubset(allowed):
            raise ValueError("event properties contain forbidden fields")
        return value


class EventBatchRequest(StrictModel):
    events: Annotated[list[EventItem], Field(min_length=1, max_length=50)]


class EventBatchResponse(StrictModel):
    accepted: int
    duplicates: int


class SessionResponse(StrictModel):
    status: Literal["started", "ended"]


class MetricsOverview(StrictModel):
    window_days: int
    dau: int
    wau: int
    mau: int
    new_installations: int
    sessions: int
    sessions_per_active_actor: float | None
    transaction_users: int
    transaction_count: int
    quick_category_usage_rate: float | None
    natural_language_users: int
    natural_language_confirmation_rate: float | None
    ai_users: int
    ai_success_rate: float | None
    image_analysis_users: int
    image_analysis_success_rate: float | None
    d1_retention: float | None
    d7_retention: float | None
    identity_scope: Literal["anonymous_actor"] = "anonymous_actor"
