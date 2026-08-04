from datetime import datetime
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


class ChatMessageRequest(StrictModel):
    role: Literal["user", "assistant"]
    content: Annotated[str, Field(min_length=1, max_length=2000)]


class ChatContext(StrictModel):
    today_summary: Annotated[str, Field(max_length=1000)] | None = None
    month_summary: Annotated[str, Field(max_length=1000)] | None = None
    budget_summary: Annotated[str, Field(max_length=1000)] | None = None


class ChatRequest(StrictModel):
    messages: Annotated[list[ChatMessageRequest], Field(min_length=1, max_length=16)]
    context: ChatContext = Field(default_factory=ChatContext)

    @property
    def rounds(self) -> int:
        return (len(self.messages) + 1) // 2


class ChatResult(StrictModel):
    title: Annotated[str, Field(min_length=1, max_length=100)]
    answer: Annotated[str, Field(min_length=1, max_length=1600)]
    insights: Annotated[list[Annotated[str, Field(max_length=240)]], Field(max_length=5)]
    actions: Annotated[list[Annotated[str, Field(max_length=240)]], Field(max_length=5)]
    warnings: Annotated[list[Annotated[str, Field(max_length=240)]], Field(max_length=5)]
    disclaimer: Annotated[str, Field(min_length=1, max_length=300)]


class ChatResponse(StrictModel):
    result: ChatResult
    model: str
    usage: TokenUsage


class AllowedCategory(StrictModel):
    name: ShortText
    transaction_type: Literal["income", "expense"]


class ParseTransactionRequest(StrictModel):
    text: Annotated[str, Field(min_length=1, max_length=500)]
    timezone: Annotated[str, Field(min_length=1, max_length=64)]
    currency_code: Annotated[str, Field(pattern=r"^[A-Z]{3}$")]
    categories: Annotated[list[AllowedCategory], Field(min_length=1, max_length=80)]


class TransactionDraftResult(StrictModel):
    transaction_type: Literal["income", "expense"]
    amount_minor: Annotated[int, Field(gt=0, le=2**63 - 1)]
    currency_code: Annotated[str, Field(pattern=r"^[A-Z]{3}$")]
    category_candidate: ShortText | None
    occurred_at: datetime
    timezone: Annotated[str, Field(min_length=1, max_length=64)]
    note: Annotated[str, Field(max_length=500)]
    confidence: Annotated[float, Field(ge=0, le=1)]
    needs_confirmation: Literal[True]
    warnings: Annotated[list[Annotated[str, Field(max_length=160)]], Field(max_length=5)]


class ParseTransactionResponse(StrictModel):
    result: TransactionDraftResult
    model: str
    usage: TokenUsage


class ImageTransactionDraft(StrictModel):
    transaction_type: Literal["income", "expense"]
    amount_minor: Annotated[int, Field(gt=0, le=2**63 - 1)]
    currency_code: Annotated[str, Field(pattern=r"^[A-Z]{3}$")]
    category_candidate: ShortText | None
    occurred_at: datetime | None
    note: Annotated[str, Field(max_length=300)]
    confidence: Annotated[float, Field(ge=0, le=1)]
    needs_confirmation: Literal[True]


class ImageAnalysisResult(StrictModel):
    summary: Annotated[str, Field(min_length=1, max_length=800)]
    important_information: Annotated[
        list[Annotated[str, Field(max_length=240)]], Field(max_length=8)
    ]
    risk_flags: Annotated[list[Annotated[str, Field(max_length=240)]], Field(max_length=8)]
    transaction_drafts: Annotated[list[ImageTransactionDraft], Field(max_length=10)]
    disclaimer: Annotated[str, Field(min_length=1, max_length=300)]


class ImageAnalysisResponse(StrictModel):
    result: ImageAnalysisResult
    model: str
    usage: TokenUsage


type AiResultModel = AiResult | ChatResult | TransactionDraftResult | ImageAnalysisResult


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


def _string(maximum: int, *, minimum: int = 0) -> dict[str, object]:
    return {"type": "string", "minLength": minimum, "maxLength": maximum}


def chat_result_json_schema() -> dict[str, object]:
    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "title": _string(100, minimum=1),
            "answer": _string(1600, minimum=1),
            "insights": {"type": "array", "items": _string(240), "maxItems": 5},
            "actions": {"type": "array", "items": _string(240), "maxItems": 5},
            "warnings": {"type": "array", "items": _string(240), "maxItems": 5},
            "disclaimer": _string(300, minimum=1),
        },
        "required": ["title", "answer", "insights", "actions", "warnings", "disclaimer"],
    }


def transaction_draft_json_schema() -> dict[str, object]:
    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "transaction_type": {"type": "string", "enum": ["income", "expense"]},
            "amount_minor": {"type": "integer", "minimum": 1, "maximum": 2**63 - 1},
            "currency_code": {"type": "string", "pattern": "^[A-Z]{3}$"},
            "category_candidate": {"type": ["string", "null"], "maxLength": 80},
            "occurred_at": {"type": "string", "format": "date-time"},
            "timezone": _string(64, minimum=1),
            "note": _string(500),
            "confidence": {"type": "number", "minimum": 0, "maximum": 1},
            "needs_confirmation": {"type": "boolean", "const": True},
            "warnings": {"type": "array", "items": _string(160), "maxItems": 5},
        },
        "required": [
            "transaction_type",
            "amount_minor",
            "currency_code",
            "category_candidate",
            "occurred_at",
            "timezone",
            "note",
            "confidence",
            "needs_confirmation",
            "warnings",
        ],
    }


def image_analysis_json_schema() -> dict[str, object]:
    draft = {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "transaction_type": {"type": "string", "enum": ["income", "expense"]},
            "amount_minor": {"type": "integer", "minimum": 1, "maximum": 2**63 - 1},
            "currency_code": {"type": "string", "pattern": "^[A-Z]{3}$"},
            "category_candidate": {"type": ["string", "null"], "maxLength": 80},
            "occurred_at": {"type": ["string", "null"], "format": "date-time"},
            "note": _string(300),
            "confidence": {"type": "number", "minimum": 0, "maximum": 1},
            "needs_confirmation": {"type": "boolean", "const": True},
        },
        "required": [
            "transaction_type",
            "amount_minor",
            "currency_code",
            "category_candidate",
            "occurred_at",
            "note",
            "confidence",
            "needs_confirmation",
        ],
    }
    return {
        "type": "object",
        "additionalProperties": False,
        "properties": {
            "summary": _string(800, minimum=1),
            "important_information": {
                "type": "array",
                "items": _string(240),
                "maxItems": 8,
            },
            "risk_flags": {"type": "array", "items": _string(240), "maxItems": 8},
            "transaction_drafts": {"type": "array", "items": draft, "maxItems": 10},
            "disclaimer": _string(300, minimum=1),
        },
        "required": [
            "summary",
            "important_information",
            "risk_flags",
            "transaction_drafts",
            "disclaimer",
        ],
    }


def result_json_schema(scenario: object) -> dict[str, object]:
    value = str(scenario)
    if value.endswith("chat"):
        return chat_result_json_schema()
    if value.endswith("parse_transaction"):
        return transaction_draft_json_schema()
    if value.endswith("image_analysis"):
        return image_analysis_json_schema()
    return ai_result_json_schema()
