import hashlib
import json
import re
import secrets
from collections import Counter, defaultdict
from collections.abc import Sequence
from datetime import UTC, date, datetime, time, timedelta
from statistics import mean
from typing import Literal
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.models import AiUsageEvent
from app.analytics.models import AnalyticsEvent, AnalyticsInstallation, AnalyticsSession, utc_now
from app.analytics.schemas import (
    AiQuotaMetrics,
    AiUsageMetrics,
    DimensionValue,
    EventBatchRequest,
    InstallationRequest,
    MetricsDimensions,
    MetricsOverview,
    MetricsRetention,
    MetricsTimePoint,
    MetricsTimeseries,
    ModelUsage,
    NamedCount,
    RetentionCohort,
    SessionEndRequest,
    SessionStartRequest,
)
from app.auth.models import AuthLoginAudit, User
from app.config import Settings

PREAUTH_EVENT_NAMES = {
    "login_page_viewed",
    "phone_login_started",
    "phone_login_cancelled",
    "phone_login_failed",
    "wechat_login_started",
    "wechat_login_cancelled",
    "wechat_login_failed",
}
AUTH_EVENT_NAMES = {
    "phone_login_succeeded",
    "wechat_login_succeeded",
    "review_login_succeeded",
    "logout_completed",
    "account_deletion_started",
    "account_deletion_completed",
}
CORE_EVENT_NAMES = {
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
    "monthly_summary_submitted",
    "monthly_summary_success",
    "monthly_summary_failed",
    "budget_review_submitted",
    "budget_review_success",
    "budget_review_failed",
    "financial_plan_submitted",
    "financial_plan_success",
    "financial_plan_failed",
    "ai_parse_transaction_submitted",
    "ai_parse_transaction_success",
    "ai_parse_transaction_failed",
}
EVENT_NAMES = {
    "app_open",
    "session_start",
    "session_end",
    "home_viewed",
    *PREAUTH_EVENT_NAMES,
    *AUTH_EVENT_NAMES,
    *CORE_EVENT_NAMES,
}
AUTHENTICATED_ACTIVE_EVENT_NAMES = {
    "session_start",
    "phone_login_succeeded",
    "wechat_login_succeeded",
    "review_login_succeeded",
    "transaction_created",
    "transaction_edited",
    "transaction_deleted",
    "quick_category_used",
    "natural_language_entry_confirmed",
    "analytics_viewed",
    "budget_viewed",
    "ai_chat_submitted",
    "ai_chat_success",
    "image_analysis_submitted",
    "image_analysis_success",
}
LEGACY_ACTIVE_EVENT_NAMES = EVENT_NAMES - {"session_end"} - PREAUTH_EVENT_NAMES

ALLOWED_DIMENSIONS = {
    "platform",
    "android_version",
    "app_version",
    "application_id",
    "auth_provider",
    "user_type",
    "release_channel",
    "feature",
    "network_type",
    "ai_feature",
    "ai_status",
    "error_type",
    "model",
}


def token_digest(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


async def register_installation(
    session: AsyncSession,
    request: InstallationRequest,
    *,
    user: User | None = None,
    auth_provider: str = "unknown",
) -> tuple[AnalyticsInstallation, str]:
    _validate_installation_dimensions(request)
    installation_id = str(request.installation_id)
    actor_id = str(request.anonymous_actor_id)
    token = secrets.token_urlsafe(48)
    installation = await session.get(AnalyticsInstallation, installation_id)
    now = utc_now()
    values = {
        "anonymous_actor_id": actor_id,
        "user_id": user.id if user is not None else None,
        "token_hash": token_digest(token),
        "platform": request.platform,
        "android_version": request.android_version,
        "app_version": request.app_version,
        "application_id": request.application_id,
        "release_channel": request.release_channel,
        "auth_provider": auth_provider if user is not None else "unknown",
        "user_timezone": user.timezone if user is not None else "UTC",
        "identity_scope": "authenticated" if user is not None else "pre_auth",
        "last_seen_at": now,
    }
    if installation is None:
        installation = AnalyticsInstallation(
            installation_id=installation_id,
            first_seen_at=now,
            **values,
        )
        session.add(installation)
    else:
        for key, value in values.items():
            setattr(installation, key, value)
    await session.commit()
    return installation, token


def _validate_installation_dimensions(request: InstallationRequest) -> None:
    safe_text = re.compile(r"^[A-Za-z0-9._ -]+$")
    package_name = re.compile(r"^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$")
    if request.android_version != "unknown" and not safe_text.fullmatch(request.android_version):
        raise ValueError("android_version is invalid")
    if request.application_id != "unknown" and not package_name.fullmatch(request.application_id):
        raise ValueError("application_id is invalid")
    if not safe_text.fullmatch(request.release_channel):
        raise ValueError("release_channel is invalid")


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
    scope, user_id, timezone = _validated_identity(
        installation,
        request.identity_scope,
        str(request.user_id) if request.user_id is not None else None,
        schema_version=request.schema_version,
    )
    session_id = str(request.session_id)
    row = await session.get(AnalyticsSession, session_id)
    if row is None:
        started_at = request.started_at.astimezone(UTC)
        session.add(
            AnalyticsSession(
                session_id=session_id,
                installation_id=installation.installation_id,
                anonymous_actor_id=installation.anonymous_actor_id,
                user_id=user_id,
                auth_provider=installation.auth_provider if user_id is not None else "unknown",
                user_timezone=timezone,
                identity_scope=scope,
                local_started_date=started_at.astimezone(ZoneInfo(timezone)).date(),
                started_at=started_at,
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
        scope, user_id, timezone = _validated_identity(
            installation,
            item.identity_scope,
            str(item.user_id) if item.user_id is not None else None,
            item.schema_version,
        )
        if scope == "pre_auth" and item.event_name not in PREAUTH_EVENT_NAMES:
            raise ValueError("pre-auth event name is not allowed")
        if item.schema_version >= 2 and item.event_name in CORE_EVENT_NAMES and user_id is None:
            raise ValueError("authenticated core event requires user_id")
        occurred_at = item.occurred_at.astimezone(UTC)
        session.add(
            AnalyticsEvent(
                event_id=event_id,
                installation_id=installation.installation_id,
                anonymous_actor_id=installation.anonymous_actor_id,
                user_id=user_id,
                identity_scope=scope,
                session_id=str(item.session_id),
                event_name=item.event_name,
                occurred_at=occurred_at,
                event_date=occurred_at.astimezone(ZoneInfo(timezone)).date(),
                user_timezone=timezone,
                network_type=str(item.properties.get("network_type", "unknown")),
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


def _validated_identity(
    installation: AnalyticsInstallation,
    requested_scope: str,
    requested_user_id: str | None,
    schema_version: int,
) -> tuple[str, str | None, str]:
    if schema_version == 1:
        return "anonymous_legacy", None, "UTC"
    if requested_scope == "authenticated":
        if installation.user_id is None or requested_user_id != installation.user_id:
            raise ValueError("authenticated event user does not match installation")
        return "authenticated", installation.user_id, installation.user_timezone
    if requested_user_id is not None:
        raise ValueError("anonymous event must not include user_id")
    if requested_scope == "pre_auth":
        return "pre_auth", None, "UTC"
    if installation.identity_scope != "anonymous_legacy":
        raise ValueError("new events cannot claim legacy identity scope")
    return "anonymous_legacy", None, "UTC"


def _safe_rate(numerator: int, denominator: int) -> float | None:
    return None if denominator == 0 else round(numerator / denominator, 4)


def _aware(value: datetime) -> datetime:
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


def _utc_bounds(
    start_date: date, end_date: date, padding_days: int = 0
) -> tuple[datetime, datetime]:
    return (
        datetime.combine(start_date - timedelta(days=padding_days), time.min, tzinfo=UTC),
        datetime.combine(end_date + timedelta(days=padding_days + 1), time.min, tzinfo=UTC),
    )


async def metrics_overview(
    session: AsyncSession,
    start_date: date,
    end_date: date,
    filters: dict[str, str | None],
    *,
    identity_scope: Literal["authenticated", "anonymous_legacy"] = "authenticated",
) -> MetricsOverview:
    query_start = min(start_date, end_date - timedelta(days=29)) - timedelta(days=7)
    utc_start, utc_end = _utc_bounds(query_start, end_date, 2)
    events = (
        (
            await session.execute(
                select(AnalyticsEvent).where(
                    AnalyticsEvent.occurred_at >= utc_start,
                    AnalyticsEvent.occurred_at < utc_end,
                )
            )
        )
        .scalars()
        .all()
    )
    sessions = (
        (
            await session.execute(
                select(AnalyticsSession).where(
                    AnalyticsSession.started_at >= utc_start,
                    AnalyticsSession.started_at < utc_end,
                )
            )
        )
        .scalars()
        .all()
    )
    installations = (await session.execute(select(AnalyticsInstallation))).scalars().all()
    users = (await session.execute(select(User))).scalars().all()
    login_audits = (
        (
            await session.execute(
                select(AuthLoginAudit).where(
                    AuthLoginAudit.created_at >= utc_start,
                    AuthLoginAudit.created_at < utc_end,
                )
            )
        )
        .scalars()
        .all()
    )
    installation_map = {row.installation_id: row for row in installations}
    user_map = {row.id: row for row in users}

    filtered_events = [
        row
        for row in events
        if row.identity_scope == identity_scope
        and _matches_event(row, installation_map.get(row.installation_id), user_map, filters)
    ]
    filtered_sessions = [
        row
        for row in sessions
        if row.identity_scope == identity_scope
        and _matches_installation(installation_map.get(row.installation_id), filters)
    ]
    active_names = (
        AUTHENTICATED_ACTIVE_EVENT_NAMES
        if identity_scope == "authenticated"
        else LEGACY_ACTIVE_EVENT_NAMES
    )
    active_by_date: dict[date, set[str]] = defaultdict(set)
    active_installations_by_date: dict[date, set[str]] = defaultdict(set)
    for row in filtered_events:
        identifier = row.user_id if identity_scope == "authenticated" else row.anonymous_actor_id
        if row.event_name in active_names and identifier is not None:
            active_by_date[row.event_date].add(identifier)
            active_installations_by_date[row.event_date].add(row.installation_id)
    for session_row in filtered_sessions:
        identifier = (
            session_row.user_id
            if identity_scope == "authenticated"
            else session_row.anonymous_actor_id
        )
        if identifier is not None:
            active_by_date[session_row.local_started_date].add(identifier)
            active_installations_by_date[session_row.local_started_date].add(
                session_row.installation_id
            )

    def active_between(first: date, last: date) -> set[str]:
        result: set[str] = set()
        current = first
        while current <= last:
            result.update(active_by_date.get(current, set()))
            current += timedelta(days=1)
        return result

    window_events = [row for row in filtered_events if start_date <= row.event_date <= end_date]
    window_sessions = [
        row for row in filtered_sessions if start_date <= row.local_started_date <= end_date
    ]
    active_window = active_between(start_date, end_date)
    active_installations = {
        installation_id
        for metric_date, values in active_installations_by_date.items()
        if start_date <= metric_date <= end_date
        for installation_id in values
    }

    def named(name: str) -> list[AnalyticsEvent]:
        return [row for row in window_events if row.event_name == name]

    transaction_events = named("transaction_created")
    nl_submitted = named("natural_language_entry_submitted")
    image_submitted = named("image_analysis_submitted")
    d1, d7 = _retention_summary(users, active_by_date, start_date, end_date)
    ai_usage = await _ai_usage_rows(session, start_date, end_date, filters)
    quota_blocked = sum(row.status == "blocked" for row in ai_usage)
    ai_calls = sum(row.status in {"consumed", "released"} for row in ai_usage)
    ai_success = sum(row.status == "consumed" and row.error_type is None for row in ai_usage)
    legacy_anonymous = len(
        {
            row.anonymous_actor_id
            for row in events
            if row.identity_scope == "anonymous_legacy"
            and start_date <= row.event_date <= end_date
            and row.event_name in LEGACY_ACTIVE_EVENT_NAMES
        }
    )
    new_users = sum(
        start_date <= _local_date(row.created_at, row.timezone) <= end_date
        for row in users
        if row.status != "deleted"
    )
    new_installations = sum(
        start_date <= _local_date(row.first_seen_at, row.user_timezone) <= end_date
        and _matches_installation(row, filters)
        for row in installations
    )
    window_login_audits = [
        row
        for row in login_audits
        if start_date <= _aware(row.created_at).date() <= end_date
        and (not filters.get("auth_provider") or row.provider == filters["auth_provider"])
    ]
    login_successes = sum(row.outcome == "success" for row in window_login_audits)
    login_failures = sum(row.outcome != "success" for row in window_login_audits)
    return MetricsOverview(
        start_date=start_date,
        end_date=end_date,
        dau=len(active_by_date.get(end_date, set())),
        wau=len(active_between(end_date - timedelta(days=6), end_date)),
        mau=len(active_between(end_date - timedelta(days=29), end_date)),
        active_users=len(active_window) if identity_scope == "authenticated" else 0,
        active_installations=len(active_installations),
        legacy_anonymous_active=legacy_anonymous,
        new_users=new_users if identity_scope == "authenticated" else 0,
        new_installations=new_installations,
        login_attempts=len(window_login_audits),
        login_successes=login_successes,
        login_failures=login_failures,
        login_success_rate=_safe_rate(login_successes, len(window_login_audits)),
        sessions=len(window_sessions),
        sessions_per_active_user=_safe_rate(len(window_sessions), len(active_window)),
        transaction_users=len({row.user_id for row in transaction_events if row.user_id}),
        transaction_count=len(transaction_events),
        transactions_per_user=_safe_rate(
            len(transaction_events), len({row.user_id for row in transaction_events if row.user_id})
        ),
        quick_category_usage_rate=_safe_rate(
            len(named("quick_category_used")), len(transaction_events)
        ),
        natural_language_users=len({row.user_id for row in nl_submitted if row.user_id}),
        natural_language_submissions=len(nl_submitted),
        natural_language_confirmation_rate=_safe_rate(
            len(named("natural_language_entry_confirmed")), len(nl_submitted)
        ),
        budget_users=len({row.user_id for row in named("budget_viewed") if row.user_id}),
        analytics_users=len({row.user_id for row in named("analytics_viewed") if row.user_id}),
        ai_users=len({row.user_id for row in ai_usage}),
        ai_calls=ai_calls,
        ai_success_rate=_safe_rate(ai_success, ai_calls),
        image_analysis_users=len({row.user_id for row in image_submitted if row.user_id}),
        d1_retention=d1,
        d7_retention=d7,
        quota_blocked=quota_blocked,
        identity_scope=identity_scope,
    )


async def metrics_timeseries(
    session: AsyncSession,
    start_date: date,
    end_date: date,
    filters: dict[str, str | None],
) -> MetricsTimeseries:
    points: list[MetricsTimePoint] = []
    current = start_date
    while current <= end_date:
        overview = await metrics_overview(session, current, current, filters)
        points.append(
            MetricsTimePoint(
                metric_date=current,
                dau=overview.dau,
                wau=overview.wau,
                mau=overview.mau,
                active_installations=overview.active_installations,
                sessions=overview.sessions,
                new_users=overview.new_users,
                new_installations=overview.new_installations,
            )
        )
        current += timedelta(days=1)
    return MetricsTimeseries(start_date=start_date, end_date=end_date, points=points)


async def metrics_dimensions(
    session: AsyncSession,
    start_date: date,
    end_date: date,
    dimension: str,
    filters: dict[str, str | None],
) -> MetricsDimensions:
    if dimension not in ALLOWED_DIMENSIONS:
        raise ValueError("dimension is not allowed")
    if dimension in {"ai_feature", "ai_status", "error_type", "model"}:
        rows = await _ai_usage_rows(session, start_date, end_date, filters)
        attribute = {
            "ai_feature": "feature",
            "ai_status": "status",
            "error_type": "error_type",
            "model": "model",
        }[dimension]
        values: dict[str, list[AiUsageEvent]] = defaultdict(list)
        for usage_row in rows:
            values[str(getattr(usage_row, attribute) or "none")].append(usage_row)
        return MetricsDimensions(
            dimension=dimension,
            values=[
                DimensionValue(
                    value=value,
                    users=len({row.user_id for row in grouped}),
                    installations=len({row.installation_id for row in grouped}),
                    events=len(grouped),
                )
                for value, grouped in sorted(
                    values.items(), key=lambda item: (-len(item[1]), item[0])
                )
            ],
        )

    utc_start, utc_end = _utc_bounds(start_date, end_date, 2)
    events = (
        (
            await session.execute(
                select(AnalyticsEvent).where(
                    AnalyticsEvent.occurred_at >= utc_start,
                    AnalyticsEvent.occurred_at < utc_end,
                    AnalyticsEvent.identity_scope == "authenticated",
                )
            )
        )
        .scalars()
        .all()
    )
    installations = (await session.execute(select(AnalyticsInstallation))).scalars().all()
    users = (await session.execute(select(User))).scalars().all()
    installation_map = {row.installation_id: row for row in installations}
    user_map = {row.id: row for row in users}
    grouped: dict[str, list[AnalyticsEvent]] = defaultdict(list)
    for event_row in events:
        installation = installation_map.get(event_row.installation_id)
        if not start_date <= event_row.event_date <= end_date or not _matches_event(
            event_row, installation, user_map, filters
        ):
            continue
        value = _dimension_value(dimension, event_row, installation, user_map)
        grouped[value].append(event_row)
    return MetricsDimensions(
        dimension=dimension,
        values=[
            DimensionValue(
                value=value,
                users=len({row.user_id for row in rows if row.user_id}),
                installations=len({row.installation_id for row in rows}),
                events=len(rows),
            )
            for value, rows in sorted(grouped.items(), key=lambda item: (-len(item[1]), item[0]))
        ],
    )


async def metrics_retention(
    session: AsyncSession, start_date: date, end_date: date
) -> MetricsRetention:
    users = (await session.execute(select(User))).scalars().all()
    utc_start, utc_end = _utc_bounds(start_date, end_date + timedelta(days=7), 2)
    events = (
        (
            await session.execute(
                select(AnalyticsEvent).where(
                    AnalyticsEvent.identity_scope == "authenticated",
                    AnalyticsEvent.occurred_at >= utc_start,
                    AnalyticsEvent.occurred_at < utc_end,
                )
            )
        )
        .scalars()
        .all()
    )
    sessions = (
        (
            await session.execute(
                select(AnalyticsSession).where(
                    AnalyticsSession.identity_scope == "authenticated",
                    AnalyticsSession.started_at >= utc_start,
                    AnalyticsSession.started_at < utc_end,
                )
            )
        )
        .scalars()
        .all()
    )
    active: dict[date, set[str]] = defaultdict(set)
    for event_row in events:
        if event_row.user_id and event_row.event_name in AUTHENTICATED_ACTIVE_EVENT_NAMES:
            active[event_row.event_date].add(event_row.user_id)
    for session_row in sessions:
        if session_row.user_id:
            active[session_row.local_started_date].add(session_row.user_id)
    cohorts: list[RetentionCohort] = []
    today = utc_now().date()
    current = start_date
    while current <= end_date:
        cohort = {row.id for row in users if _local_date(row.created_at, row.timezone) == current}
        d1_users = len(cohort & active.get(current + timedelta(days=1), set()))
        d7_users = len(cohort & active.get(current + timedelta(days=7), set()))
        mature_d1 = current <= today - timedelta(days=1)
        mature_d7 = current <= today - timedelta(days=7)
        cohorts.append(
            RetentionCohort(
                cohort_date=current,
                users=len(cohort),
                d1_users=d1_users if mature_d1 else None,
                d1_rate=_safe_rate(d1_users, len(cohort)) if mature_d1 else None,
                d7_users=d7_users if mature_d7 else None,
                d7_rate=_safe_rate(d7_users, len(cohort)) if mature_d7 else None,
            )
        )
        current += timedelta(days=1)
    d1, d7 = _retention_summary(users, active, start_date, end_date)
    return MetricsRetention(
        start_date=start_date,
        end_date=end_date,
        d1_retention=d1,
        d7_retention=d7,
        cohorts=cohorts,
    )


async def ai_usage_metrics(
    session: AsyncSession,
    start_date: date,
    end_date: date,
    filters: dict[str, str | None],
    settings: Settings,
) -> AiUsageMetrics:
    rows = await _ai_usage_rows(session, start_date, end_date, filters)
    calls = [row for row in rows if row.status in {"consumed", "released"}]
    successes = [row for row in calls if row.status == "consumed" and row.error_type is None]
    failures = [row for row in calls if row not in successes]
    latencies = sorted(row.latency_ms for row in calls if row.latency_ms is not None)
    by_feature = Counter(row.feature for row in calls)
    by_model: dict[str, list[AiUsageEvent]] = defaultdict(list)
    for row in calls:
        by_model[row.model or "unknown"].append(row)
    pricing = _pricing(settings.ai_model_pricing_json)
    models = [
        ModelUsage(
            model=model,
            calls=len(values),
            prompt_tokens=sum(row.prompt_tokens for row in values),
            completion_tokens=sum(row.completion_tokens for row in values),
            total_tokens=sum(row.total_tokens for row in values),
            estimated_cost_usd=_estimated_cost(model, values, pricing),
        )
        for model, values in sorted(by_model.items(), key=lambda item: (-len(item[1]), item[0]))
    ]
    calls_by_user = Counter(row.user_id for row in calls)
    active_users = len(calls_by_user)
    return AiUsageMetrics(
        active_users=active_users,
        calls=len(calls),
        successes=len(successes),
        failures=len(failures),
        success_rate=_safe_rate(len(successes), len(calls)),
        average_calls_per_user=(round(len(calls) / active_users, 4) if active_users else None),
        average_latency_ms=round(mean(latencies), 2) if latencies else None,
        p50_latency_ms=_percentile(latencies, 0.50),
        p95_latency_ms=_percentile(latencies, 0.95),
        prompt_tokens=sum(row.prompt_tokens for row in calls),
        completion_tokens=sum(row.completion_tokens for row in calls),
        total_tokens=sum(row.total_tokens for row in calls),
        estimated_cost_usd=round(sum(item.estimated_cost_usd for item in models), 8),
        high_usage_users=sum(value >= 8 for value in calls_by_user.values()),
        kimi_429=sum(row.error_type == "AI_RATE_LIMITED" for row in rows),
        timeouts=sum(row.error_type == "AI_UPSTREAM_TIMEOUT" for row in rows),
        invalid_responses=sum(row.error_type == "AI_INVALID_RESPONSE" for row in rows),
        by_feature=[
            NamedCount(name=name, count=count)
            for name, count in sorted(by_feature.items(), key=lambda item: (-item[1], item[0]))
        ],
        by_model=models,
    )


async def ai_quota_metrics(
    session: AsyncSession,
    start_date: date,
    end_date: date,
    filters: dict[str, str | None],
) -> AiQuotaMetrics:
    rows = await _ai_usage_rows(session, start_date, end_date, filters)
    blocked = [row for row in rows if row.status == "blocked"]
    calls_by_user = Counter(row.user_id for row in rows if row.status in {"consumed", "released"})
    return AiQuotaMetrics(
        blocked=len(blocked),
        daily_limit_users=len({row.user_id for row in blocked if row.error_type == "daily_limit"}),
        weekly_limit_users=len(
            {row.user_id for row in blocked if row.error_type == "weekly_limit"}
        ),
        high_usage_users=sum(value >= 8 for value in calls_by_user.values()),
    )


async def feature_ranking(
    session: AsyncSession, start_date: date, end_date: date
) -> list[NamedCount]:
    utc_start, utc_end = _utc_bounds(start_date, end_date, 2)
    rows = (
        (
            await session.execute(
                select(AnalyticsEvent).where(
                    AnalyticsEvent.identity_scope == "authenticated",
                    AnalyticsEvent.occurred_at >= utc_start,
                    AnalyticsEvent.occurred_at < utc_end,
                )
            )
        )
        .scalars()
        .all()
    )
    counts = Counter(
        _event_feature(row.event_name) for row in rows if start_date <= row.event_date <= end_date
    )
    return [
        NamedCount(name=name, count=count)
        for name, count in sorted(counts.items(), key=lambda item: (-item[1], item[0]))
    ]


async def _ai_usage_rows(
    session: AsyncSession,
    start_date: date,
    end_date: date,
    filters: dict[str, str | None],
) -> list[AiUsageEvent]:
    utc_start, utc_end = _utc_bounds(start_date, end_date, 2)
    rows = (
        (
            await session.execute(
                select(AiUsageEvent).where(
                    AiUsageEvent.occurred_at >= utc_start,
                    AiUsageEvent.occurred_at < utc_end,
                )
            )
        )
        .scalars()
        .all()
    )
    installation_filters = {
        key
        for key in (
            "platform",
            "android_version",
            "app_version",
            "application_id",
            "auth_provider",
            "release_channel",
        )
        if filters.get(key)
    }
    installation_map: dict[str, AnalyticsInstallation] = {}
    if installation_filters:
        installations = (await session.execute(select(AnalyticsInstallation))).scalars().all()
        installation_map = {row.installation_id: row for row in installations}
    user_map: dict[str, User] = {}
    if filters.get("user_type"):
        users = (await session.execute(select(User))).scalars().all()
        user_map = {row.id: row for row in users}
    result = []
    for row in rows:
        if not start_date <= _local_date(row.occurred_at, row.user_timezone) <= end_date:
            continue
        if filters.get("ai_feature") and row.feature != filters["ai_feature"]:
            continue
        if filters.get("ai_status") and row.status != filters["ai_status"]:
            continue
        if filters.get("error_type") and (row.error_type or "none") != filters["error_type"]:
            continue
        if filters.get("model") and (row.model or "unknown") != filters["model"]:
            continue
        if filters.get("feature") and row.feature != filters["feature"]:
            continue
        if installation_filters and not _matches_installation(
            installation_map.get(row.installation_id), filters
        ):
            continue
        if filters.get("user_type"):
            user = user_map.get(row.user_id)
            if user is None:
                continue
            user_type = (
                "new"
                if _local_date(user.created_at, user.timezone)
                == _local_date(row.occurred_at, row.user_timezone)
                else "returning"
            )
            if user_type != filters["user_type"]:
                continue
        result.append(row)
    return result


def _matches_installation(
    installation: AnalyticsInstallation | None, filters: dict[str, str | None]
) -> bool:
    if installation is None:
        return False
    for key in (
        "platform",
        "android_version",
        "app_version",
        "application_id",
        "auth_provider",
        "release_channel",
    ):
        expected = filters.get(key)
        if expected and getattr(installation, key) != expected:
            return False
    return True


def _matches_event(
    event: AnalyticsEvent,
    installation: AnalyticsInstallation | None,
    users: dict[str, User],
    filters: dict[str, str | None],
) -> bool:
    if not _matches_installation(installation, filters):
        return False
    if filters.get("network_type") and event.network_type != filters["network_type"]:
        return False
    if filters.get("feature") and _event_feature(event.event_name) != filters["feature"]:
        return False
    if filters.get("user_type") and event.user_id:
        user = users.get(event.user_id)
        if user is None:
            return False
        user_type = (
            "new"
            if _local_date(user.created_at, user.timezone) == event.event_date
            else "returning"
        )
        if user_type != filters["user_type"]:
            return False
    return True


def _dimension_value(
    dimension: str,
    event: AnalyticsEvent,
    installation: AnalyticsInstallation | None,
    users: dict[str, User],
) -> str:
    if dimension == "feature":
        return _event_feature(event.event_name)
    if dimension == "network_type":
        return event.network_type
    if dimension == "user_type":
        user = users.get(event.user_id or "")
        if user is None:
            return "unknown"
        return (
            "new"
            if _local_date(user.created_at, user.timezone) == event.event_date
            else "returning"
        )
    if installation is None:
        return "unknown"
    return str(getattr(installation, dimension))


def _event_feature(event_name: str) -> str:
    if event_name.startswith("transaction_") or event_name.startswith("quick_category"):
        return "transactions"
    if event_name.startswith("natural_language") or event_name.startswith("ai_parse"):
        return "natural_language_entry"
    if event_name.startswith("budget"):
        return "budget"
    if event_name.startswith("analytics"):
        return "analytics"
    if event_name.startswith("image_analysis"):
        return "image_analysis"
    if event_name.startswith(("ai_chat", "monthly_summary", "financial_plan")):
        return "ai"
    if "login" in event_name or event_name.startswith(("logout", "account_deletion")):
        return "auth"
    if event_name.startswith("session"):
        return "session"
    return "app"


def _local_date(value: datetime, timezone: str) -> date:
    try:
        zone = ZoneInfo(timezone)
    except Exception:
        zone = ZoneInfo("UTC")
    return _aware(value).astimezone(zone).date()


def _retention_summary(
    users: Sequence[User],
    active: dict[date, set[str]],
    start_date: date,
    end_date: date,
) -> tuple[float | None, float | None]:
    today = utc_now().date()

    def calculate(offset: int) -> float | None:
        cohort = [
            row
            for row in users
            if start_date <= _local_date(row.created_at, row.timezone) <= end_date
            and _local_date(row.created_at, row.timezone) <= today - timedelta(days=offset)
        ]
        if not cohort:
            return None
        returned = sum(
            row.id
            in active.get(_local_date(row.created_at, row.timezone) + timedelta(days=offset), set())
            for row in cohort
        )
        return _safe_rate(returned, len(cohort))

    return calculate(1), calculate(7)


def _percentile(values: list[int], quantile: float) -> int | None:
    if not values:
        return None
    index = max(0, min(len(values) - 1, int(round((len(values) - 1) * quantile))))
    return values[index]


def _pricing(value: str) -> dict[str, dict[str, float]]:
    try:
        decoded = json.loads(value)
        if not isinstance(decoded, dict):
            return {}
        result: dict[str, dict[str, float]] = {}
        for model, prices in decoded.items():
            if not isinstance(model, str) or not isinstance(prices, dict):
                continue
            prompt = prices.get("prompt_per_million_usd", 0)
            completion = prices.get("completion_per_million_usd", 0)
            if isinstance(prompt, (int, float)) and isinstance(completion, (int, float)):
                result[model] = {
                    "prompt_per_million_usd": max(0.0, float(prompt)),
                    "completion_per_million_usd": max(0.0, float(completion)),
                }
        return result
    except (TypeError, ValueError, json.JSONDecodeError):
        return {}


def _estimated_cost(
    model: str,
    values: list[AiUsageEvent],
    pricing: dict[str, dict[str, float]],
) -> float:
    price = pricing.get(model, {})
    prompt = sum(row.prompt_tokens for row in values)
    completion = sum(row.completion_tokens for row in values)
    cost = (
        prompt * price.get("prompt_per_million_usd", 0.0)
        + completion * price.get("completion_per_million_usd", 0.0)
    ) / 1_000_000
    return round(cost, 8)
