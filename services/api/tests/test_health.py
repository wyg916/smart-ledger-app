from collections.abc import AsyncIterator

import httpx
import pytest
from sqlalchemy.exc import OperationalError

from app.database import DatabaseProbe, get_database_probe
from app.main import app


@pytest.fixture
async def client() -> AsyncIterator[httpx.AsyncClient]:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as test_client:
        yield test_client
    app.dependency_overrides.clear()


async def healthy_probe() -> None:
    return None


async def failing_probe() -> None:
    raise OperationalError("SELECT 1", {}, OSError("database unavailable"))


def override_probe(probe: DatabaseProbe) -> None:
    app.dependency_overrides[get_database_probe] = lambda: probe


async def test_liveness_does_not_require_database(client: httpx.AsyncClient) -> None:
    response = await client.get("/health/live")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


async def test_readiness_succeeds_when_database_is_available(client: httpx.AsyncClient) -> None:
    override_probe(healthy_probe)

    response = await client.get("/health/ready")

    assert response.status_code == 200
    assert response.json()["status"] == "ready"


async def test_readiness_uses_unified_error_shape(client: httpx.AsyncClient) -> None:
    override_probe(failing_probe)

    response = await client.get("/health/ready")

    assert response.status_code == 503
    assert response.json() == {
        "error": {
            "code": "database_unavailable",
            "message": "Database is not ready",
        }
    }


async def test_version_reports_non_production_environment(client: httpx.AsyncClient) -> None:
    response = await client.get("/version")

    assert response.status_code == 200
    assert response.json() == {
        "service": "smart-ledger-api",
        "version": "0.1.0",
        "environment": "development",
    }
