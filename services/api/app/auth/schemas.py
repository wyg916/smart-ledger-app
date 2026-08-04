from datetime import datetime
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


JsonUuid = Annotated[UUID, Field(strict=False)]


class PhoneLoginRequest(StrictModel):
    token: Annotated[str, Field(min_length=8, max_length=4096)]
    carrier: Literal["mobile", "unicom", "telecom"] | None = None
    installation_id: JsonUuid


class WechatStateRequest(StrictModel):
    installation_id: JsonUuid


class WechatStateResponse(StrictModel):
    state: Annotated[str, Field(min_length=32, max_length=256)]
    expires_in_seconds: int


class WechatLoginRequest(StrictModel):
    code: Annotated[str, Field(min_length=4, max_length=2048)]
    state: Annotated[str, Field(min_length=32, max_length=256)]
    installation_id: JsonUuid


class ReviewLoginRequest(StrictModel):
    username: Annotated[str, Field(min_length=3, max_length=128)]
    password: Annotated[str, Field(min_length=8, max_length=256)]
    installation_id: JsonUuid


class RefreshRequest(StrictModel):
    refresh_token: Annotated[str, Field(min_length=32, max_length=512)]


class LogoutRequest(StrictModel):
    refresh_token: Annotated[str | None, Field(default=None, min_length=32, max_length=512)]


class TokenPair(StrictModel):
    access_token: str
    refresh_token: str
    token_type: Literal["Bearer"] = "Bearer"
    access_expires_at: datetime
    refresh_expires_at: datetime


class UserView(StrictModel):
    user_id: str
    status: str
    providers: list[str]


class AuthResponse(StrictModel):
    user: UserView
    tokens: TokenPair
    session_id: str


class StatusResponse(StrictModel):
    status: str


class IdentityResponse(StrictModel):
    providers: list[str]


class DeletionRequestPayload(StrictModel):
    idempotency_key: Annotated[str, Field(min_length=16, max_length=128)]
    local_data_action: Literal["delete_local", "keep_isolated"]


class DeletionConfirmPayload(StrictModel):
    request_id: JsonUuid
    confirmation: Literal["DELETE"]


class DeletionResponse(StrictModel):
    request_id: str
    status: str
    local_data_action: str
