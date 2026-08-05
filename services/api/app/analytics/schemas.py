from datetime import date, datetime
from typing import Annotated, Any, Literal
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
    android_version: Annotated[str, Field(min_length=1, max_length=32)] = "unknown"
    application_id: Annotated[str, Field(min_length=1, max_length=128)] = "unknown"
    release_channel: Annotated[str, Field(min_length=1, max_length=40)] = "unknown"


class InstallationResponse(StrictModel):
    installation_token: Annotated[str, Field(min_length=32, max_length=256)]


class SessionStartRequest(StrictModel):
    session_id: JsonUuid
    started_at: JsonDateTime
    schema_version: Literal[1, 2] = 1
    user_id: JsonUuid | None = None
    identity_scope: Literal["anonymous_legacy", "pre_auth", "authenticated"] = "anonymous_legacy"


class SessionEndRequest(StrictModel):
    session_id: JsonUuid
    ended_at: JsonDateTime


PropertyValue = bool | int | Annotated[str, Field(max_length=40)]


class EventItem(StrictModel):
    event_id: JsonUuid
    event_name: Annotated[str, Field(min_length=1, max_length=64)]
    session_id: JsonUuid
    occurred_at: JsonDateTime
    schema_version: Literal[1, 2]
    user_id: JsonUuid | None = None
    identity_scope: Literal["anonymous_legacy", "pre_auth", "authenticated"] = "anonymous_legacy"
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
            "feature",
            "network_type",
        }
        if not set(value).issubset(allowed):
            raise ValueError("event properties contain forbidden fields")
        network_type = value.get("network_type")
        if network_type is not None and network_type not in {
            "wifi",
            "mobile",
            "offline",
            "unknown",
        }:
            raise ValueError("network_type is invalid")
        return value


class EventBatchRequest(StrictModel):
    events: Annotated[list[EventItem], Field(min_length=1, max_length=50)]


class EventBatchResponse(StrictModel):
    accepted: int
    duplicates: int


class SessionResponse(StrictModel):
    status: Literal["started", "ended"]


class MetricsOverview(StrictModel):
    start_date: date
    end_date: date
    dau: int
    wau: int
    mau: int
    active_users: int
    active_installations: int
    legacy_anonymous_active: int
    new_users: int
    new_installations: int
    login_attempts: int
    login_successes: int
    login_failures: int
    login_success_rate: float | None
    sessions: int
    sessions_per_active_user: float | None
    transaction_users: int
    transaction_count: int
    transactions_per_user: float | None
    quick_category_usage_rate: float | None
    natural_language_users: int
    natural_language_submissions: int
    natural_language_confirmation_rate: float | None
    budget_users: int
    analytics_users: int
    ai_users: int
    ai_calls: int
    ai_success_rate: float | None
    image_analysis_users: int
    d1_retention: float | None
    d7_retention: float | None
    quota_blocked: int
    identity_scope: Literal["authenticated", "anonymous_legacy"] = "authenticated"


class MetricsTimePoint(StrictModel):
    metric_date: date
    dau: int
    wau: int
    mau: int
    active_installations: int
    sessions: int
    new_users: int
    new_installations: int


class MetricsTimeseries(StrictModel):
    start_date: date
    end_date: date
    points: list[MetricsTimePoint]


class DimensionValue(StrictModel):
    value: str
    users: int
    installations: int
    events: int


class MetricsDimensions(StrictModel):
    dimension: str
    values: list[DimensionValue]


class RetentionCohort(StrictModel):
    cohort_date: date
    users: int
    d1_users: int | None
    d1_rate: float | None
    d7_users: int | None
    d7_rate: float | None


class MetricsRetention(StrictModel):
    start_date: date
    end_date: date
    d1_retention: float | None
    d7_retention: float | None
    cohorts: list[RetentionCohort]


class NamedCount(StrictModel):
    name: str
    count: int


class ModelUsage(StrictModel):
    model: str
    calls: int
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    estimated_cost_usd: float


class AiUsageMetrics(StrictModel):
    active_users: int
    calls: int
    successes: int
    failures: int
    success_rate: float | None
    average_calls_per_user: float | None
    average_latency_ms: float | None
    p50_latency_ms: int | None
    p95_latency_ms: int | None
    prompt_tokens: int
    completion_tokens: int
    total_tokens: int
    estimated_cost_usd: float
    high_usage_users: int
    kimi_429: int
    timeouts: int
    invalid_responses: int
    by_feature: list[NamedCount]
    by_model: list[ModelUsage]


class AiQuotaMetrics(StrictModel):
    blocked: int
    daily_limit_users: int
    weekly_limit_users: int
    high_usage_users: int


class OperationsDashboard(StrictModel):
    overview: MetricsOverview
    timeseries: MetricsTimeseries
    features: list[NamedCount]
    providers: list[DimensionValue]
    app_versions: list[DimensionValue]
    ai_usage: AiUsageMetrics
    ai_quota: AiQuotaMetrics


MetricFilters = dict[str, Any]
