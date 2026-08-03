import logging
from time import monotonic
from typing import Any

from pydantic import ValidationError

from app.ai.errors import AiError
from app.ai.providers.base import AiProvider, AiScenario
from app.ai.schemas import AiResponse, AiResult

logger = logging.getLogger(__name__)


class AiService:
    def __init__(self, provider: AiProvider) -> None:
        self._provider = provider

    async def generate(
        self, scenario: AiScenario, model: str, payload: dict[str, Any]
    ) -> AiResponse:
        started = monotonic()
        for repair in (False, True):
            provider_result = await self._provider.generate(scenario, model, payload, repair=repair)
            try:
                result = AiResult.model_validate(provider_result.content)
            except ValidationError:
                if not repair:
                    continue
                raise AiError(
                    "AI_INVALID_RESPONSE", "AI provider returned invalid data", 502
                ) from None
            logger.info(
                "ai_request_completed scenario=%s model=%s retry=%s latency_ms=%d "
                "prompt_tokens=%d completion_tokens=%d total_tokens=%d",
                scenario.value,
                provider_result.model,
                int(repair),
                int((monotonic() - started) * 1000),
                provider_result.usage.prompt_tokens,
                provider_result.usage.completion_tokens,
                provider_result.usage.total_tokens,
            )
            return AiResponse(
                result=result, model=provider_result.model, usage=provider_result.usage
            )
        raise AiError("AI_INVALID_RESPONSE", "AI provider returned invalid data", 502)
