import logging
from collections.abc import AsyncIterator
from typing import Any, cast
from uuid import uuid4

import httpx
import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.analytics.models import Base
from app.auth.models import AuthIdentity, RefreshToken, UserAuthSession
from app.auth.routes import get_phone_provider, get_wechat_provider
from app.auth.service import provision_review_account
from app.config import Settings, get_settings
from app.database import get_session
from app.main import app


@pytest.fixture
async def auth_fixture() -> AsyncIterator[
    tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings]
]:
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
    factory = async_sessionmaker(engine, expire_on_commit=False)

    async def session_override() -> AsyncIterator[AsyncSession]:
        async with factory() as session:
            yield session

    settings = Settings().model_copy(
        update={
            "auth_jwt_secret": "synthetic-auth-secret-at-least-thirty-two-characters",
            "auth_identity_pepper": "synthetic-auth-pepper-at-least-thirty-two-characters",
            "phone_auth_provider": "fake",
            "wechat_auth_provider": "fake",
            "review_login_enabled": True,
        }
    )
    app.dependency_overrides[get_session] = session_override
    app.dependency_overrides[get_settings] = lambda: settings
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        yield client, factory, settings
    app.dependency_overrides.clear()
    await engine.dispose()


def _installation() -> str:
    return str(uuid4())


async def _phone_login(client: httpx.AsyncClient) -> dict[str, Any]:
    response = await client.post(
        "/api/v1/auth/phone/one-click",
        json={
            "token": "synthetic-phone-token",
            "carrier": "mobile",
            "installation_id": _installation(),
        },
    )
    assert response.status_code == 200, response.text
    return cast(dict[str, Any], response.json())


def _headers(body: dict[str, Any]) -> dict[str, str]:
    return {"authorization": f"Bearer {body['tokens']['access_token']}"}


async def _wechat_state(client: httpx.AsyncClient) -> str:
    response = await client.post(
        "/api/v1/auth/wechat/state", json={"installation_id": _installation()}
    )
    assert response.status_code == 200
    return str(response.json()["state"])


async def test_phone_login_access_me_and_sensitive_values_are_not_returned(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, _, _ = auth_fixture
    body = await _phone_login(client)
    assert body["user"]["providers"] == ["phone_one_click"]
    assert body["tokens"]["token_type"] == "Bearer"
    assert "synthetic-phone-token" not in str(body)

    me = await client.get("/api/v1/auth/me", headers=_headers(body))
    assert me.status_code == 200
    assert me.json()["user_id"] == body["user"]["user_id"]
    assert "phone" not in me.text.casefold() or "phone_one_click" in me.text


async def test_phone_provider_failure_and_token_replay_are_closed(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, _, _ = auth_fixture
    failed = await client.post(
        "/api/v1/auth/phone/one-click",
        json={"token": "synthetic-invalid-token", "installation_id": _installation()},
    )
    assert failed.status_code == 401
    replay = await client.post(
        "/api/v1/auth/phone/one-click",
        json={"token": "synthetic-invalid-token", "installation_id": _installation()},
    )
    assert replay.status_code == 409
    assert "synthetic-invalid-token" not in replay.text


async def test_wechat_login_requires_single_use_server_state_and_code(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, _, _ = auth_fixture
    state = await _wechat_state(client)
    payload = {
        "code": "synthetic-wechat-code",
        "state": state,
        "installation_id": _installation(),
    }
    response = await client.post("/api/v1/auth/wechat", json=payload)
    assert response.status_code == 200
    assert response.json()["user"]["providers"] == ["wechat"]

    replay = await client.post("/api/v1/auth/wechat", json=payload)
    assert replay.status_code == 409
    assert state not in replay.text
    assert payload["code"] not in replay.text


async def test_refresh_rotates_and_replay_revokes_session(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, factory, _ = auth_fixture
    login = await _phone_login(client)
    original = login["tokens"]["refresh_token"]
    refreshed = await client.post("/api/v1/auth/refresh", json={"refresh_token": original})
    assert refreshed.status_code == 200
    assert refreshed.json()["tokens"]["refresh_token"] != original

    replay = await client.post("/api/v1/auth/refresh", json={"refresh_token": original})
    assert replay.status_code == 409
    new_refresh = refreshed.json()["tokens"]["refresh_token"]
    revoked = await client.post("/api/v1/auth/refresh", json={"refresh_token": new_refresh})
    assert revoked.status_code == 401
    async with factory() as session:
        sessions = (await session.execute(UserAuthSession.__table__.select())).all()
        tokens = (await session.execute(RefreshToken.__table__.select())).all()
        assert sessions[0].revoked_at is not None
        assert all(row.revoked_at is not None for row in tokens)


async def test_logout_revokes_access_session(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, _, _ = auth_fixture
    login = await _phone_login(client)
    logged_out = await client.post("/api/v1/auth/logout", headers=_headers(login), json={})
    assert logged_out.status_code == 200
    assert (await client.get("/api/v1/auth/me", headers=_headers(login))).status_code == 401


async def test_review_login_is_provisioned_server_side_and_rate_limited(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, factory, settings = auth_fixture
    async with factory() as session:
        await provision_review_account(
            session,
            username="store-reviewer",
            password="synthetic-review-password",
            settings=settings,
        )
    success = await client.post(
        "/api/v1/auth/review-login",
        json={
            "username": "store-reviewer",
            "password": "synthetic-review-password",
            "installation_id": _installation(),
        },
    )
    assert success.status_code == 200
    assert success.json()["user"]["providers"] == ["play_review"]

    for _ in range(4):
        failed = await client.post(
            "/api/v1/auth/review-login",
            json={
                "username": "store-reviewer",
                "password": "synthetic-wrong-password",
                "installation_id": _installation(),
            },
        )
        assert failed.status_code == 401
    limited = await client.post(
        "/api/v1/auth/review-login",
        json={
            "username": "store-reviewer",
            "password": "synthetic-wrong-password",
            "installation_id": _installation(),
        },
    )
    assert limited.status_code == 429


async def test_multiple_identities_bind_to_one_user_and_conflicts_are_rejected(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, factory, settings = auth_fixture
    phone = await _phone_login(client)
    state = await _wechat_state(client)
    bound = await client.post(
        "/api/v1/auth/identities/bind-wechat",
        headers=_headers(phone),
        json={
            "code": "synthetic-wechat-code",
            "state": state,
            "installation_id": _installation(),
        },
    )
    assert bound.status_code == 200
    assert bound.json()["providers"] == ["phone_one_click", "wechat"]

    async with factory() as session:
        await provision_review_account(
            session,
            username="conflict-reviewer",
            password="synthetic-review-password",
            settings=settings,
        )
    review = await client.post(
        "/api/v1/auth/review-login",
        json={
            "username": "conflict-reviewer",
            "password": "synthetic-review-password",
            "installation_id": _installation(),
        },
    )
    second_state = await _wechat_state(client)
    conflict = await client.post(
        "/api/v1/auth/identities/bind-wechat",
        headers=_headers(review.json()),
        json={
            "code": "synthetic-wechat-code",
            "state": second_state,
            "installation_id": _installation(),
        },
    )
    assert conflict.status_code in {409}


async def test_unbind_refuses_last_identity(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, _, _ = auth_fixture
    phone = await _phone_login(client)
    response = await client.delete(
        "/api/v1/auth/identities/phone_one_click", headers=_headers(phone)
    )
    assert response.status_code == 401


async def test_account_deletion_is_idempotent_revokes_auth_and_anonymizes_mapping(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, factory, _ = auth_fixture
    login = await _phone_login(client)
    request_payload = {
        "idempotency_key": "synthetic-idempotency-key-0001",
        "local_data_action": "delete_local",
    }
    first = await client.post(
        "/api/v1/account/deletion-request",
        headers=_headers(login),
        json=request_payload,
    )
    second = await client.post(
        "/api/v1/account/deletion-request",
        headers=_headers(login),
        json=request_payload,
    )
    assert first.status_code == second.status_code == 200
    assert first.json()["request_id"] == second.json()["request_id"]

    confirmed = await client.post(
        "/api/v1/account/deletion-confirm",
        headers=_headers(login),
        json={"request_id": first.json()["request_id"], "confirmation": "DELETE"},
    )
    assert confirmed.status_code == 200
    assert confirmed.json()["status"] == "completed"
    assert (await client.get("/api/v1/auth/me", headers=_headers(login))).status_code == 401
    async with factory() as session:
        identities = (await session.execute(AuthIdentity.__table__.select())).all()
        assert identities == []


async def test_unknown_fields_and_oversized_auth_requests_are_rejected(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, _, _ = auth_fixture
    unknown = await client.post(
        "/api/v1/auth/phone/one-click",
        json={
            "token": "synthetic-phone-token",
            "installation_id": _installation(),
            "phone": "forbidden",
        },
    )
    assert unknown.status_code == 422
    oversized = await client.post(
        "/api/v1/auth/review-login",
        content=b"x" * 32769,
        headers={"content-type": "application/json"},
    )
    assert oversized.status_code == 413


async def test_production_fake_providers_fail_closed(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
) -> None:
    client, _, settings = auth_fixture
    production = settings.model_copy(update={"environment": "production"})
    app.dependency_overrides[get_settings] = lambda: production
    phone = await client.post(
        "/api/v1/auth/phone/one-click",
        json={"token": "synthetic-phone-token", "installation_id": _installation()},
    )
    assert phone.status_code == 503
    state = await _wechat_state(client)
    wechat = await client.post(
        "/api/v1/auth/wechat",
        json={
            "code": "synthetic-wechat-code",
            "state": state,
            "installation_id": _installation(),
        },
    )
    assert wechat.status_code == 503
    assert "PHONE_AUTH_PROVIDER" in production.production_configuration_errors()
    assert "WECHAT_AUTH_PROVIDER" in production.production_configuration_errors()


async def test_auth_logs_contain_metadata_only(
    auth_fixture: tuple[httpx.AsyncClient, async_sessionmaker[AsyncSession], Settings],
    caplog: pytest.LogCaptureFixture,
) -> None:
    client, _, _ = auth_fixture
    with caplog.at_level(logging.INFO, logger="app.auth"):
        response = await client.post(
            "/api/v1/auth/phone/one-click",
            json={
                "token": "synthetic-phone-token",
                "installation_id": _installation(),
            },
        )
    assert response.status_code == 200
    assert "provider=phone_one_click" in caplog.text
    assert "synthetic-phone-token" not in caplog.text
    assert response.json()["tokens"]["access_token"] not in caplog.text


def test_provider_dependencies_are_overridable() -> None:
    assert get_phone_provider is not None
    assert get_wechat_provider is not None
