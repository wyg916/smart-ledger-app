import hashlib
import json
import secrets
from collections import defaultdict
from datetime import UTC, date, datetime, time, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.analytics.models import AnalyticsEvent, AnalyticsInstallation, AnalyticsSession, utc_now
from app.analytics.schemas import (
    EventBatchRequest,
    InstallationRequest,
    MetricsOverview,
    SessionEndRequest,
    SessionStartRequest,
)

EVENT_NAMES = {
    "app_open",
    "session_start",
    "session_end",
    "home_viewed",
    "transaction_created",
    "transaction_edited",
    "transaction_deleted",
    "quick_category_used",
    "natural_language_entry_submitted",
    "natural_language_entry_confirmed",
    "natural_language_entry_cancelled",
    "analytics_viewed",
    "budget_viewed",
    "ai_chat_submitted",
    "ai_chat_success",
    "ai_chat_failed",
    "image_analysis_submitted",
    "image_analysis_success",
    "image_analysis_failed",
}

ACTIVE_EVENT_NAMES = EVENT_NAMES - {"session_end"}


def token_digest(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


async def register_installation(
    session: AsyncSession, request: InstallationRequest
) -> tuple[AnalyticsInstallation, str]:
    installation_id = str(request.installation_id)
    actor_id = str(request.anonymous_actor_id)
    token = secrets.token_urlsafe(48)
    installation = await session.get(AnalyticsInstallation, installation_id)
    now = utc_now()
    if installation is None:
        installation = AnalyticsInstallation(
            installation_id=installation_id,
            anonymous_actor_id=actor_id,
            token_hash=token_digest(token),
            platform=request.platform,
            app_version=request.app_version,
            first_seen_at=now,
            last_seen_at=now,
        )
        session.add(installation)
    else:
        installation.anonymous_actor_id = actor_id
        installation.token_hash = token_digest(token)
        installation.platform = request.platform
        installation.app_version = request.app_version
        installation.last_seen_at = now
    await session.commit()
    return installation, token


async def find_installation_by_token(
    session: AsyncSession, token: str
) -> AnalyticsInstallation | None:
    result = await session.execute(
        select(AnalyticsInstallation).where(AnalyticsInstallation.token_hash == token_digest(token))
    )
    return result.scalar_one_or_none()


async def start_session(
    session: AsyncSession,
    installation: AnalyticsInstallation,
    request: SessionStartRequest,
) -> None:
    session_id = str(request.session_id)
    row = await session.get(AnalyticsSession, session_id)
    if row is None:
        session.add(
            AnalyticsSession(
                session_id=session_id,
                installation_id=installation.installation_id,
                anonymous_actor_id=installation.anonymous_actor_id,
                started_at=request.started_at.astimezone(UTC),
            )
        )
    installation.last_seen_at = utc_now()
    await session.commit()


async def end_session(
    session: AsyncSession,
    installation: AnalyticsInstallation,
    request: SessionEndRequest,
) -> bool:
    row = await session.get(AnalyticsSession, str(request.session_id))
    if row is None or row.installation_id != installation.installation_id:
        return False
    row.ended_at = request.ended_at.astimezone(UTC)
    installation.last_seen_at = utc_now()
    await session.commit()
    return True


async def ingest_events(
    session: AsyncSession,
    installation: AnalyticsInstallation,
    request: EventBatchRequest,
) -> tuple[int, int]:
    if any(item.event_name not in EVENT_NAMES for item in request.events):
        raise ValueError("event name is not whitelisted")
    accepted = 0
    duplicates = 0
    for item in request.events:
        event_id = str(item.event_id)
        if await session.get(AnalyticsEvent, event_id) is not None:
            duplicates += 1
            continue
        session.add(
            AnalyticsEvent(
                event_id=event_id,
                installation_id=installation.installation_id,
                anonymous_actor_id=installation.anonymous_actor_id,
                session_id=str(item.session_id),
                event_name=item.event_name,
                occurred_at=item.occurred_at.astimezone(UTC),
                schema_version=item.schema_version,
                properties_json=json.dumps(
                    item.properties, ensure_ascii=True, separators=(",", ":")
                ),
                received_at=utc_now(),
            )
        )
        accepted += 1
    installation.last_seen_at = utc_now()
    await session.commit()
    return accepted, duplicates


def _safe_rate(numerator: int, denominator: int) -> float | None:
    return None if denominator == 0 else round(numerator / denominator, 4)


def _aware(value: datetime) -> datetime:
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


async def metrics_overview(session: AsyncSession, days: int) -> MetricsOverview:
    now = utc_now()
    today_start = datetime.combine(now.date(), time.min, tzinfo=UTC)
    window_start = today_start - timedelta(days=days - 1)
    month_start = today_start - timedelta(days=29)
    query_start = min(window_start, month_start) - timedelta(days=7)
    event_rows = (
        (
            await session.execute(
                select(AnalyticsEvent).where(AnalyticsEvent.occurred_at >= query_start)
            )
        )
        .scalars()
        .all()
    )
    installations = (await session.execute(select(AnalyticsInstallation))).scalars().all()
    sessions = (
        (
            await session.execute(
                select(AnalyticsSession).where(AnalyticsSession.started_at >= window_start)
            )
        )
        .scalars()
        .all()
    )

    events = [row for row in event_rows if _aware(row.occurred_at) >= window_start]
    active_by_date: dict[date, set[str]] = defaultdict(set)
    for event in event_rows:
        occurred = _aware(event.occurred_at)
        if event.event_name in ACTIVE_EVENT_NAMES:
            active_by_date[occurred.date()].add(event.anonymous_actor_id)

    def actors_since(start: datetime) -> set[str]:
        return {
            row.anonymous_actor_id
            for row in event_rows
            if row.event_name in ACTIVE_EVENT_NAMES and _aware(row.occurred_at) >= start
        }

    def named(name: str) -> list[AnalyticsEvent]:
        return [row for row in events if row.event_name == name]

    transaction_events = named("transaction_created")
    quick_events = named("quick_category_used")
    nl_submitted = named("natural_language_entry_submitted")
    nl_confirmed = named("natural_language_entry_confirmed")
    ai_submitted = named("ai_chat_submitted")
    ai_success = named("ai_chat_success")
    image_submitted = named("image_analysis_submitted")
    image_success = named("image_analysis_success")
    active_window = actors_since(window_start)

    def retention(offset: int) -> float | None:
        mature = [
            row
            for row in installations
            if _aware(row.first_seen_at).date() <= now.date() - timedelta(days=offset)
        ]
        if not mature:
            return None
        returned = sum(
            1
            for row in mature
            if row.anonymous_actor_id
            in active_by_date.get(_aware(row.first_seen_at).date() + timedelta(days=offset), set())
        )
        return _safe_rate(returned, len(mature))

    return MetricsOverview(
        window_days=days,
        dau=len(active_by_date.get(now.date(), set())),
        wau=len(actors_since(today_start - timedelta(days=6))),
        mau=len(actors_since(month_start)),
        new_installations=sum(
            1 for row in installations if _aware(row.first_seen_at) >= window_start
        ),
        sessions=len(sessions),
        sessions_per_active_actor=_safe_rate(len(sessions), len(active_window)),
        transaction_users=len({row.anonymous_actor_id for row in transaction_events}),
        transaction_count=len(transaction_events),
        quick_category_usage_rate=_safe_rate(len(quick_events), len(transaction_events)),
        natural_language_users=len({row.anonymous_actor_id for row in nl_submitted}),
        natural_language_confirmation_rate=_safe_rate(len(nl_confirmed), len(nl_submitted)),
        ai_users=len({row.anonymous_actor_id for row in ai_submitted}),
        ai_success_rate=_safe_rate(len(ai_success), len(ai_submitted)),
        image_analysis_users=len({row.anonymous_actor_id for row in image_submitted}),
        image_analysis_success_rate=_safe_rate(len(image_success), len(image_submitted)),
        d1_retention=retention(1),
        d7_retention=retention(7),
    )
