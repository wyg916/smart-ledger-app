from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import uuid4

import httpx
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.analytics.models import Base
from app.auth.models import User
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


async def _login(client: httpx.AsyncClient) -> tuple[str, str]:
    response = await client.post(
        "/api/v1/auth/phone/one-click",
        json={
            "token": "synthetic-phone-token",
            "installation_id": str(uuid4()),
            "timezone": "Asia/Shanghai",
        },
    )
    assert response.status_code == 200, response.text
    return response.json()["tokens"]["access_token"], response.json()["user"]["user_id"]


async def _registered_user(
    client: httpx.AsyncClient,
    access_token: str,
    *,
    app_version: str,
) -> tuple[str, str]:
    installation_id = str(uuid4())
    response = await client.post(
        "/api/v1/telemetry/installations",
        headers={"authorization": f"Bearer {access_token}"},
        json={
            "installation_id": installation_id,
            "anonymous_actor_id": str(uuid4()),
            "platform": "android",
            "android_version": "16",
            "app_version": app_version,
            "application_id": "com.wyg916.smartledger",
            "release_channel": "application_market",
        },
    )
    assert response.status_code == 200, response.text
    return installation_id, response.json()["installation_token"]


async def _authenticated_session_and_event(
    client: httpx.AsyncClient,
    token: str,
    user_id: str,
    occurred_at: datetime,
    *,
    event_name: str = "transaction_created",
) -> None:
    session_id = str(uuid4())
    headers = {"authorization": f"Bearer {token}"}
    session_response = await client.post(
        "/api/v1/telemetry/sessions/start",
        headers=headers,
        json={
            "session_id": session_id,
            "started_at": occurred_at.isoformat(),
            "schema_version": 2,
            "user_id": user_id,
            "identity_scope": "authenticated",
        },
    )
    assert session_response.status_code == 200, session_response.text
    event_response = await client.post(
        "/api/v1/telemetry/events/batch",
        headers=headers,
        json={
            "events": [
                {
                    "event_id": str(uuid4()),
                    "event_name": event_name,
                    "session_id": session_id,
                    "occurred_at": (occurred_at + timedelta(minutes=1)).isoformat(),
                    "schema_version": 2,
                    "user_id": user_id,
                    "identity_scope": "authenticated",
                    "properties": {"entry_method": "manual", "network_type": "wifi"},
                }
            ]
        },
    )
    assert event_response.status_code == 200, event_response.text


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
        "/api/v1/internal/metrics/overview?identity_scope=anonymous_legacy",
        headers={"authorization": "Bearer synthetic-internal-token"},
    )
    assert metrics.status_code == 200
    body = metrics.json()
    assert body["identity_scope"] == "anonymous_legacy"
    assert body["transaction_count"] >= 0
    assert "installation_id" not in body
    assert "anonymous_actor_id" not in body


async def test_authenticated_metrics_deduplicate_user_across_devices_and_sessions(
    client: httpx.AsyncClient,
) -> None:
    access_token, user_id = await _login(client)
    _, first = await _registered_user(client, access_token, app_version="1.0.0")
    _, second = await _registered_user(client, access_token, app_version="1.1.0")
    now = datetime.now(UTC).replace(microsecond=0)
    await _authenticated_session_and_event(client, first, user_id, now)
    await _authenticated_session_and_event(client, second, user_id, now)
    metric_date = now.astimezone().date().isoformat()
    internal = {"authorization": "Bearer synthetic-internal-token"}
    overview = await client.get(
        f"/api/v1/internal/metrics/overview?start_date={metric_date}&end_date={metric_date}",
        headers=internal,
    )
    assert overview.status_code == 200, overview.text
    body = overview.json()
    assert body["identity_scope"] == "authenticated"
    assert body["dau"] == body["wau"] == body["mau"] == 1
    assert body["active_users"] == 1
    assert body["active_installations"] == 2
    assert body["sessions"] == 2
    assert body["transaction_users"] == 1
    assert body["transaction_count"] == 2
    assert body["new_users"] == 1
    assert body["login_successes"] == 1

    provider = await client.get(
        f"/api/v1/internal/metrics/dimensions?start_date={metric_date}"
        f"&end_date={metric_date}&dimension=auth_provider",
        headers=internal,
    )
    assert provider.json()["values"][0]["value"] == "phone_one_click"
    assert provider.json()["values"][0]["users"] == 1
    versions = await client.get(
        f"/api/v1/internal/metrics/dimensions?start_date={metric_date}"
        f"&end_date={metric_date}&dimension=app_version",
        headers=internal,
    )
    assert {row["value"] for row in versions.json()["values"]} == {"1.0.0", "1.1.0"}
    features = await client.get(
        f"/api/v1/internal/metrics/dimensions?start_date={metric_date}"
        f"&end_date={metric_date}&dimension=feature",
        headers=internal,
    )
    assert any(row["value"] == "transactions" for row in features.json()["values"])


async def test_pre_auth_core_event_is_rejected_and_login_failure_never_counts_as_dau(
    client: httpx.AsyncClient,
) -> None:
    _, _, token = await _registered(client)
    session_id = str(uuid4())
    rejected = await client.post(
        "/api/v1/telemetry/events/batch",
        headers={"authorization": f"Bearer {token}"},
        json={
            "events": [
                {
                    "event_id": str(uuid4()),
                    "event_name": "transaction_created",
                    "session_id": session_id,
                    "occurred_at": datetime.now(UTC).isoformat(),
                    "schema_version": 2,
                    "identity_scope": "pre_auth",
                    "properties": {"entry_method": "manual"},
                }
            ]
        },
    )
    assert rejected.status_code == 422
    failed = await client.post(
        "/api/v1/auth/phone/one-click",
        json={"token": "synthetic-invalid-token", "installation_id": str(uuid4())},
    )
    assert failed.status_code == 401
    today = datetime.now(UTC).date().isoformat()
    overview = await client.get(
        f"/api/v1/internal/metrics/overview?start_date={today}&end_date={today}",
        headers={"authorization": "Bearer synthetic-internal-token"},
    )
    assert overview.json()["dau"] == 0
    assert overview.json()["login_failures"] == 1


async def test_metrics_production_missing_internal_secret_is_fail_closed(
    client: httpx.AsyncClient,
) -> None:
    production = Settings().model_copy(
        update={"environment": "production", "internal_metrics_token": ""}
    )
    app.dependency_overrides[get_settings] = lambda: production
    response = await client.get(
        "/api/v1/internal/metrics/overview",
        headers={"authorization": "Bearer any-value"},
    )
    assert response.status_code == 401


@pytest.fixture
async def retention_fixture() -> AsyncIterator[
    tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession]]
]:
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    factory = async_sessionmaker(engine, expire_on_commit=False)

    async def session_override() -> AsyncIterator[AsyncSession]:
        async with factory() as session:
            yield session

    settings = Settings().model_copy(
        update={"telemetry_enabled": True, "internal_metrics_token": "synthetic-internal-token"}
    )
    app.dependency_overrides[get_session] = session_override
    app.dependency_overrides[get_settings] = lambda: settings
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as value:
        yield value, factory
    app.dependency_overrides.clear()
    await engine.dispose()


async def test_d1_and_d7_retention_use_user_cohorts(
    retention_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession]],
) -> None:
    client, factory = retention_fixture
    access_token, user_id = await _login(client)
    _, token = await _registered_user(client, access_token, app_version="1.0.0")
    cohort = datetime.now(UTC).replace(microsecond=0) - timedelta(days=8)
    async with factory() as session:
        user = await session.get(User, user_id)
        assert user is not None
        user.created_at = cohort
        await session.commit()
    await _authenticated_session_and_event(client, token, user_id, cohort + timedelta(days=1))
    await _authenticated_session_and_event(client, token, user_id, cohort + timedelta(days=7))
    cohort_date = cohort.astimezone().date().isoformat()
    response = await client.get(
        f"/api/v1/internal/metrics/retention?start_date={cohort_date}&end_date={cohort_date}",
        headers={"authorization": "Bearer synthetic-internal-token"},
    )
    assert response.status_code == 200, response.text
    assert response.json()["d1_retention"] == 1.0
    assert response.json()["d7_retention"] == 1.0
