import asyncio
import json
import random
from time import monotonic
from typing import Any, cast

import openai
from openai import AsyncOpenAI

from app.ai.errors import AiError, map_upstream_status
from app.ai.prompts.v1.system import SYSTEM_PROMPT
from app.ai.providers.base import AiScenario, ProviderResult
from app.ai.schemas import TokenUsage, ai_result_json_schema


class KimiProvider:
    def __init__(self, *, api_key: str, base_url: str) -> None:
        self._client = AsyncOpenAI(
            api_key=api_key,
            base_url=base_url,
            timeout=openai.Timeout(40.0, connect=5.0, read=30.0, write=10.0),
            max_retries=0,
        )

    async def list_models(self) -> list[str]:
        try:
            page = await self._client.models.list()
        except openai.APITimeoutError as exc:
            raise AiError("AI_UPSTREAM_TIMEOUT", "AI provider timed out", 504, True) from exc
        except openai.APIConnectionError as exc:
            raise AiError("AI_UPSTREAM_ERROR", "AI provider is unavailable", 503, True) from exc
        except openai.APIStatusError as exc:
            raise map_upstream_status(exc.status_code) from exc
        return sorted(item.id for item in page.data)

    async def generate(
        self, scenario: AiScenario, model: str, payload: dict[str, Any], repair: bool = False
    ) -> ProviderResult:
        last_error: AiError | None = None
        for attempt in range(2):
            started = monotonic()
            try:
                result = await self._generate_once(scenario, model, payload, repair)
                _ = monotonic() - started
                return result
            except AiError as exc:
                last_error = exc
                if not exc.retryable or attempt == 1:
                    raise
                await asyncio.sleep(0.2 * (2**attempt) + random.uniform(0, 0.05))
        assert last_error is not None
        raise last_error

    async def _generate_once(
        self, scenario: AiScenario, model: str, payload: dict[str, Any], repair: bool
    ) -> ProviderResult:
        user_content = json.dumps(
            {"scenario": scenario.value, "repair": repair, "summary": payload},
            ensure_ascii=False,
            separators=(",", ":"),
        )
        schema = ai_result_json_schema()
        request: dict[str, Any] = {
            "model": model,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_content},
            ],
            "response_format": {
                "type": "json_schema",
                "json_schema": {"name": "smart_ledger_ai_result", "strict": True, "schema": schema},
            },
            "stream": False,
            "max_tokens": 4096,
        }
        if model == "kimi-k2.6":
            request["extra_body"] = {"thinking": {"type": "disabled"}}
        if model == "kimi-k3":
            request["reasoning_effort"] = "low"
        try:
            completion = await self._client.chat.completions.create(**cast(Any, request))
        except openai.APITimeoutError as exc:
            raise AiError("AI_UPSTREAM_TIMEOUT", "AI provider timed out", 504, True) from exc
        except openai.APIConnectionError as exc:
            raise AiError("AI_UPSTREAM_ERROR", "AI provider is unavailable", 503, True) from exc
        except openai.APIStatusError as exc:
            raise map_upstream_status(exc.status_code) from exc
        content = completion.choices[0].message.content
        if not content:
            raise AiError("AI_INVALID_RESPONSE", "AI provider returned invalid data", 502)
        try:
            decoded = json.loads(content)
        except json.JSONDecodeError as exc:
            raise AiError("AI_INVALID_RESPONSE", "AI provider returned invalid data", 502) from exc
        usage = completion.usage
        return ProviderResult(
            content=decoded,
            model=completion.model,
            usage=TokenUsage(
                prompt_tokens=usage.prompt_tokens if usage else 0,
                completion_tokens=usage.completion_tokens if usage else 0,
                total_tokens=usage.total_tokens if usage else 0,
            ),
        )
