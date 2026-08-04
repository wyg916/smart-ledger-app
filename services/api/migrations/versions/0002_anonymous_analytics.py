"""Add anonymous installation, session, event and daily metric tables.

Revision ID: 0002_anonymous_analytics
Revises: 0001_platform_foundation
Create Date: 2026-08-04
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0002_anonymous_analytics"
down_revision: str | None = "0001_platform_foundation"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "analytics_installations",
        sa.Column("installation_id", sa.String(36), primary_key=True),
        sa.Column("anonymous_actor_id", sa.String(36), nullable=False),
        sa.Column("token_hash", sa.String(64), nullable=False, unique=True),
        sa.Column("platform", sa.String(16), nullable=False),
        sa.Column("app_version", sa.String(32), nullable=False),
        sa.Column("first_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index(
        "ix_analytics_installations_anonymous_actor_id",
        "analytics_installations",
        ["anonymous_actor_id"],
    )
    op.create_table(
        "analytics_sessions",
        sa.Column("session_id", sa.String(36), primary_key=True),
        sa.Column(
            "installation_id",
            sa.String(36),
            sa.ForeignKey("analytics_installations.installation_id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("anonymous_actor_id", sa.String(36), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_analytics_sessions_installation_id", "analytics_sessions", ["installation_id"]
    )
    op.create_index(
        "ix_analytics_sessions_anonymous_actor_id",
        "analytics_sessions",
        ["anonymous_actor_id"],
    )
    op.create_table(
        "analytics_events",
        sa.Column("event_id", sa.String(36), primary_key=True),
        sa.Column(
            "installation_id",
            sa.String(36),
            sa.ForeignKey("analytics_installations.installation_id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("anonymous_actor_id", sa.String(36), nullable=False),
        sa.Column("session_id", sa.String(36), nullable=False),
        sa.Column("event_name", sa.String(64), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("schema_version", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("properties_json", sa.Text(), nullable=False, server_default="{}"),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_analytics_events_installation_id", "analytics_events", ["installation_id"])  # noqa: E501
    op.create_index(
        "ix_analytics_events_anonymous_actor_id", "analytics_events", ["anonymous_actor_id"]
    )
    op.create_index("ix_analytics_events_session_id", "analytics_events", ["session_id"])
    op.create_index("ix_analytics_events_event_name", "analytics_events", ["event_name"])
    op.create_index("ix_analytics_events_occurred_at", "analytics_events", ["occurred_at"])
    op.create_index(
        "idx_analytics_events_actor_time",
        "analytics_events",
        ["anonymous_actor_id", "occurred_at"],
    )
    op.create_table(
        "analytics_daily_metrics",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("metric_date", sa.Date(), nullable=False),
        sa.Column("metric_name", sa.String(64), nullable=False),
        sa.Column("metric_value", sa.Integer(), nullable=False),
        sa.Column("calculated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("metric_date", "metric_name"),
    )


def downgrade() -> None:
    op.drop_table("analytics_daily_metrics")
    op.drop_table("analytics_events")
    op.drop_table("analytics_sessions")
    op.drop_table("analytics_installations")
