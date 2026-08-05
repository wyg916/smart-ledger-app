from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.analytics.models import Base, utc_now


class AiQuotaPlan(Base):
    __tablename__ = "ai_quota_plans"

    plan_code: Mapped[str] = mapped_column(String(32), primary_key=True)
    daily_limit: Mapped[int] = mapped_column(Integer)
    weekly_limit: Mapped[int] = mapped_column(Integer)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    effective_from: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    effective_to: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    __table_args__ = (
        CheckConstraint("daily_limit > 0", name="ck_ai_quota_plan_daily_positive"),
        CheckConstraint("weekly_limit >= daily_limit", name="ck_ai_quota_plan_weekly_daily"),
    )


class AiQuotaCounter(Base):
    __tablename__ = "ai_quota_counters"

    user_id: Mapped[str] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), primary_key=True
    )
    period_type: Mapped[str] = mapped_column(String(16), primary_key=True)
    period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True), primary_key=True)
    period_end: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    used_units: Mapped[int] = mapped_column(Integer, default=0)
    reserved_units: Mapped[int] = mapped_column(Integer, default=0)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    version: Mapped[int] = mapped_column(Integer, default=1)

    __table_args__ = (
        CheckConstraint(
            "period_type IN ('daily', 'weekly')", name="ck_ai_quota_counter_period_type"
        ),
        CheckConstraint(
            "used_units >= 0 AND reserved_units >= 0",
            name="ck_ai_quota_counter_nonnegative",
        ),
        UniqueConstraint(
            "user_id", "period_type", "period_start", name="uq_ai_quota_counter_period"
        ),
        Index("idx_ai_quota_counters_user_end", "user_id", "period_end"),
    )


class AiUsageEvent(Base):
    __tablename__ = "ai_usage_events"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    request_id: Mapped[str] = mapped_column(String(64))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    installation_id: Mapped[str] = mapped_column(String(36), index=True)
    feature: Mapped[str] = mapped_column(String(32), index=True)
    model: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    status: Mapped[str] = mapped_column(String(16), index=True)
    quota_units: Mapped[int] = mapped_column(Integer, default=1)
    prompt_tokens: Mapped[int] = mapped_column(Integer, default=0)
    completion_tokens: Mapped[int] = mapped_column(Integer, default=0)
    total_tokens: Mapped[int] = mapped_column(Integer, default=0)
    latency_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    user_timezone: Mapped[str] = mapped_column(String(64))
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    daily_period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    weekly_period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    error_type: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    __table_args__ = (
        CheckConstraint(
            "status IN ('reserved', 'consumed', 'released', 'blocked')",
            name="ck_ai_usage_status",
        ),
        CheckConstraint("quota_units >= 0", name="ck_ai_usage_quota_nonnegative"),
        CheckConstraint(
            "prompt_tokens >= 0 AND completion_tokens >= 0 AND total_tokens >= 0",
            name="ck_ai_usage_tokens_nonnegative",
        ),
        UniqueConstraint("user_id", "request_id", name="uq_ai_usage_user_request"),
        Index("idx_ai_usage_user_time", "user_id", "occurred_at"),
        Index("idx_ai_usage_feature_status_time", "feature", "status", "occurred_at"),
        Index("idx_ai_usage_model_time", "model", "occurred_at"),
    )
