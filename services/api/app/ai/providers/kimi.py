import asyncio
import json
import random
from time import monotonic
from typing import Any, cast

import openai
from openai import AsyncOpenAI

from app.ai.errors import AiError, map_upstream_status
from app.ai.prompts.v1.system import (
    CHAT_SYSTEM_PROMPT,
    IMAGE_SYSTEM_PROMPT,
    PARSE_SYSTEM_PROMPT,
    SYSTEM_PROMPT,
)
from app.ai.providers.base import AiScenario, ProviderResult
from app.ai.schemas import TokenUsage, result_json_schema


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
        safe_payload = dict(payload)
        image_data_url = safe_payload.pop("_image_data_url", None)
        schema = result_json_schema(scenario)
        user_content = json.dumps(
            {
                "scenario": scenario.value,
                "repair": repair,
                "input": safe_payload,
                "required_output_schema": schema,
                "output_rule": (
                    "Return exactly one JSON object matching required_output_schema. "
                    "Do not wrap or rename fields."
                ),
            },
            ensure_ascii=False,
            separators=(",", ":"),
        )
        system_prompt = {
            AiScenario.chat: CHAT_SYSTEM_PROMPT,
            AiScenario.parse_transaction: PARSE_SYSTEM_PROMPT,
            AiScenario.image_analysis: IMAGE_SYSTEM_PROMPT,
        }.get(scenario, SYSTEM_PROMPT)
        user_message: dict[str, Any] = {"role": "user", "content": user_content}
        if scenario is AiScenario.image_analysis:
            if not isinstance(image_data_url, str):
                raise AiError("AI_INVALID_IMAGE", "Image payload is missing", 400)
            user_message["content"] = [
                {"type": "image_url", "image_url": {"url": image_data_url}},
                {"type": "text", "text": user_content},
            ]
        request: dict[str, Any] = {
            "model": model,
            "messages": [
                {"role": "system", "content": system_prompt},
                user_message,
            ],
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": f"smart_ledger_{scenario.value}",
                    "strict": True,
                    "schema": schema,
                },
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
