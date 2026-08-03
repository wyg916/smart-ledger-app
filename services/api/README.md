# Smart Ledger API foundation

This service contains only the P1A platform skeleton: configuration, async database
connectivity, Alembic plumbing, health/version endpoints, and automated checks. It
does not contain authentication, sync, AI, or business data models.

```bash
uv sync --frozen
uv run uvicorn app.main:app --reload
uv run pytest
```

Copy `.env.example` to `.env` only for local development. The checked-in values are
local placeholders and must never be reused for a deployed environment.
