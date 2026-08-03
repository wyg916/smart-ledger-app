import asyncio
import os
from time import monotonic
from typing import Any

from app.ai.errors import AiError
from app.ai.providers.base import AiScenario
from app.ai.providers.kimi import KimiProvider
from app.ai.services import AiService
from app.config import Settings


def synthetic_payloads() -> dict[AiScenario, dict[str, Any]]:
    comparison = {
        "previous_minor": 8000,
        "delta_minor": 2000,
        "change_basis_points": 2500,
        "has_baseline": True,
    }
    return {
        AiScenario.monthly_summary: {
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
            "income_categories": [{"name": "合成收入", "amount_minor": 20000}],
            "expense_categories": [{"name": "合成支出", "amount_minor": 10000}],
            "accounts": [{"name": "合成账户", "balance_minor": 10000}],
        },
        AiScenario.budget_review: {
            "month": "2026-08",
            "currency_code": "CNY",
            "total_budget_minor": 50000,
            "used_minor": 10000,
            "remaining_minor": 40000,
            "overrun_minor": 0,
            "usage_basis_points": 2000,
            "category_budgets": [],
            "days_remaining": 20,
        },
        AiScenario.financial_plan: {
            "goal_name": "合成应急金",
            "target_minor": 1000000,
            "deadline_months": 12,
            "current_minor": 100000,
            "monthly_contribution_minor": 50000,
            "risk_preference": "conservative",
            "monthly_gap_minor": 25000,
            "currency_code": "CNY",
        },
    }


async def main() -> int:
    settings = Settings()
    if not settings.kimi_live_test:
        print("live_test=disabled")
        return 2
    if not settings.moonshot_api_key:
        print("live_test=not_configured")
        return 2
    provider = KimiProvider(
        api_key=settings.moonshot_api_key,
        base_url=settings.kimi_base_url,
    )
    try:
        models = await provider.list_models()
    except AiError as error:
        print(f"models status=failed error={error.code}")
        return 1
    print("models status=200 ids=" + ",".join(models))
    fast_model = settings.kimi_fast_model
    reasoning_model = settings.kimi_reasoning_model
    if fast_model not in models:
        fast_model = next((item for item in models if item.startswith("kimi-k2.6")), "")
    if reasoning_model not in models:
        reasoning_model = next(
            (item for item in models if item.startswith("kimi-k3")),
            fast_model,
        )
    if not fast_model or not reasoning_model:
        print("routing status=failed error=AI_MODEL_NOT_AVAILABLE")
        return 1
    print(f"routing fast={fast_model} reasoning={reasoning_model}")
    service = AiService(provider)
    scenario_filter = os.getenv("KIMI_SMOKE_SCENARIO", "").strip()
    failed = False
    for scenario, payload in synthetic_payloads().items():
        if scenario_filter and scenario.value != scenario_filter:
            continue
        model = reasoning_model if scenario is AiScenario.financial_plan else fast_model
        started = monotonic()
        try:
            response = await service.generate(scenario, model, payload)
        except AiError as error:
            failed = True
            print(
                f"scene={scenario.value} model={model} status=failed "
                f"latency_ms={int((monotonic() - started) * 1000)} error={error.code}"
            )
            continue
        print(
            f"scene={scenario.value} model={response.model} status=200 "
            f"latency_ms={int((monotonic() - started) * 1000)} "
            f"prompt_tokens={response.usage.prompt_tokens} "
            f"completion_tokens={response.usage.completion_tokens} "
            f"total_tokens={response.usage.total_tokens} "
            "structured_output=pass pydantic=pass"
        )
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
