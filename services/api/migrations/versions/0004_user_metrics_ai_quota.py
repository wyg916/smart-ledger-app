"""Add authenticated product metrics and atomic AI quota tables.

Revision ID: 0004_user_metrics_ai_quota
Revises: 0003_authenticated_users
Create Date: 2026-08-05
"""

from collections.abc import Sequence
from datetime import UTC, datetime

import sqlalchemy as sa
from alembic import op

revision: str = "0004_user_metrics_ai_quota"
down_revision: str | None = "0003_authenticated_users"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "users", sa.Column("timezone", sa.String(64), nullable=False, server_default="UTC")
    )
    op.add_column(
        "users", sa.Column("timezone_updated_at", sa.DateTime(timezone=True), nullable=True)
    )
    op.add_column(
        "users", sa.Column("plan_code", sa.String(32), nullable=False, server_default="free")
    )
    op.create_index("ix_users_plan_code", "users", ["plan_code"])
    op.add_column(
        "auth_sessions",
        sa.Column("auth_provider", sa.String(32), nullable=False, server_default="unknown"),
    )
    op.create_index("ix_auth_sessions_auth_provider", "auth_sessions", ["auth_provider"])

    op.add_column(
        "analytics_installations",
        sa.Column("android_version", sa.String(32), nullable=False, server_default="unknown"),
    )
    op.add_column(
        "analytics_installations",
        sa.Column("application_id", sa.String(128), nullable=False, server_default="unknown"),
    )
    op.add_column(
        "analytics_installations",
        sa.Column("release_channel", sa.String(40), nullable=False, server_default="unknown"),
    )
    op.add_column(
        "analytics_installations",
        sa.Column("auth_provider", sa.String(32), nullable=False, server_default="unknown"),
    )
    op.add_column(
        "analytics_installations",
        sa.Column("user_timezone", sa.String(64), nullable=False, server_default="UTC"),
    )
    op.add_column(
        "analytics_installations",
        sa.Column(
            "identity_scope",
            sa.String(24),
            nullable=False,
            server_default="anonymous_legacy",
        ),
    )
    for column in ("application_id", "release_channel", "auth_provider", "identity_scope"):
        op.create_index(f"ix_analytics_installations_{column}", "analytics_installations", [column])

    op.add_column(
        "analytics_sessions",
        sa.Column("auth_provider", sa.String(32), nullable=False, server_default="unknown"),
    )
    op.add_column(
        "analytics_sessions",
        sa.Column("user_timezone", sa.String(64), nullable=False, server_default="UTC"),
    )
    op.add_column(
        "analytics_sessions",
        sa.Column(
            "identity_scope",
            sa.String(24),
            nullable=False,
            server_default="anonymous_legacy",
        ),
    )
    op.add_column(
        "analytics_sessions",
        sa.Column("local_started_date", sa.Date(), nullable=False, server_default="1970-01-01"),
    )
    for column in ("auth_provider", "identity_scope", "local_started_date"):
        op.create_index(f"ix_analytics_sessions_{column}", "analytics_sessions", [column])

    op.add_column(
        "analytics_events",
        sa.Column(
            "identity_scope",
            sa.String(24),
            nullable=False,
            server_default="anonymous_legacy",
        ),
    )
    op.add_column(
        "analytics_events",
        sa.Column("event_date", sa.Date(), nullable=False, server_default="1970-01-01"),
    )
    op.add_column(
        "analytics_events",
        sa.Column("user_timezone", sa.String(64), nullable=False, server_default="UTC"),
    )
    op.add_column(
        "analytics_events",
        sa.Column("network_type", sa.String(16), nullable=False, server_default="unknown"),
    )
    for column in ("identity_scope", "event_date", "network_type"):
        op.create_index(f"ix_analytics_events_{column}", "analytics_events", [column])
    op.create_index(
        "idx_analytics_events_user_time", "analytics_events", ["user_id", "occurred_at"]
    )
    op.create_index(
        "idx_analytics_events_scope_date", "analytics_events", ["identity_scope", "event_date"]
    )

    bind = op.get_bind()
    bind.execute(
        sa.text(
            "UPDATE analytics_installations SET identity_scope = "
            "CASE WHEN user_id IS NULL THEN 'anonymous_legacy' ELSE 'authenticated' END"
        )
    )
    bind.execute(
        sa.text(
            "UPDATE analytics_sessions SET identity_scope = "
            "CASE WHEN user_id IS NULL THEN 'anonymous_legacy' ELSE 'authenticated' END"
        )
    )
    bind.execute(
        sa.text(
            "UPDATE analytics_events SET identity_scope = "
            "CASE WHEN user_id IS NULL THEN 'anonymous_legacy' ELSE 'authenticated' END"
        )
    )
    if bind.dialect.name == "sqlite":
        bind.execute(sa.text("UPDATE analytics_sessions SET local_started_date = date(started_at)"))
        bind.execute(sa.text("UPDATE analytics_events SET event_date = date(occurred_at)"))
    else:
        bind.execute(
            sa.text("UPDATE analytics_sessions SET local_started_date = CAST(started_at AS DATE)")
        )
        bind.execute(sa.text("UPDATE analytics_events SET event_date = CAST(occurred_at AS DATE)"))

    op.create_table(
        "ai_quota_plans",
        sa.Column("plan_code", sa.String(32), primary_key=True),
        sa.Column("daily_limit", sa.Integer(), nullable=False),
        sa.Column("weekly_limit", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("effective_from", sa.DateTime(timezone=True), nullable=False),
        sa.Column("effective_to", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("daily_limit > 0", name="ck_ai_quota_plan_daily_positive"),
        sa.CheckConstraint("weekly_limit >= daily_limit", name="ck_ai_quota_plan_weekly_daily"),
    )
    op.create_index("ix_ai_quota_plans_is_active", "ai_quota_plans", ["is_active"])
    op.bulk_insert(
        sa.table(
            "ai_quota_plans",
            sa.column("plan_code", sa.String),
            sa.column("daily_limit", sa.Integer),
            sa.column("weekly_limit", sa.Integer),
            sa.column("is_active", sa.Boolean),
            sa.column("effective_from", sa.DateTime(timezone=True)),
            sa.column("effective_to", sa.DateTime(timezone=True)),
        ),
        [
            {
                "plan_code": "free",
                "daily_limit": 2,
                "weekly_limit": 10,
                "is_active": True,
                "effective_from": datetime.now(UTC),
                "effective_to": None,
            }
        ],
    )
    op.create_table(
        "ai_quota_counters",
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column("period_type", sa.String(16), primary_key=True),
        sa.Column("period_start", sa.DateTime(timezone=True), primary_key=True),
        sa.Column("period_end", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_units", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("reserved_units", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False, server_default="1"),
        sa.UniqueConstraint(
            "user_id", "period_type", "period_start", name="uq_ai_quota_counter_period"
        ),
        sa.CheckConstraint(
            "period_type IN ('daily', 'weekly')", name="ck_ai_quota_counter_period_type"
        ),
        sa.CheckConstraint(
            "used_units >= 0 AND reserved_units >= 0",
            name="ck_ai_quota_counter_nonnegative",
        ),
    )
    op.create_index(
        "idx_ai_quota_counters_user_end", "ai_quota_counters", ["user_id", "period_end"]
    )
    op.create_table(
        "ai_usage_events",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("request_id", sa.String(64), nullable=False),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("installation_id", sa.String(36), nullable=False),
        sa.Column("feature", sa.String(32), nullable=False),
        sa.Column("model", sa.String(80), nullable=True),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("quota_units", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("prompt_tokens", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("completion_tokens", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_tokens", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("latency_ms", sa.Integer(), nullable=True),
        sa.Column("user_timezone", sa.String(64), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("daily_period_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("weekly_period_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("error_type", sa.String(64), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("user_id", "request_id", name="uq_ai_usage_user_request"),
        sa.CheckConstraint(
            "status IN ('reserved', 'consumed', 'released', 'blocked')",
            name="ck_ai_usage_status",
        ),
        sa.CheckConstraint("quota_units >= 0", name="ck_ai_usage_quota_nonnegative"),
        sa.CheckConstraint(
            "prompt_tokens >= 0 AND completion_tokens >= 0 AND total_tokens >= 0",
            name="ck_ai_usage_tokens_nonnegative",
        ),
    )
    for column in (
        "user_id",
        "installation_id",
        "feature",
        "model",
        "status",
        "occurred_at",
        "error_type",
    ):
        op.create_index(f"ix_ai_usage_events_{column}", "ai_usage_events", [column])
    op.create_index("idx_ai_usage_user_time", "ai_usage_events", ["user_id", "occurred_at"])
    op.create_index(
        "idx_ai_usage_feature_status_time",
        "ai_usage_events",
        ["feature", "status", "occurred_at"],
    )
    op.create_index("idx_ai_usage_model_time", "ai_usage_events", ["model", "occurred_at"])


def downgrade() -> None:
    op.drop_table("ai_usage_events")
    op.drop_table("ai_quota_counters")
    op.drop_table("ai_quota_plans")

    op.drop_index("idx_analytics_events_scope_date", table_name="analytics_events")
    op.drop_index("idx_analytics_events_user_time", table_name="analytics_events")
    for column in ("network_type", "event_date", "identity_scope"):
        op.drop_index(f"ix_analytics_events_{column}", table_name="analytics_events")
    for column in ("network_type", "user_timezone", "event_date", "identity_scope"):
        op.drop_column("analytics_events", column)

    for column in ("local_started_date", "identity_scope", "auth_provider"):
        op.drop_index(f"ix_analytics_sessions_{column}", table_name="analytics_sessions")
    for column in ("local_started_date", "identity_scope", "user_timezone", "auth_provider"):
        op.drop_column("analytics_sessions", column)

    for column in ("identity_scope", "auth_provider", "release_channel", "application_id"):
        op.drop_index(f"ix_analytics_installations_{column}", table_name="analytics_installations")
    for column in (
        "identity_scope",
        "user_timezone",
        "auth_provider",
        "release_channel",
        "application_id",
        "android_version",
    ):
        op.drop_column("analytics_installations", column)

    op.drop_index("ix_auth_sessions_auth_provider", table_name="auth_sessions")
    op.drop_column("auth_sessions", "auth_provider")
    op.drop_index("ix_users_plan_code", table_name="users")
    op.drop_column("users", "plan_code")
    op.drop_column("users", "timezone_updated_at")
    op.drop_column("users", "timezone")
