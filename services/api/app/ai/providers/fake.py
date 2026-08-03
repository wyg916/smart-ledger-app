from typing import Any

from app.ai.providers.base import AiScenario, ProviderResult
from app.ai.schemas import TokenUsage


class FakeProvider:
    def __init__(self, *, invalid_once: bool = False, always_invalid: bool = False) -> None:
        self.invalid_once = invalid_once
        self.always_invalid = always_invalid
        self.calls = 0

    async def list_models(self) -> list[str]:
        return ["fake-fast", "fake-reasoning"]

    async def generate(
        self, scenario: AiScenario, model: str, payload: dict[str, Any], repair: bool = False
    ) -> ProviderResult:
        self.calls += 1
        if self.always_invalid or (self.invalid_once and self.calls == 1):
            content: dict[str, Any] = {"invalid": True}
        else:
            label = {
                AiScenario.monthly_summary: "月度消费总结",
                AiScenario.budget_review: "预算执行解释",
                AiScenario.financial_plan: "财务规划建议",
            }[scenario]
            content = {
                "title": label,
                "summary": "基于确定性摘要生成的合成测试结论。",
                "insights": [
                    {
                        "type": "neutral",
                        "title": "摘要可信",
                        "detail": "仅使用聚合数据进行解释。",
                        "evidence": "确定性金额由客户端提供",
                    }
                ],
                "actions": [{"priority": 1, "title": "持续记录", "detail": "保持稳定记账习惯。"}],
                "risk_tips": ["建议仅作一般性财务信息参考。"],
                "disclaimer": "AI 结果仅供一般性财务信息参考，不构成投资、法律或税务建议。",
            }
        return ProviderResult(
            content=content,
            model=model,
            usage=TokenUsage(prompt_tokens=10, completion_tokens=20, total_tokens=30),
        )
