from typing import Annotated, Any, NoReturn

from fastapi import APIRouter, Depends, HTTPException

from app.ai.errors import AiError
from app.ai.providers.base import AiProvider, AiScenario
from app.ai.providers.fake import FakeProvider
from app.ai.providers.kimi import KimiProvider
from app.ai.schemas import (
    AiResponse,
    AiStatus,
    BudgetReviewRequest,
    FinancialPlanRequest,
    MonthlySummaryRequest,
)
from app.ai.services import AiService
from app.config import Settings, get_settings

router = APIRouter(prefix="/api/v1/ai", tags=["ai"])


def get_ai_provider(settings: Annotated[Settings, Depends(get_settings)]) -> AiProvider:
    if settings.kimi_provider == "fake":
        return FakeProvider()
    if not settings.moonshot_api_key:
        raise AiError("AI_NOT_CONFIGURED", "AI provider is not configured", 503)
    return KimiProvider(api_key=settings.moonshot_api_key, base_url=settings.kimi_base_url)


def _ensure_available(settings: Settings) -> None:
    if settings.environment == "production":
        raise AiError(
            "AI_PRODUCTION_AUTH_REQUIRED",
            "AI is unavailable in production without authentication",
            403,
        )
    if not settings.kimi_ai_enabled:
        raise AiError("AI_DISABLED", "AI is disabled", 503)


def _raise_http(error: AiError) -> NoReturn:
    raise HTTPException(
        status_code=error.status_code,
        detail={"code": error.code, "message": error.message},
    ) from error


async def _generate(
    scenario: AiScenario,
    payload: Any,
    settings: Settings,
    provider: AiProvider,
) -> AiResponse:
    try:
        _ensure_available(settings)
        model = (
            settings.kimi_reasoning_model
            if scenario is AiScenario.financial_plan
            else settings.kimi_fast_model
        )
        return await AiService(provider).generate(scenario, model, payload.model_dump(mode="json"))
    except AiError as exc:
        _raise_http(exc)


@router.get("/status", response_model=AiStatus)
async def ai_status(settings: Annotated[Settings, Depends(get_settings)]) -> AiStatus:
    ready = settings.kimi_provider == "fake" or bool(settings.moonshot_api_key)
    return AiStatus(
        ai_enabled=settings.kimi_ai_enabled,
        provider=settings.kimi_provider,
        fast_model=settings.kimi_fast_model,
        reasoning_model=settings.kimi_reasoning_model,
        configuration_ready=ready,
        production_available=False,
    )


ProviderDependency = Annotated[AiProvider, Depends(get_ai_provider)]
SettingsDependency = Annotated[Settings, Depends(get_settings)]


@router.post("/monthly-summary", response_model=AiResponse)
async def monthly_summary(
    payload: MonthlySummaryRequest, settings: SettingsDependency, provider: ProviderDependency
) -> AiResponse:
    return await _generate(AiScenario.monthly_summary, payload, settings, provider)


@router.post("/budget-review", response_model=AiResponse)
async def budget_review(
    payload: BudgetReviewRequest, settings: SettingsDependency, provider: ProviderDependency
) -> AiResponse:
    return await _generate(AiScenario.budget_review, payload, settings, provider)


@router.post("/financial-plan", response_model=AiResponse)
async def financial_plan(
    payload: FinancialPlanRequest, settings: SettingsDependency, provider: ProviderDependency
) -> AiResponse:
    return await _generate(AiScenario.financial_plan, payload, settings, provider)
