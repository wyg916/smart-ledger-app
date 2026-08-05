import asyncio
from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any
from uuid import uuid4

import httpx
import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.ai.errors import AiError, map_upstream_status
from app.ai.models import AiQuotaCounter, AiUsageEvent
from app.ai.providers.base import AiScenario, ProviderResult
from app.ai.providers.fake import FakeProvider
from app.ai.quota import QuotaReservation, QuotaService, quota_periods
from app.ai.routes import get_ai_provider
from app.ai.schemas import TokenUsage
from app.analytics.models import Base
from app.auth.models import User
from app.config import Settings, get_settings
from app.database import get_session
from app.main import app


class MutableClock:
    def __init__(self, value: datetime) -> None:
        self.value = value

    def __call__(self) -> datetime:
        return self.value


class FailingProvider:
    def __init__(self, error: AiError) -> None:
        self.error = error
        self.calls = 0

    async def list_models(self) -> list[str]:
        return []

    async def generate(
        self, scenario: AiScenario, model: str, payload: dict[str, Any], repair: bool = False
    ) -> ProviderResult:
        del scenario, model, payload, repair
        self.calls += 1
        raise self.error


def configured_settings(**updates: Any) -> Settings:
    baseline = Settings().model_copy(
        update={
            "environment": "development",
            "moonshot_api_key": "synthetic-key",
            "kimi_ai_enabled": True,
            "kimi_provider": "fake",
            "kimi_fast_model": "fake-fast",
            "auth_jwt_secret": "synthetic-auth-secret-at-least-thirty-two-characters",
            "auth_identity_pepper": "synthetic-auth-pepper-at-least-thirty-two-characters",
            "phone_auth_provider": "fake",
            "ai_model_pricing_json": (
                '{"fake-fast":{"prompt_per_million_usd":1,"completion_per_million_usd":2}}'
            ),
        }
    )
    return baseline.model_copy(update=updates)


def monthly_payload() -> dict[str, Any]:
    comparison = {
        "previous_minor": 8000,
        "delta_minor": 2000,
        "change_basis_points": 2500,
        "has_baseline": True,
    }
    return {
        "month": "2026-08",
        "currency_code": "CNY",
        "time_zone_id": "Asia/Shanghai",
        "income_minor": 20000,
        "expense_minor": 10000,
        "net_minor": 10000,
        "income_comparison": comparison,
        "expense_comparison": comparison,
        "daily_trend": [],
        "income_categories": [],
        "expense_categories": [],
        "accounts": [],
    }


@pytest.fixture
async def quota_http() -> AsyncIterator[
    tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings]
]:
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    factory = async_sessionmaker(engine, expire_on_commit=False)

    async def session_override() -> AsyncIterator[AsyncSession]:
        async with factory() as session:
            yield session

    settings = configured_settings()
    app.dependency_overrides[get_session] = session_override
    app.dependency_overrides[get_settings] = lambda: settings
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        login = await client.post(
            "/api/v1/auth/phone/one-click",
            json={
                "token": "synthetic-phone-token",
                "installation_id": str(uuid4()),
                "timezone": "Asia/Shanghai",
            },
        )
        assert login.status_code == 200, login.text
        client.headers["authorization"] = f"Bearer {login.json()['tokens']['access_token']}"
        yield client, factory, settings
    app.dependency_overrides.clear()
    await engine.dispose()


async def test_http_daily_limit_is_authoritative_and_records_usage(
    quota_http: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, factory, _ = quota_http
    provider = FakeProvider()
    app.dependency_overrides[get_ai_provider] = lambda: provider

    responses = [
        await client.post(
            "/api/v1/ai/monthly-summary",
            json=monthly_payload(),
            headers={"x-request-id": str(uuid4())},
        )
        for _ in range(3)
    ]
    assert [response.status_code for response in responses] == [200, 200, 429]
    blocked = responses[-1].json()
    assert blocked["error"]["code"] == "AI_QUOTA_EXCEEDED"
    assert blocked["daily_limit"] == 2
    assert blocked["daily_used"] == 2
    assert blocked["daily_remaining"] == 0
    assert blocked["weekly_remaining"] == 8
    assert provider.calls == 2

    quota = await client.get("/api/v1/ai/quota")
    assert quota.status_code == 200
    assert quota.json()["daily_used"] == 2
    assert quota.json()["weekly_used"] == 2
    async with factory() as session:
        rows = (await session.execute(select(AiUsageEvent))).scalars().all()
        assert [row.status for row in rows].count("consumed") == 2
        assert [row.status for row in rows].count("blocked") == 1
        assert sum(row.total_tokens for row in rows) == 60
        assert all(row.prompt_tokens in {0, 10} for row in rows)


async def test_request_id_is_idempotent_and_validation_does_not_consume(
    quota_http: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, _, _ = quota_http
    provider = FakeProvider()
    app.dependency_overrides[get_ai_provider] = lambda: provider
    invalid = monthly_payload() | {"income_minor": 1.5}
    rejected = await client.post(
        "/api/v1/ai/monthly-summary",
        json=invalid,
        headers={"x-request-id": str(uuid4())},
    )
    assert rejected.status_code == 422
    assert (await client.get("/api/v1/ai/quota")).json()["daily_used"] == 0

    request_id = str(uuid4())
    first = await client.post(
        "/api/v1/ai/monthly-summary",
        json=monthly_payload(),
        headers={"x-request-id": request_id},
    )
    duplicate = await client.post(
        "/api/v1/ai/monthly-summary",
        json=monthly_payload(),
        headers={"x-request-id": request_id},
    )
    assert first.status_code == 200
    assert duplicate.status_code == 409
    assert duplicate.json()["error"]["code"] == "AI_REQUEST_ALREADY_PROCESSED"
    assert duplicate.json()["request_status"] == "consumed"
    assert provider.calls == 1
    assert (await client.get("/api/v1/ai/quota")).json()["daily_used"] == 1


@pytest.mark.parametrize(
    "error",
    [map_upstream_status(401), map_upstream_status(403), map_upstream_status(429)],
)
async def test_pre_generation_provider_failures_release_reservation(
    quota_http: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
    error: AiError,
) -> None:
    client, factory, _ = quota_http
    provider = FailingProvider(error)
    app.dependency_overrides[get_ai_provider] = lambda: provider
    response = await client.post(
        "/api/v1/ai/monthly-summary",
        json=monthly_payload(),
        headers={"x-request-id": str(uuid4())},
    )
    assert response.status_code == error.status_code
    assert (await client.get("/api/v1/ai/quota")).json()["daily_used"] == 0
    async with factory() as session:
        usage = (await session.execute(select(AiUsageEvent))).scalar_one()
        assert usage.status == "released"
        assert usage.error_type == error.code


async def test_timeout_and_invalid_structured_output_consume_once(
    quota_http: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, factory, _ = quota_http
    timeout = FailingProvider(AiError("AI_UPSTREAM_TIMEOUT", "timed out", 504))
    app.dependency_overrides[get_ai_provider] = lambda: timeout
    timed_out = await client.post(
        "/api/v1/ai/monthly-summary",
        json=monthly_payload(),
        headers={"x-request-id": str(uuid4())},
    )
    assert timed_out.status_code == 504

    invalid = FakeProvider(always_invalid=True)
    app.dependency_overrides[get_ai_provider] = lambda: invalid
    malformed = await client.post(
        "/api/v1/ai/monthly-summary",
        json=monthly_payload(),
        headers={"x-request-id": str(uuid4())},
    )
    assert malformed.status_code == 502
    assert invalid.calls == 2
    quota = (await client.get("/api/v1/ai/quota")).json()
    assert quota["daily_used"] == 2
    async with factory() as session:
        rows = (await session.execute(select(AiUsageEvent))).scalars().all()
        assert {row.error_type for row in rows} == {
            "AI_UPSTREAM_TIMEOUT",
            "AI_INVALID_RESPONSE",
        }
        assert all(row.status == "consumed" for row in rows)


async def _direct_database(
    path: Path | None = None,
) -> tuple[
    async_sessionmaker[AsyncSession],
    User,
    Settings,
    Any,
]:
    url = "sqlite+aiosqlite:///:memory:" if path is None else f"sqlite+aiosqlite:///{path}"
    engine = create_async_engine(url, connect_args={"timeout": 20})
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    factory = async_sessionmaker(engine, expire_on_commit=False)
    now = datetime(2026, 8, 3, 0, 0, tzinfo=UTC)
    user = User(
        id=str(uuid4()),
        status="active",
        timezone="UTC",
        plan_code="free",
        created_at=now,
        updated_at=now,
    )
    async with factory() as session:
        session.add(user)
        await session.commit()
    return factory, user, configured_settings(), engine


async def _consume(service: QuotaService, reservation: QuotaReservation) -> None:
    await service.consume(
        reservation,
        model="fake-fast",
        usage=TokenUsage(prompt_tokens=1, completion_tokens=2, total_tokens=3),
        latency_ms=5,
    )


async def test_weekly_limit_and_monday_boundary() -> None:
    factory, user, settings, engine = await _direct_database()
    clock = MutableClock(datetime(2026, 8, 3, 1, tzinfo=UTC))  # Monday
    async with factory() as session:
        stored = await session.get(User, user.id)
        assert stored is not None
        service = QuotaService(session, settings, clock)
        for day in range(5):
            clock.value = datetime(2026, 8, 3 + day, 1, tzinfo=UTC)
            for _ in range(2):
                await _consume(
                    service,
                    await service.reserve(
                        user=stored,
                        installation_id=str(uuid4()),
                        feature="chat",
                        request_id=str(uuid4()),
                    ),
                )
        clock.value = datetime(2026, 8, 8, 1, tzinfo=UTC)
        with pytest.raises(AiError, match="AI usage quota exceeded") as caught:
            await service.reserve(
                user=stored,
                installation_id=str(uuid4()),
                feature="chat",
                request_id=str(uuid4()),
            )
        assert caught.value.details is not None
        assert caught.value.details["limit_reason"] == "weekly_limit"
        clock.value = datetime(2026, 8, 10, 0, 0, tzinfo=UTC)
        status = await service.status(stored)
        assert status.weekly_used == 0
        assert status.weekly_remaining == 10
    await engine.dispose()


async def test_iana_day_boundary_and_stale_reservation_recovery() -> None:
    factory, user, settings, engine = await _direct_database()
    clock = MutableClock(datetime(2026, 8, 3, 15, 59, tzinfo=UTC))
    async with factory() as session:
        stored = await session.get(User, user.id)
        assert stored is not None
        stored.timezone = "Asia/Shanghai"
        await session.commit()
        service = QuotaService(session, settings, clock)
        reservation = await service.reserve(
            user=stored,
            installation_id=str(uuid4()),
            feature="chat",
            request_id=str(uuid4()),
        )
        assert (await service.status(stored)).daily_remaining == 1
        clock.value += timedelta(minutes=11)
        recovered = await service.status(stored)
        assert recovered.daily_remaining == 2
        usage = await session.get(AiUsageEvent, reservation.event_id)
        assert usage is not None
        assert usage.status == "released"
        assert usage.error_type == "reservation_expired"
        clock.value = datetime(2026, 8, 4, 15, 59, tzinfo=UTC)
        before = quota_periods(clock.value, stored.timezone)
        clock.value += timedelta(minutes=1)
        after = quota_periods(clock.value, stored.timezone)
        assert before.daily_start != after.daily_start
        assert after.daily_start == datetime(2026, 8, 4, 16, tzinfo=UTC)
    await engine.dispose()


async def test_timezone_change_carries_usage_and_rejects_active_reservation() -> None:
    factory, user, settings, engine = await _direct_database()
    clock = MutableClock(datetime(2026, 8, 3, 16, 30, tzinfo=UTC))
    async with factory() as session:
        stored = await session.get(User, user.id)
        assert stored is not None
        service = QuotaService(session, settings, clock)
        first = await service.reserve(
            user=stored,
            installation_id=str(uuid4()),
            feature="chat",
            request_id=str(uuid4()),
        )
        await _consume(service, first)

        assert await service.prepare_timezone_change(stored, "Asia/Shanghai")
        stored.timezone = "Asia/Shanghai"
        await session.commit()
        carried = await service.status(stored)
        assert carried.daily_used == 1
        assert carried.weekly_used == 1
        assert carried.daily_remaining == 1

        await service.reserve(
            user=stored,
            installation_id=str(uuid4()),
            feature="chat",
            request_id=str(uuid4()),
        )
        assert not await service.prepare_timezone_change(stored, "America/New_York")
        assert stored.timezone == "Asia/Shanghai"
    await engine.dispose()


async def test_concurrent_reservations_never_exceed_daily_limit(tmp_path: Path) -> None:
    factory, user, settings, engine = await _direct_database(tmp_path / "quota.sqlite")
    clock = MutableClock(datetime(2026, 8, 3, 2, tzinfo=UTC))

    async def reserve_once() -> QuotaReservation | AiError:
        async with factory() as session:
            stored = await session.get(User, user.id)
            assert stored is not None
            try:
                return await QuotaService(session, settings, clock).reserve(
                    user=stored,
                    installation_id=str(uuid4()),
                    feature="chat",
                    request_id=str(uuid4()),
                )
            except AiError as error:
                return error

    results = await asyncio.gather(*(reserve_once() for _ in range(3)))
    assert sum(isinstance(value, QuotaReservation) for value in results) == 2
    assert (
        sum(isinstance(value, AiError) and value.code == "AI_QUOTA_EXCEEDED" for value in results)
        == 1
    )
    async with factory() as session:
        counters = (await session.execute(select(AiQuotaCounter))).scalars().all()
        assert max(counter.used_units + counter.reserved_units for counter in counters) <= 2
    await engine.dispose()


async def test_review_plan_is_bounded_and_server_controlled(
    quota_http: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, factory, settings = quota_http
    ordinary_switch = await client.put(
        "/api/v1/account/timezone",
        json={"timezone": "UTC", "plan_code": "review"},
    )
    assert ordinary_switch.status_code == 422
    async with factory() as session:
        user = (await session.execute(select(User))).scalar_one()
        user.plan_code = "review"
        await session.commit()
        status = await QuotaService(session, settings).status(user)
        assert status.daily_limit == settings.ai_review_daily_limit
        assert status.weekly_limit == settings.ai_review_weekly_limit
        assert status.daily_limit < 1_000_000
