"""Explicit retention job for de-identified analytics facts and aggregates."""

import asyncio
from datetime import timedelta

from sqlalchemy import delete

from app.analytics.models import AnalyticsDailyMetric, AnalyticsEvent, utc_now
from app.config import get_settings
from app.database import dispose_engine, get_session_factory


async def main() -> None:
    settings = get_settings()
    raw_cutoff = utc_now() - timedelta(days=settings.analytics_raw_retention_days)
    aggregate_cutoff = raw_cutoff.date() - timedelta(
        days=settings.analytics_aggregate_retention_days - settings.analytics_raw_retention_days
    )
    async with get_session_factory()() as session:
        raw = await session.execute(
            delete(AnalyticsEvent).where(AnalyticsEvent.received_at < raw_cutoff)
        )
        aggregates = await session.execute(
            delete(AnalyticsDailyMetric).where(AnalyticsDailyMetric.metric_date < aggregate_cutoff)
        )
        await session.commit()
        print(
            "metrics_retention=completed "
            f"raw_events={getattr(raw, 'rowcount', 0)} "
            f"aggregates={getattr(aggregates, 'rowcount', 0)}"
        )
    await dispose_engine()


if __name__ == "__main__":
    asyncio.run(main())
