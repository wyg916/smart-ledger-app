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
        elif scenario is AiScenario.chat:
            content = {
                "title": "一起看看",
                "answer": "我可以依据你明确附带的聚合摘要解释收支，也可以回答一般财务问题。",
                "insights": ["当前回答没有读取原始账单或备注。"],
                "actions": ["可以先选择是否附带今日、本月或预算摘要。"],
                "warnings": [],
                "disclaimer": "AI 内容仅供一般性财务信息参考。",
            }
        elif scenario is AiScenario.parse_transaction:
            categories = payload.get("categories", [])
            first = categories[0] if categories else None
            content = {
                "transaction_type": first["transaction_type"] if first else "expense",
                "amount_minor": 2500,
                "currency_code": payload.get("currency_code", "CNY"),
                "category_candidate": first["name"] if first else None,
                "occurred_at": "2026-08-04T08:00:00+08:00",
                "timezone": payload.get("timezone", "Asia/Shanghai"),
                "note": "AI 解析草稿",
                "confidence": 0.86,
                "needs_confirmation": True,
                "warnings": [],
            }
        elif scenario is AiScenario.image_analysis:
            content = {
                "summary": "这是一张合成财务截图。",
                "important_information": ["识别到一笔待核对的消费记录。"],
                "risk_flags": [],
                "transaction_drafts": [
                    {
                        "transaction_type": "expense",
                        "amount_minor": 2500,
                        "currency_code": "CNY",
                        "category_candidate": "餐饮",
                        "occurred_at": "2026-08-04T08:00:00+08:00",
                        "note": "截图识别草稿",
                        "confidence": 0.82,
                        "needs_confirmation": True,
                    }
                ],
                "disclaimer": "截图识别可能有误，确认后才能记账。",
            }
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
