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
                "summary": "已经为你整理好啦：这份结论只依据本地确定性聚合，可以安心核对。",
                "insights": [
                    {
                        "type": "positive",
                        "title": "数据边界很清楚",
                        "detail": "你保留了完整的本地账目，AI 这里只使用聚合数据帮你读懂趋势。",
                        "evidence": "确定性金额由客户端提供",
                    }
                ],
                "actions": [
                    {
                        "priority": 1,
                        "title": "轻松保持记录",
                        "detail": "可以继续按现在的节奏记账，让下一次回顾更从容。",
                    }
                ],
                "risk_tips": ["温柔提醒：建议仍需结合你的实际情况判断。"],
                "disclaimer": "AI 结果仅供一般性财务信息参考，不构成投资、法律或税务建议。",
            }
        return ProviderResult(
            content=content,
            model=model,
            usage=TokenUsage(prompt_tokens=10, completion_tokens=20, total_tokens=30),
        )
