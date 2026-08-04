from collections.abc import AsyncIterator
from typing import Any
from uuid import uuid4

import httpx
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.analytics.models import Base
from app.config import Settings, get_settings
from app.database import get_session
from app.main import app


@pytest.fixture
async def client() -> AsyncIterator[httpx.AsyncClient]:
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    factory = async_sessionmaker(engine, expire_on_commit=False)

    async def session_override() -> AsyncIterator[AsyncSession]:
        async with factory() as session:
            yield session

    configured = Settings().model_copy(
        update={
            "telemetry_enabled": True,
            "internal_metrics_token": "synthetic-internal-token",
        }
    )
    app.dependency_overrides[get_session] = session_override
    app.dependency_overrides[get_settings] = lambda: configured
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as value:
        yield value
    app.dependency_overrides.clear()
    await engine.dispose()


async def _registered(client: httpx.AsyncClient) -> tuple[str, str, str]:
    installation_id = str(uuid4())
    actor_id = str(uuid4())
    response = await client.post(
        "/api/v1/telemetry/installations",
        json={
            "installation_id": installation_id,
            "anonymous_actor_id": actor_id,
            "platform": "android",
            "app_version": "0.1.0",
        },
    )
    assert response.status_code == 200
    return installation_id, actor_id, response.json()["installation_token"]


async def test_registration_uses_opaque_token_and_auth_is_fail_closed(
    client: httpx.AsyncClient,
) -> None:
    installation_id, actor_id, token = await _registered(client)
    assert installation_id not in token
    assert actor_id not in token

    missing = await client.post(
        "/api/v1/telemetry/sessions/start",
        json={"session_id": str(uuid4()), "started_at": "2026-08-04T08:00:00Z"},
    )
    assert missing.status_code == 401
    assert token not in missing.text


async def test_events_are_whitelisted_idempotent_and_metrics_are_anonymous(
    client: httpx.AsyncClient,
) -> None:
    _, _, token = await _registered(client)
    session_id = str(uuid4())
    headers = {"authorization": f"Bearer {token}"}
    started = await client.post(
        "/api/v1/telemetry/sessions/start",
        headers=headers,
        json={"session_id": session_id, "started_at": "2026-08-04T08:00:00Z"},
    )
    assert started.status_code == 200
    event_id = str(uuid4())
    batch: dict[str, Any] = {
        "events": [
            {
                "event_id": event_id,
                "event_name": "transaction_created",
                "session_id": session_id,
                "occurred_at": "2026-08-04T08:01:00Z",
                "schema_version": 1,
                "properties": {"entry_method": "manual"},
            }
        ]
    }
    accepted = await client.post("/api/v1/telemetry/events/batch", headers=headers, json=batch)
    duplicate = await client.post("/api/v1/telemetry/events/batch", headers=headers, json=batch)
    assert accepted.json() == {"accepted": 1, "duplicates": 0}
    assert duplicate.json() == {"accepted": 0, "duplicates": 1}

    forbidden = batch.copy()
    forbidden["events"] = [
        {**batch["events"][0], "event_id": str(uuid4()), "properties": {"note": "secret"}}
    ]
    rejected = await client.post("/api/v1/telemetry/events/batch", headers=headers, json=forbidden)
    assert rejected.status_code == 422

    unauthorized = await client.get("/api/v1/internal/metrics/overview")
    assert unauthorized.status_code == 401
    metrics = await client.get(
        "/api/v1/internal/metrics/overview",
        headers={"authorization": "Bearer synthetic-internal-token"},
    )
    assert metrics.status_code == 200
    body = metrics.json()
    assert body["identity_scope"] == "anonymous_actor"
    assert body["transaction_count"] >= 0
    assert "installation_id" not in body
    assert "anonymous_actor_id" not in body
