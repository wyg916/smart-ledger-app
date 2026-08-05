import logging
from collections.abc import AsyncIterator
from io import BytesIO
from typing import Any
from uuid import uuid4

import httpx
import pytest
from PIL import Image
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.ai.errors import AiError, map_upstream_status
from app.ai.prompts.v1.system import SYSTEM_PROMPT
from app.ai.providers.base import AiScenario, ProviderResult
from app.ai.providers.fake import FakeProvider
from app.ai.routes import get_ai_provider
from app.ai.schemas import ai_result_json_schema
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

    app.dependency_overrides[get_session] = session_override
    app.dependency_overrides[get_settings] = lambda: settings()
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as test_client:
        login = await test_client.post(
            "/api/v1/auth/phone/one-click",
            json={
                "token": "synthetic-phone-token",
                "carrier": "mobile",
                "installation_id": str(uuid4()),
                "timezone": "Asia/Shanghai",
            },
        )
        assert login.status_code == 200, login.text
        test_client.headers["authorization"] = f"Bearer {login.json()['tokens']['access_token']}"
        yield test_client
    app.dependency_overrides.clear()
    await engine.dispose()


def settings(**updates: Any) -> Settings:
    baseline = Settings().model_copy(
        update={
            "environment": "development",
            "moonshot_api_key": "synthetic-key",
            "kimi_ai_enabled": True,
            "kimi_provider": "fake",
            "kimi_fast_model": "fake-fast",
            "kimi_reasoning_model": "fake-reasoning",
        }
    )
    return baseline.model_copy(update=updates)


def override(provider: Any = None, **setting_updates: Any) -> None:
    configured = settings(**setting_updates)
    app.dependency_overrides[get_settings] = lambda: configured
    if provider is not None:
        app.dependency_overrides[get_ai_provider] = lambda: provider


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
        "daily_trend": [
            {"local_date": "2026-08-03", "income_minor": 20000, "expense_minor": 10000}
        ],
        "income_categories": [{"name": "工资", "amount_minor": 20000}],
        "expense_categories": [{"name": "餐饮", "amount_minor": 10000}],
        "accounts": [{"name": "默认账户", "balance_minor": 10000}],
    }


def budget_payload() -> dict[str, Any]:
    return {
        "month": "2026-08",
        "currency_code": "CNY",
        "total_budget_minor": 50000,
        "used_minor": 10000,
        "remaining_minor": 40000,
        "overrun_minor": 0,
        "usage_basis_points": 2000,
        "category_budgets": [
            {
                "name": "餐饮",
                "budget_minor": 20000,
                "used_minor": 10000,
                "remaining_minor": 10000,
                "overrun_minor": 0,
            }
        ],
        "days_remaining": 20,
    }


def plan_payload() -> dict[str, Any]:
    return {
        "goal_name": "应急金",
        "target_minor": 1000000,
        "deadline_months": 12,
        "current_minor": 100000,
        "monthly_contribution_minor": 50000,
        "risk_preference": "conservative",
        "monthly_gap_minor": 25000,
        "currency_code": "CNY",
    }


def test_prompt_requires_warm_but_truthful_tone() -> None:
    assert "温柔、知性、甜美但克制" in SYSTEM_PROMPT
    assert "不制造\n焦虑" in SYSTEM_PROMPT
    assert "不能为了温柔而淡化事实" in SYSTEM_PROMPT
    assert "不得虚构、重算或修改确定性金额" in SYSTEM_PROMPT
    assert "不得展示 income_minor" in SYSTEM_PROMPT
    assert "自然、易懂的中文" in SYSTEM_PROMPT


async def test_status_is_non_sensitive(client: httpx.AsyncClient) -> None:
    override()
    response = await client.get("/api/v1/ai/status")
    assert response.status_code == 200
    assert response.json() == {
        "ai_enabled": True,
        "provider": "fake",
        "fast_model": "fake-fast",
        "reasoning_model": "fake-reasoning",
        "configuration_ready": True,
        "production_available": False,
    }


@pytest.mark.parametrize(
    ("path", "payload", "expected_model"),
    [
        ("monthly-summary", monthly_payload(), "fake-fast"),
        ("budget-review", budget_payload(), "fake-fast"),
        ("financial-plan", plan_payload(), "fake-reasoning"),
    ],
)
async def test_three_scenarios_use_fake_provider(
    client: httpx.AsyncClient, path: str, payload: dict[str, Any], expected_model: str
) -> None:
    override(FakeProvider())
    response = await client.post(f"/api/v1/ai/{path}", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert body["model"] == expected_model
    assert body["usage"] == {"prompt_tokens": 10, "completion_tokens": 20, "total_tokens": 30}
    assert "reasoning_content" not in body
    assert "amount_minor" not in body["result"]
    assert "整理好啦" in body["result"]["summary"]


async def test_free_chat_accepts_only_explicit_aggregate_context(
    client: httpx.AsyncClient,
) -> None:
    override(FakeProvider(), kimi_chat_model="fake-chat")
    response = await client.post(
        "/api/v1/ai/chat",
        json={
            "messages": [{"role": "user", "content": "帮我解释一下"}],
            "context": {"today_summary": "今天收入0分，支出2500分。"},
        },
    )
    assert response.status_code == 200
    assert response.json()["model"] == "fake-chat"
    assert "原始账单" in response.json()["result"]["insights"][0]


async def test_parse_transaction_returns_confirmation_only_draft(
    client: httpx.AsyncClient,
) -> None:
    override(FakeProvider())
    response = await client.post(
        "/api/v1/ai/parse-transaction",
        json={
            "text": "今天早餐25元",
            "timezone": "Asia/Shanghai",
            "currency_code": "CNY",
            "categories": [{"name": "餐饮", "transaction_type": "expense"}],
        },
    )
    assert response.status_code == 200
    result = response.json()["result"]
    assert result["amount_minor"] == 2500
    assert result["category_candidate"] == "餐饮"
    assert result["needs_confirmation"] is True


async def test_image_analysis_validates_and_reencodes_image(
    client: httpx.AsyncClient,
) -> None:
    override(FakeProvider(), kimi_vision_model="fake-vision")
    buffer = BytesIO()
    Image.new("RGB", (20, 20), (255, 240, 220)).save(buffer, format="PNG")
    response = await client.post(
        "/api/v1/ai/analyze-image",
        files={"image": ("receipt.png", buffer.getvalue(), "image/png")},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["model"] == "fake-vision"
    assert body["result"]["transaction_drafts"][0]["needs_confirmation"] is True

    invalid = await client.post(
        "/api/v1/ai/analyze-image",
        files={"image": ("receipt.png", b"not-an-image", "image/png")},
    )
    assert invalid.status_code == 422
    assert invalid.json()["error"]["code"] == "AI_IMAGE_INVALID"


async def test_disabled_and_production_fail_closed(client: httpx.AsyncClient) -> None:
    override(FakeProvider(), kimi_ai_enabled=False)
    disabled = await client.post("/api/v1/ai/monthly-summary", json=monthly_payload())
    assert disabled.status_code == 503
    assert disabled.json()["error"]["code"] == "AI_DISABLED"
    override(FakeProvider(), environment="production")
    production = await client.post("/api/v1/ai/monthly-summary", json=monthly_payload())
    assert production.status_code == 200


async def test_missing_key_is_configuration_error(client: httpx.AsyncClient) -> None:
    override(None, kimi_provider="kimi", moonshot_api_key="")
    response = await client.post("/api/v1/ai/monthly-summary", json=monthly_payload())
    assert response.status_code == 503
    assert response.json()["error"]["code"] == "AI_NOT_CONFIGURED"


@pytest.mark.parametrize(
    "mutation",
    [
        lambda data: data.update({"unknown": True}),
        lambda data: data.update({"income_minor": 1.5}),
        lambda data: data.update({"daily_trend": data["daily_trend"] * 32}),
        lambda data: data.update({"expense_categories": data["expense_categories"] * 11}),
    ],
)
async def test_strict_request_validation(client: httpx.AsyncClient, mutation: Any) -> None:
    override(FakeProvider())
    payload = monthly_payload()
    mutation(payload)
    response = await client.post("/api/v1/ai/monthly-summary", json=payload)
    assert response.status_code == 422


async def test_request_body_limit(client: httpx.AsyncClient) -> None:
    override(FakeProvider())
    response = await client.post(
        "/api/v1/ai/monthly-summary",
        content=b"x" * 32769,
        headers={"content-type": "application/json"},
    )
    assert response.status_code == 413


async def test_invalid_response_repairs_once(client: httpx.AsyncClient) -> None:
    provider = FakeProvider(invalid_once=True)
    override(provider)
    response = await client.post("/api/v1/ai/monthly-summary", json=monthly_payload())
    assert response.status_code == 200
    assert provider.calls == 2


async def test_invalid_response_fails_after_repair(client: httpx.AsyncClient) -> None:
    provider = FakeProvider(always_invalid=True)
    override(provider)
    response = await client.post("/api/v1/ai/monthly-summary", json=monthly_payload())
    assert response.status_code == 502
    assert response.json()["error"]["code"] == "AI_INVALID_RESPONSE"
    assert provider.calls == 2


class FailingProvider:
    def __init__(self, error: AiError) -> None:
        self.error = error

    async def list_models(self) -> list[str]:
        return []

    async def generate(
        self, scenario: AiScenario, model: str, payload: dict[str, Any], repair: bool = False
    ) -> ProviderResult:
        raise self.error


@pytest.mark.parametrize(
    ("error", "status_code", "code"),
    [
        (map_upstream_status(400), 502, "AI_UPSTREAM_ERROR"),
        (map_upstream_status(401), 502, "AI_UPSTREAM_AUTH_ERROR"),
        (map_upstream_status(403), 502, "AI_UPSTREAM_AUTH_ERROR"),
        (map_upstream_status(429), 429, "AI_RATE_LIMITED"),
        (map_upstream_status(503), 503, "AI_UPSTREAM_ERROR"),
        (AiError("AI_UPSTREAM_TIMEOUT", "AI provider timed out", 504), 504, "AI_UPSTREAM_TIMEOUT"),
    ],
)
async def test_upstream_errors_are_sanitized(
    client: httpx.AsyncClient, error: AiError, status_code: int, code: str
) -> None:
    override(FailingProvider(error))
    response = await client.post("/api/v1/ai/monthly-summary", json=monthly_payload())
    assert response.status_code == status_code
    assert response.json()["error"]["code"] == code
    assert "synthetic-key" not in response.text


async def test_logs_only_contain_metadata(client: httpx.AsyncClient, caplog: Any) -> None:
    override(FakeProvider())
    with caplog.at_level(logging.INFO, logger="app.ai.services"):
        response = await client.post("/api/v1/ai/monthly-summary", json=monthly_payload())
    assert response.status_code == 200
    text = caplog.text
    assert "scenario=monthly_summary" in text
    assert "prompt_tokens=10" in text
    assert "synthetic-key" not in text
    assert "Asia/Shanghai" not in text
    assert "reasoning_content" not in text


def test_structured_output_schema_is_inline_and_closed() -> None:
    schema = ai_result_json_schema()
    encoded = str(schema)
    assert "$ref" not in encoded
    assert "$defs" not in encoded
    assert schema["additionalProperties"] is False
