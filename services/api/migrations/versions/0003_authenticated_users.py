"""Add authenticated users, sessions, identities and deletion workflow.

Revision ID: 0003_authenticated_users
Revises: 0002_anonymous_analytics
Create Date: 2026-08-04
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "0003_authenticated_users"
down_revision: str | None = "0002_anonymous_analytics"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("status", sa.String(24), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_users_status", "users", ["status"])
    op.create_table(
        "auth_identities",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("provider", sa.String(32), nullable=False),
        sa.Column("provider_subject_hash", sa.String(64), nullable=False),
        sa.Column("phone_hash", sa.String(64), nullable=True, unique=True),
        sa.Column("display_hint", sa.String(32), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("provider", "provider_subject_hash", name="uq_auth_provider_subject"),
    )
    op.create_index("ix_auth_identities_user_id", "auth_identities", ["user_id"])
    op.create_table(
        "auth_sessions",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("installation_id", sa.String(36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_auth_sessions_user_id", "auth_sessions", ["user_id"])
    op.create_index("ix_auth_sessions_installation_id", "auth_sessions", ["installation_id"])
    op.create_index("ix_auth_sessions_expires_at", "auth_sessions", ["expires_at"])
    op.create_table(
        "refresh_tokens",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "session_id",
            sa.String(36),
            sa.ForeignKey("auth_sessions.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("token_hash", sa.String(64), nullable=False, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("replaced_by_token_id", sa.String(36), nullable=True),
    )
    op.create_index("ix_refresh_tokens_session_id", "refresh_tokens", ["session_id"])
    op.create_index("ix_refresh_tokens_expires_at", "refresh_tokens", ["expires_at"])
    op.create_table(
        "user_installations",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("installation_id", sa.String(36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("user_id", "installation_id", name="uq_user_installation"),
    )
    op.create_index("ix_user_installations_user_id", "user_installations", ["user_id"])
    op.create_index(
        "ix_user_installations_installation_id", "user_installations", ["installation_id"]
    )
    op.create_table(
        "account_deletion_requests",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("idempotency_key_hash", sa.String(64), nullable=False, unique=True),
        sa.Column("status", sa.String(24), nullable=False),
        sa.Column("local_data_action", sa.String(24), nullable=False),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("confirmed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index(
        "ix_account_deletion_requests_user_id", "account_deletion_requests", ["user_id"]
    )
    op.create_index("ix_account_deletion_requests_status", "account_deletion_requests", ["status"])
    op.create_table(
        "review_accounts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column(
            "user_id",
            sa.String(36),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column("username_hash", sa.String(64), nullable=False, unique=True),
        sa.Column("password_salt", sa.String(64), nullable=False),
        sa.Column("password_hash", sa.String(64), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("rotated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table(
        "auth_replay_tokens",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("purpose", sa.String(32), nullable=False),
        sa.Column("token_hash", sa.String(64), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("purpose", "token_hash", name="uq_auth_replay_purpose_token"),
    )
    op.create_index("ix_auth_replay_tokens_expires_at", "auth_replay_tokens", ["expires_at"])
    op.create_table(
        "auth_login_audits",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("user_id", sa.String(36), nullable=True),
        sa.Column("provider", sa.String(32), nullable=False),
        sa.Column("outcome", sa.String(32), nullable=False),
        sa.Column("request_id", sa.String(64), nullable=False),
        sa.Column("request_fingerprint", sa.String(64), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_auth_login_audits_user_id", "auth_login_audits", ["user_id"])
    op.create_index("ix_auth_login_audits_provider", "auth_login_audits", ["provider"])
    op.create_index("ix_auth_login_audits_request_id", "auth_login_audits", ["request_id"])
    op.create_index(
        "ix_auth_login_audits_request_fingerprint",
        "auth_login_audits",
        ["request_fingerprint"],
    )
    op.create_index(
        "idx_auth_audit_provider_fingerprint_time",
        "auth_login_audits",
        ["provider", "request_fingerprint", "created_at"],
    )
    for table in ("analytics_installations", "analytics_sessions", "analytics_events"):
        op.add_column(table, sa.Column("user_id", sa.String(36), nullable=True))
        op.create_index(f"ix_{table}_user_id", table, ["user_id"])


def downgrade() -> None:
    for table in ("analytics_events", "analytics_sessions", "analytics_installations"):
        op.drop_index(f"ix_{table}_user_id", table_name=table)
        op.drop_column(table, "user_id")
    op.drop_table("auth_login_audits")
    op.drop_table("auth_replay_tokens")
    op.drop_table("review_accounts")
    op.drop_table("account_deletion_requests")
    op.drop_table("user_installations")
    op.drop_table("refresh_tokens")
    op.drop_table("auth_sessions")
    op.drop_table("auth_identities")
    op.drop_table("users")
