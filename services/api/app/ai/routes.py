import base64
from datetime import datetime
from io import BytesIO
from typing import Annotated, Any, NoReturn
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from PIL import Image, ImageOps, UnidentifiedImageError

from app.ai.errors import AiError
from app.ai.providers.base import AiProvider, AiScenario
from app.ai.providers.fake import FakeProvider
from app.ai.providers.kimi import KimiProvider
from app.ai.schemas import (
    AiResponse,
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
from app.auth.dependencies import OptionalCurrentUser
from app.config import Settings, get_settings

router = APIRouter(prefix="/api/v1/ai", tags=["ai"])


def get_ai_provider(settings: Annotated[Settings, Depends(get_settings)]) -> AiProvider:
    if settings.kimi_provider == "fake":
        return FakeProvider()
    if not settings.moonshot_api_key:
        raise AiError("AI_NOT_CONFIGURED", "AI provider is not configured", 503)
    return KimiProvider(api_key=settings.moonshot_api_key, base_url=settings.kimi_base_url)


def _ensure_available(settings: Settings, authenticated: bool) -> None:
    if settings.environment == "production" and not authenticated:
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
    authenticated: bool,
) -> AiResponse:
    try:
        _ensure_available(settings, authenticated)
        model = (
            settings.kimi_reasoning_model
            if scenario is AiScenario.financial_plan
            else settings.kimi_fast_model
        )
        return await AiService(provider).generate(scenario, model, payload.model_dump(mode="json"))
    except AiError as exc:
        _raise_http(exc)


async def _generate_typed[ResultT: StrictModel](
    scenario: AiScenario,
    payload: dict[str, Any],
    settings: Settings,
    provider: AiProvider,
    result_type: type[ResultT],
    model: str,
    authenticated: bool,
) -> tuple[ResultT, str, Any]:
    try:
        _ensure_available(settings, authenticated)
        return await AiService(provider).generate_typed(scenario, model, payload, result_type)
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
    payload: MonthlySummaryRequest,
    settings: SettingsDependency,
    provider: ProviderDependency,
    current: OptionalCurrentUser,
) -> AiResponse:
    return await _generate(
        AiScenario.monthly_summary, payload, settings, provider, current is not None
    )


@router.post("/budget-review", response_model=AiResponse)
async def budget_review(
    payload: BudgetReviewRequest,
    settings: SettingsDependency,
    provider: ProviderDependency,
    current: OptionalCurrentUser,
) -> AiResponse:
    return await _generate(
        AiScenario.budget_review, payload, settings, provider, current is not None
    )


@router.post("/financial-plan", response_model=AiResponse)
async def financial_plan(
    payload: FinancialPlanRequest,
    settings: SettingsDependency,
    provider: ProviderDependency,
    current: OptionalCurrentUser,
) -> AiResponse:
    return await _generate(
        AiScenario.financial_plan, payload, settings, provider, current is not None
    )


@router.post("/chat", response_model=ChatResponse)
async def chat(
    payload: ChatRequest,
    settings: SettingsDependency,
    provider: ProviderDependency,
    current: OptionalCurrentUser,
) -> ChatResponse:
    result, model, usage = await _generate_typed(
        AiScenario.chat,
        payload.model_dump(mode="json"),
        settings,
        provider,
        ChatResult,
        settings.kimi_chat_model,
        current is not None,
    )
    return ChatResponse(result=result, model=model, usage=usage)


@router.post("/parse-transaction", response_model=ParseTransactionResponse)
async def parse_transaction(
    payload: ParseTransactionRequest,
    settings: SettingsDependency,
    provider: ProviderDependency,
    current: OptionalCurrentUser,
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
        current is not None,
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
    settings: SettingsDependency,
    provider: ProviderDependency,
    current: OptionalCurrentUser,
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
            current is not None,
        )
        return ImageAnalysisResponse(result=result, model=model, usage=usage)
    finally:
        raw = b""
        await image.close()
