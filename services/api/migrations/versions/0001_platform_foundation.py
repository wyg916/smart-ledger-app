"""Record the P1A platform foundation baseline.

Revision ID: 0001_platform_foundation
Revises:
Create Date: 2026-08-03
"""

from collections.abc import Sequence

revision: str = "0001_platform_foundation"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Intentionally empty: P1A introduces no business tables."""


def downgrade() -> None:
    """Intentionally empty: P1A introduces no business tables."""
