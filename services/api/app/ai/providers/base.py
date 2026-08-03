from dataclasses import dataclass
from enum import StrEnum
from typing import Any, Protocol

from app.ai.schemas import TokenUsage


class AiScenario(StrEnum):
    monthly_summary = "monthly_summary"
    budget_review = "budget_review"
    financial_plan = "financial_plan"


@dataclass(frozen=True, slots=True)
class ProviderResult:
    content: dict[str, Any]
    model: str
    usage: TokenUsage


class AiProvider(Protocol):
    async def generate(
        self, scenario: AiScenario, model: str, payload: dict[str, Any], repair: bool = False
    ) -> ProviderResult: ...

    async def list_models(self) -> list[str]: ...
