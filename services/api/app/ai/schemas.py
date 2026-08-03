from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field

MinorAmount = Annotated[int, Field(ge=-(2**63), le=2**63 - 1)]
NonNegativeMinor = Annotated[int, Field(ge=0, le=2**63 - 1)]
ShortText = Annotated[str, Field(min_length=1, max_length=80)]


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class MonthComparison(StrictModel):
    previous_minor: MinorAmount
    delta_minor: MinorAmount
    change_basis_points: int | None = Field(default=None, ge=-1_000_000, le=1_000_000)
    has_baseline: bool


class DailyAggregate(StrictModel):
    local_date: Annotated[str, Field(pattern=r"^\d{4}-\d{2}-\d{2}$")]
    income_minor: NonNegativeMinor
    expense_minor: NonNegativeMinor


class CategoryAggregate(StrictModel):
    name: ShortText
    amount_minor: NonNegativeMinor


class AccountAggregate(StrictModel):
    name: ShortText
    balance_minor: MinorAmount


class MonthlySummaryRequest(StrictModel):
    month: Annotated[str, Field(pattern=r"^\d{4}-\d{2}$")]
    currency_code: Annotated[str, Field(pattern=r"^[A-Z]{3}$")]
    time_zone_id: Annotated[str, Field(min_length=1, max_length=64)]
    income_minor: NonNegativeMinor
    expense_minor: NonNegativeMinor
    net_minor: MinorAmount
    income_comparison: MonthComparison
    expense_comparison: MonthComparison
    daily_trend: Annotated[list[DailyAggregate], Field(max_length=31)]
    income_categories: Annotated[list[CategoryAggregate], Field(max_length=10)]
    expense_categories: Annotated[list[CategoryAggregate], Field(max_length=10)]
    accounts: Annotated[list[AccountAggregate], Field(max_length=20)]


class BudgetAggregate(StrictModel):
    name: ShortText
    budget_minor: NonNegativeMinor
    used_minor: NonNegativeMinor
    remaining_minor: NonNegativeMinor
    overrun_minor: NonNegativeMinor


class BudgetReviewRequest(StrictModel):
    month: Annotated[str, Field(pattern=r"^\d{4}-\d{2}$")]
    currency_code: Annotated[str, Field(pattern=r"^[A-Z]{3}$")]
    total_budget_minor: NonNegativeMinor
    used_minor: NonNegativeMinor
    remaining_minor: NonNegativeMinor
    overrun_minor: NonNegativeMinor
    usage_basis_points: Annotated[int, Field(ge=0, le=1_000_000)]
    category_budgets: Annotated[list[BudgetAggregate], Field(max_length=10)]
    days_remaining: Annotated[int, Field(ge=0, le=31)]


class FinancialPlanRequest(StrictModel):
    goal_name: ShortText
    target_minor: NonNegativeMinor
    deadline_months: Annotated[int, Field(ge=1, le=600)]
    current_minor: NonNegativeMinor
    monthly_contribution_minor: NonNegativeMinor
    risk_preference: Literal["conservative", "balanced", "growth"]
    monthly_gap_minor: MinorAmount
    currency_code: Annotated[str, Field(pattern=r"^[A-Z]{3}$")]


class Insight(StrictModel):
    type: Literal["positive", "warning", "neutral"]
    title: Annotated[str, Field(min_length=1, max_length=80)]
    detail: Annotated[str, Field(min_length=1, max_length=400)]
    evidence: Annotated[str, Field(min_length=1, max_length=200)]


class Action(StrictModel):
    priority: Annotated[int, Field(ge=1, le=5)]
    title: Annotated[str, Field(min_length=1, max_length=80)]
    detail: Annotated[str, Field(min_length=1, max_length=400)]


class AiResult(StrictModel):
    title: Annotated[str, Field(min_length=1, max_length=100)]
    summary: Annotated[str, Field(min_length=1, max_length=800)]
    insights: Annotated[list[Insight], Field(max_length=5)]
    actions: Annotated[list[Action], Field(max_length=5)]
    risk_tips: Annotated[list[Annotated[str, Field(max_length=200)]], Field(max_length=5)]
    disclaimer: Annotated[str, Field(min_length=1, max_length=300)]


class TokenUsage(StrictModel):
    prompt_tokens: Annotated[int, Field(ge=0)]
    completion_tokens: Annotated[int, Field(ge=0)]
    total_tokens: Annotated[int, Field(ge=0)]


class AiResponse(StrictModel):
    result: AiResult
    model: str
    usage: TokenUsage


class AiStatus(StrictModel):
    ai_enabled: bool
    provider: str
    fast_model: str
    reasoning_model: str
    configuration_ready: bool
    production_available: bool


def ai_result_json_schema() -> dict[str, object]:
    def text(maximum: int) -> dict[str, object]:
        return {"type": "string", "minLength": 1, "maxLength": maximum}

    insight = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "type": {"type": "string", "enum": ["positive", "warning", "neutral"]},
            "title": text(80),
            "detail": text(400),
            "evidence": text(200),
        },
        "required": ["type", "title", "detail", "evidence"],
    }
    action = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "priority": {"type": "integer", "minimum": 1, "maximum": 5},
            "title": text(80),
            "detail": text(400),
        },
        "required": ["priority", "title", "detail"],
    }
    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "title": text(100),
            "summary": text(800),
            "insights": {"type": "array", "items": insight, "maxItems": 5},
            "actions": {"type": "array", "items": action, "maxItems": 5},
            "risk_tips": {"type": "array", "items": text(200), "maxItems": 5},
            "disclaimer": text(300),
        },
        "required": ["title", "summary", "insights", "actions", "risk_tips", "disclaimer"],
    }
