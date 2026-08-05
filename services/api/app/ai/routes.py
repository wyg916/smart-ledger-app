import base64
from datetime import datetime
from io import BytesIO
from time import monotonic
from typing import Annotated, Any
from uuid import UUID
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import APIRouter, Depends, File, HTTPException, Request, UploadFile
from PIL import Image, ImageOps, UnidentifiedImageError
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.errors import AiError
from app.ai.providers.base import AiProvider, AiScenario
from app.ai.providers.fake import FakeProvider
from app.ai.providers.kimi import KimiProvider
from app.ai.quota import QuotaService, should_consume_error
from app.ai.schemas import (
    AiQuotaStatus,
    AiResponse,
    AiResult,
    AiStatus,
    BudgetReviewRequest,
    ChatRequest,
    ChatResponse,
    ChatResult,
    FinancialPlanRequest,
    ImageAnalysisResponse,
    ImageAnalysisResult,
    MonthlySummaryRequest,
    ParseTransactionRequest,
    ParseTransactionResponse,
    StrictModel,
    TransactionDraftResult,
)
from app.ai.services import AiService
from app.auth.dependencies import CurrentUser
from app.config import Settings, get_settings
from app.database import get_session

router = APIRouter(prefix="/api/v1/ai", tags=["ai"])


def get_ai_provider(settings: Annotated[Settings, Depends(get_settings)]) -> AiProvider:
    if settings.kimi_provider == "fake":
        return FakeProvider()
    if not settings.moonshot_api_key:
        raise AiError("AI_NOT_CONFIGURED", "AI provider is not configured", 503)
    return KimiProvider(api_key=settings.moonshot_api_key, base_url=settings.kimi_base_url)


def _ensure_available(settings: Settings) -> None:
    if not settings.kimi_ai_enabled:
        raise AiError("AI_DISABLED", "AI is disabled", 503)


def _request_id(request: Request) -> str:
    value = str(getattr(request.state, "request_id", ""))
    try:
        UUID(value)
    except ValueError as exc:
        raise AiError("AI_REQUEST_ID_INVALID", "X-Request-Id must be a UUID", 422) from exc
    return value


async def _generate_typed[ResultT: StrictModel](
    scenario: AiScenario,
    payload: dict[str, Any],
    settings: Settings,
    provider: AiProvider,
    result_type: type[ResultT],
    model: str,
    request: Request,
    session: AsyncSession,
    current: Any,
) -> tuple[ResultT, str, Any]:
    _ensure_available(settings)
    quota = QuotaService(session, settings)
    reservation = await quota.reserve(
        user=current.user,
        installation_id=current.auth_session.installation_id,
        feature=scenario.value,
        request_id=_request_id(request),
    )
    started = monotonic()
    try:
        result, actual_model, usage = await AiService(provider).generate_typed(
            scenario, model, payload, result_type
        )
    except AiError as exc:
        latency_ms = int((monotonic() - started) * 1000)
        if should_consume_error(exc):
            await quota.consume(
                reservation,
                model=model,
                usage=None,
                latency_ms=latency_ms,
                error_type=exc.code,
            )
        else:
            await quota.release(
                reservation,
                error_type=exc.code,
                latency_ms=latency_ms,
            )
        raise
    except Exception:
        await quota.consume(
            reservation,
            model=model,
            usage=None,
            latency_ms=int((monotonic() - started) * 1000),
            error_type="AI_INTERNAL_ERROR_AFTER_RESERVATION",
        )
        raise
    await quota.consume(
        reservation,
        model=actual_model,
        usage=usage,
        latency_ms=int((monotonic() - started) * 1000),
    )
    return result, actual_model, usage


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
SessionDependency = Annotated[AsyncSession, Depends(get_session)]


@router.get("/quota", response_model=AiQuotaStatus)
async def ai_quota(
    session: SessionDependency,
    settings: SettingsDependency,
    current: CurrentUser,
) -> AiQuotaStatus:
    return await QuotaService(session, settings).status(current.user)


@router.post("/monthly-summary", response_model=AiResponse)
async def monthly_summary(
    payload: MonthlySummaryRequest,
    request: Request,
    session: SessionDependency,
    current: CurrentUser,
    settings: SettingsDependency,
    provider: ProviderDependency,
) -> AiResponse:
    result, model, usage = await _generate_typed(
        AiScenario.monthly_summary,
        payload.model_dump(mode="json"),
        settings,
        provider,
        AiResult,
        settings.kimi_fast_model,
        request,
        session,
        current,
    )
    return AiResponse(result=result, model=model, usage=usage)


@router.post("/budget-review", response_model=AiResponse)
async def budget_review(
    payload: BudgetReviewRequest,
    request: Request,
    session: SessionDependency,
    current: CurrentUser,
    settings: SettingsDependency,
    provider: ProviderDependency,
) -> AiResponse:
    result, model, usage = await _generate_typed(
        AiScenario.budget_review,
        payload.model_dump(mode="json"),
        settings,
        provider,
        AiResult,
        settings.kimi_fast_model,
        request,
        session,
        current,
    )
    return AiResponse(result=result, model=model, usage=usage)


@router.post("/financial-plan", response_model=AiResponse)
async def financial_plan(
    payload: FinancialPlanRequest,
    request: Request,
    session: SessionDependency,
    current: CurrentUser,
    settings: SettingsDependency,
    provider: ProviderDependency,
) -> AiResponse:
    result, model, usage = await _generate_typed(
        AiScenario.financial_plan,
        payload.model_dump(mode="json"),
        settings,
        provider,
        AiResult,
        settings.kimi_reasoning_model,
        request,
        session,
        current,
    )
    return AiResponse(result=result, model=model, usage=usage)


@router.post("/chat", response_model=ChatResponse)
async def chat(
    payload: ChatRequest,
    request: Request,
    session: SessionDependency,
    current: CurrentUser,
    settings: SettingsDependency,
    provider: ProviderDependency,
) -> ChatResponse:
    result, model, usage = await _generate_typed(
        AiScenario.chat,
        payload.model_dump(mode="json"),
        settings,
        provider,
        ChatResult,
        settings.kimi_chat_model,
        request,
        session,
        current,
    )
    return ChatResponse(result=result, model=model, usage=usage)


@router.post("/parse-transaction", response_model=ParseTransactionResponse)
async def parse_transaction(
    payload: ParseTransactionRequest,
    request: Request,
    session: SessionDependency,
    current: CurrentUser,
    settings: SettingsDependency,
    provider: ProviderDependency,
) -> ParseTransactionResponse:
    try:
        ZoneInfo(payload.timezone)
    except ZoneInfoNotFoundError as exc:
        raise HTTPException(
            status_code=422,
            detail={"code": "AI_TIMEZONE_INVALID", "message": "Timezone is invalid"},
        ) from exc
    provider_payload = payload.model_dump(mode="json")
    provider_payload["reference_time"] = datetime.now(ZoneInfo(payload.timezone)).isoformat()
    result, model, usage = await _generate_typed(
        AiScenario.parse_transaction,
        provider_payload,
        settings,
        provider,
        TransactionDraftResult,
        settings.kimi_fast_model,
        request,
        session,
        current,
    )
    allowed = {(category.name, category.transaction_type) for category in payload.categories}
    if (
        result.category_candidate is not None
        and (
            result.category_candidate,
            result.transaction_type,
        )
        not in allowed
    ):
        raise HTTPException(
            status_code=502,
            detail={
                "code": "AI_INVALID_RESPONSE",
                "message": "AI category candidate is invalid",
            },
        )
    if result.currency_code != payload.currency_code or result.timezone != payload.timezone:
        raise HTTPException(
            status_code=502,
            detail={"code": "AI_INVALID_RESPONSE", "message": "AI draft context is invalid"},
        )
    return ParseTransactionResponse(result=result, model=model, usage=usage)


def _validated_image(raw: bytes, content_type: str | None) -> tuple[bytes, str]:
    allowed = {"image/png", "image/jpeg", "image/webp"}
    if content_type not in allowed:
        raise HTTPException(
            status_code=415,
            detail={"code": "AI_IMAGE_TYPE_INVALID", "message": "Unsupported image type"},
        )
    try:
        source: Image.Image = Image.open(BytesIO(raw))
        source.verify()
        source = Image.open(BytesIO(raw))
        source = ImageOps.exif_transpose(source)
    except (UnidentifiedImageError, OSError) as exc:
        raise HTTPException(
            status_code=422,
            detail={"code": "AI_IMAGE_INVALID", "message": "Image content is invalid"},
        ) from exc
    if source.width * source.height > 16_000_000:
        raise HTTPException(
            status_code=413,
            detail={"code": "AI_IMAGE_DIMENSIONS_INVALID", "message": "Image is too large"},
        )
    source.thumbnail((4096, 4096), Image.Resampling.LANCZOS)
    converted = source.convert("RGB")
    output = BytesIO()
    converted.save(output, format="JPEG", quality=84, optimize=True)
    return output.getvalue(), "image/jpeg"


@router.post("/analyze-image", response_model=ImageAnalysisResponse)
async def analyze_image(
    request: Request,
    session: SessionDependency,
    current: CurrentUser,
    settings: SettingsDependency,
    provider: ProviderDependency,
    image: Annotated[UploadFile, File()],
) -> ImageAnalysisResponse:
    raw = b""
    try:
        raw = await image.read(8 * 1024 * 1024 + 1)
        if len(raw) > 8 * 1024 * 1024:
            raise HTTPException(
                status_code=413,
                detail={"code": "AI_IMAGE_TOO_LARGE", "message": "Image exceeds 8 MiB"},
            )
        encoded, mime_type = _validated_image(raw, image.content_type)
        data_url = f"data:{mime_type};base64,{base64.b64encode(encoded).decode('ascii')}"
        result, model, usage = await _generate_typed(
            AiScenario.image_analysis,
            {"_image_data_url": data_url, "instruction": "分析这张财务相关截图"},
            settings,
            provider,
            ImageAnalysisResult,
            settings.kimi_vision_model,
            request,
            session,
            current,
        )
        return ImageAnalysisResponse(result=result, model=model, usage=usage)
    finally:
        raw = b""
        await image.close()
