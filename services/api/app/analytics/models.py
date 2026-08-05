from datetime import UTC, date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


def utc_now() -> datetime:
    return datetime.now(UTC)


class Base(DeclarativeBase):
    pass


class AnalyticsInstallation(Base):
    __tablename__ = "analytics_installations"

    installation_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    anonymous_actor_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str | None] = mapped_column(String(36), index=True, nullable=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    platform: Mapped[str] = mapped_column(String(16))
    android_version: Mapped[str] = mapped_column(String(32), default="unknown")
    app_version: Mapped[str] = mapped_column(String(32))
    application_id: Mapped[str] = mapped_column(String(128), default="unknown", index=True)
    release_channel: Mapped[str] = mapped_column(String(40), default="unknown", index=True)
    auth_provider: Mapped[str] = mapped_column(String(32), default="unknown", index=True)
    user_timezone: Mapped[str] = mapped_column(String(64), default="UTC")
    identity_scope: Mapped[str] = mapped_column(String(24), default="anonymous_legacy", index=True)
    first_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)


class AnalyticsSession(Base):
    __tablename__ = "analytics_sessions"

    session_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    installation_id: Mapped[str] = mapped_column(
        ForeignKey("analytics_installations.installation_id", ondelete="CASCADE"), index=True
    )
    anonymous_actor_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str | None] = mapped_column(String(36), index=True, nullable=True)
    auth_provider: Mapped[str] = mapped_column(String(32), default="unknown", index=True)
    user_timezone: Mapped[str] = mapped_column(String(64), default="UTC")
    identity_scope: Mapped[str] = mapped_column(String(24), default="anonymous_legacy", index=True)
    local_started_date: Mapped[date] = mapped_column(Date, index=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class AnalyticsEvent(Base):
    __tablename__ = "analytics_events"

    event_id: Mapped[str] = mapped_column(String(36), primary_key=True)
    installation_id: Mapped[str] = mapped_column(
        ForeignKey("analytics_installations.installation_id", ondelete="CASCADE"), index=True
    )
    anonymous_actor_id: Mapped[str] = mapped_column(String(36), index=True)
    user_id: Mapped[str | None] = mapped_column(String(36), index=True, nullable=True)
    identity_scope: Mapped[str] = mapped_column(String(24), default="anonymous_legacy", index=True)
    session_id: Mapped[str] = mapped_column(String(36), index=True)
    event_name: Mapped[str] = mapped_column(String(64), index=True)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    event_date: Mapped[date] = mapped_column(Date, index=True)
    user_timezone: Mapped[str] = mapped_column(String(64), default="UTC")
    network_type: Mapped[str] = mapped_column(String(16), default="unknown", index=True)
    schema_version: Mapped[int] = mapped_column(Integer, default=1)
    properties_json: Mapped[str] = mapped_column(Text, default="{}")
    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    __table_args__ = (
        Index("idx_analytics_events_actor_time", "anonymous_actor_id", "occurred_at"),
        Index("idx_analytics_events_user_time", "user_id", "occurred_at"),
        Index("idx_analytics_events_scope_date", "identity_scope", "event_date"),
    )


class AnalyticsDailyMetric(Base):
    __tablename__ = "analytics_daily_metrics"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    metric_date: Mapped[date] = mapped_column(Date)
    metric_name: Mapped[str] = mapped_column(String(64))
    metric_value: Mapped[int] = mapped_column(Integer)
    calculated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utc_now)

    __table_args__ = (UniqueConstraint("metric_date", "metric_name"),)
