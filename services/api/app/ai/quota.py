from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from typing import Any
from uuid import uuid4
from zoneinfo import ZoneInfo

from sqlalchemy import case, select, update
from sqlalchemy.dialects.postgresql import insert as postgresql_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.errors import AiError
from app.ai.models import AiQuotaCounter, AiQuotaPlan, AiUsageEvent
from app.ai.schemas import AiQuotaStatus, TokenUsage
from app.analytics.models import utc_now
from app.auth.models import User
from app.config import Settings


@dataclass(frozen=True, slots=True)
class QuotaPeriods:
    daily_start: datetime
    daily_end: datetime
    weekly_start: datetime
    weekly_end: datetime


@dataclass(frozen=True, slots=True)
class QuotaReservation:
    event_id: str
    request_id: str
    user_id: str
    feature: str
    periods: QuotaPeriods


def quota_periods(now: datetime, timezone: str) -> QuotaPeriods:
    zone = ZoneInfo(timezone)
    current = _aware(now).astimezone(zone)
    daily_date = current.date()
    weekly_date = daily_date - timedelta(days=daily_date.weekday())

    def boundary(local_date: date) -> datetime:
        return datetime.combine(local_date, time.min, tzinfo=zone).astimezone(UTC)

    return QuotaPeriods(
        daily_start=boundary(daily_date),
        daily_end=boundary(daily_date + timedelta(days=1)),
        weekly_start=boundary(weekly_date),
        weekly_end=boundary(weekly_date + timedelta(days=7)),
    )


def should_consume_error(error: AiError) -> bool:
    return error.code in {"AI_UPSTREAM_TIMEOUT", "AI_INVALID_RESPONSE"}


class QuotaService:
    def __init__(
        self,
        session: AsyncSession,
        settings: Settings,
        clock: Callable[[], datetime] = utc_now,
    ) -> None:
        self._session = session
        self._settings = settings
        self._clock = clock

    async def status(self, user: User) -> AiQuotaStatus:
        now = _aware(self._clock())
        await self._cleanup_stale(user.id, now)
        status = await self._status_without_cleanup(user, now)
        await self._session.commit()
        return status

    async def prepare_timezone_change(self, user: User, new_timezone: str) -> bool:
        """Carry current usage into the new local periods without rewriting history.

        A timezone change is rejected while a reservation is in flight because that
        reservation must settle against the period in which it was created.
        """
        now = _aware(self._clock())
        await self._cleanup_stale(user.id, now)
        old_periods = quota_periods(now, user.timezone)
        new_periods = quota_periods(now, new_timezone)
        period_pairs = (
            (
                "daily",
                old_periods.daily_start,
                new_periods.daily_start,
                new_periods.daily_end,
            ),
            (
                "weekly",
                old_periods.weekly_start,
                new_periods.weekly_start,
                new_periods.weekly_end,
            ),
        )
        for period_type, old_start, new_start, new_end in period_pairs:
            if old_start == new_start:
                continue
            old_counter = (
                await self._session.execute(
                    select(AiQuotaCounter)
                    .where(
                        AiQuotaCounter.user_id == user.id,
                        AiQuotaCounter.period_type == period_type,
                        AiQuotaCounter.period_start == old_start,
                    )
                    .with_for_update()
                )
            ).scalar_one_or_none()
            if old_counter is None:
                continue
            if old_counter.reserved_units > 0:
                return False
            await self._ensure_counter(user.id, period_type, new_start, new_end, now)
            await self._session.execute(
                update(AiQuotaCounter)
                .where(
                    AiQuotaCounter.user_id == user.id,
                    AiQuotaCounter.period_type == period_type,
                    AiQuotaCounter.period_start == new_start,
                )
                .values(
                    used_units=case(
                        (
                            AiQuotaCounter.used_units < old_counter.used_units,
                            old_counter.used_units,
                        ),
                        else_=AiQuotaCounter.used_units,
                    ),
                    updated_at=now,
                    version=AiQuotaCounter.version + 1,
                )
            )
        return True

    async def reserve(
        self,
        *,
        user: User,
        installation_id: str,
        feature: str,
        request_id: str,
    ) -> QuotaReservation:
        now = _aware(self._clock())
        plan = await self._active_plan(user.plan_code, now)
        periods = quota_periods(now, user.timezone)
        await self._cleanup_stale(user.id, now)

        event_id = str(uuid4())
        inserted = await self._insert_ignore(
            AiUsageEvent,
            {
                "id": event_id,
                "request_id": request_id,
                "user_id": user.id,
                "installation_id": installation_id,
                "feature": feature,
                "model": None,
                "status": "reserved",
                "quota_units": 1,
                "prompt_tokens": 0,
                "completion_tokens": 0,
                "total_tokens": 0,
                "latency_ms": None,
                "user_timezone": user.timezone,
                "occurred_at": now,
                "daily_period_start": periods.daily_start,
                "weekly_period_start": periods.weekly_start,
                "error_type": None,
                "created_at": now,
                "updated_at": now,
            },
            ["user_id", "request_id"],
        )
        if not inserted:
            existing = (
                await self._session.execute(
                    select(AiUsageEvent).where(
                        AiUsageEvent.user_id == user.id,
                        AiUsageEvent.request_id == request_id,
                    )
                )
            ).scalar_one()
            status = await self.status(user)
            if existing.status == "blocked":
                raise self._quota_error(status, existing.error_type or "limit")
            raise AiError(
                "AI_REQUEST_ALREADY_PROCESSED",
                "AI request id has already been processed",
                409,
                details={"request_status": existing.status, **status.model_dump(mode="json")},
            )

        await self._ensure_counter(user.id, "daily", periods.daily_start, periods.daily_end, now)
        await self._ensure_counter(user.id, "weekly", periods.weekly_start, periods.weekly_end, now)
        daily_reserved = await self._reserve_counter(
            user.id, "daily", periods.daily_start, plan.daily_limit, now
        )
        if not daily_reserved:
            await self._block(event_id, "daily_limit", now)
            await self._session.commit()
            raise self._quota_error(await self._status_without_cleanup(user, now), "daily_limit")

        weekly_reserved = await self._reserve_counter(
            user.id, "weekly", periods.weekly_start, plan.weekly_limit, now
        )
        if not weekly_reserved:
            await self._decrement_reserved(user.id, "daily", periods.daily_start, now)
            await self._block(event_id, "weekly_limit", now)
            await self._session.commit()
            raise self._quota_error(await self._status_without_cleanup(user, now), "weekly_limit")

        await self._session.commit()
        return QuotaReservation(
            event_id=event_id,
            request_id=request_id,
            user_id=user.id,
            feature=feature,
            periods=periods,
        )

    async def consume(
        self,
        reservation: QuotaReservation,
        *,
        model: str | None,
        usage: TokenUsage | None,
        latency_ms: int,
        error_type: str | None = None,
    ) -> None:
        event = await self._session.get(AiUsageEvent, reservation.event_id)
        if event is None or event.status != "reserved":
            return
        now = _aware(self._clock())
        for period_type, start in (
            ("daily", reservation.periods.daily_start),
            ("weekly", reservation.periods.weekly_start),
        ):
            await self._session.execute(
                update(AiQuotaCounter)
                .where(
                    AiQuotaCounter.user_id == reservation.user_id,
                    AiQuotaCounter.period_type == period_type,
                    AiQuotaCounter.period_start == start,
                    AiQuotaCounter.reserved_units > 0,
                )
                .values(
                    reserved_units=AiQuotaCounter.reserved_units - 1,
                    used_units=AiQuotaCounter.used_units + 1,
                    updated_at=now,
                    version=AiQuotaCounter.version + 1,
                )
            )
        event.status = "consumed"
        event.model = model
        event.prompt_tokens = usage.prompt_tokens if usage is not None else 0
        event.completion_tokens = usage.completion_tokens if usage is not None else 0
        event.total_tokens = usage.total_tokens if usage is not None else 0
        event.latency_ms = max(0, latency_ms)
        event.error_type = error_type
        event.updated_at = now
        await self._session.commit()

    async def release(
        self,
        reservation: QuotaReservation,
        *,
        error_type: str,
        latency_ms: int,
    ) -> None:
        event = await self._session.get(AiUsageEvent, reservation.event_id)
        if event is None or event.status != "reserved":
            return
        now = _aware(self._clock())
        for period_type, start in (
            ("daily", reservation.periods.daily_start),
            ("weekly", reservation.periods.weekly_start),
        ):
            await self._decrement_reserved(reservation.user_id, period_type, start, now)
        event.status = "released"
        event.error_type = error_type
        event.latency_ms = max(0, latency_ms)
        event.updated_at = now
        await self._session.commit()

    async def _status_without_cleanup(self, user: User, now: datetime) -> AiQuotaStatus:
        plan = await self._active_plan(user.plan_code, now)
        periods = quota_periods(now, user.timezone)
        daily = await self._counter(user.id, "daily", periods.daily_start)
        weekly = await self._counter(user.id, "weekly", periods.weekly_start)
        daily_used = daily.used_units if daily is not None else 0
        daily_reserved = daily.reserved_units if daily is not None else 0
        weekly_used = weekly.used_units if weekly is not None else 0
        weekly_reserved = weekly.reserved_units if weekly is not None else 0
        return AiQuotaStatus(
            plan_code=plan.plan_code,
            daily_limit=plan.daily_limit,
            daily_used=daily_used,
            daily_reserved=daily_reserved,
            daily_remaining=max(0, plan.daily_limit - daily_used - daily_reserved),
            weekly_limit=plan.weekly_limit,
            weekly_used=weekly_used,
            weekly_reserved=weekly_reserved,
            weekly_remaining=max(0, plan.weekly_limit - weekly_used - weekly_reserved),
            next_daily_reset_at=periods.daily_end,
            next_weekly_reset_at=periods.weekly_end,
            user_timezone=user.timezone,
        )

    async def _active_plan(self, plan_code: str, now: datetime) -> AiQuotaPlan:
        plan = await self._session.get(AiQuotaPlan, plan_code)
        if plan is None:
            limits = self._configured_plan_limits(plan_code)
            if limits is None:
                raise AiError("AI_QUOTA_PLAN_UNAVAILABLE", "AI quota plan is unavailable", 503)
            await self._insert_ignore(
                AiQuotaPlan,
                {
                    "plan_code": plan_code,
                    "daily_limit": limits[0],
                    "weekly_limit": limits[1],
                    "is_active": True,
                    "effective_from": now,
                    "effective_to": None,
                },
                ["plan_code"],
            )
            plan = await self._session.get(AiQuotaPlan, plan_code)
        if (
            plan is None
            or not plan.is_active
            or _aware(plan.effective_from) > now
            or (plan.effective_to is not None and _aware(plan.effective_to) <= now)
        ):
            raise AiError("AI_QUOTA_PLAN_UNAVAILABLE", "AI quota plan is unavailable", 503)
        return plan

    def _configured_plan_limits(self, plan_code: str) -> tuple[int, int] | None:
        return {
            "free": (
                self._settings.ai_free_daily_limit,
                self._settings.ai_free_weekly_limit,
            ),
            "review": (
                self._settings.ai_review_daily_limit,
                self._settings.ai_review_weekly_limit,
            ),
            "internal_test": (
                self._settings.ai_internal_test_daily_limit,
                self._settings.ai_internal_test_weekly_limit,
            ),
        }.get(plan_code)

    async def _ensure_counter(
        self,
        user_id: str,
        period_type: str,
        period_start: datetime,
        period_end: datetime,
        now: datetime,
    ) -> None:
        await self._insert_ignore(
            AiQuotaCounter,
            {
                "user_id": user_id,
                "period_type": period_type,
                "period_start": period_start,
                "period_end": period_end,
                "used_units": 0,
                "reserved_units": 0,
                "updated_at": now,
                "version": 1,
            },
            ["user_id", "period_type", "period_start"],
        )

    async def _reserve_counter(
        self,
        user_id: str,
        period_type: str,
        period_start: datetime,
        limit: int,
        now: datetime,
    ) -> bool:
        result = await self._session.execute(
            update(AiQuotaCounter)
            .where(
                AiQuotaCounter.user_id == user_id,
                AiQuotaCounter.period_type == period_type,
                AiQuotaCounter.period_start == period_start,
                AiQuotaCounter.used_units + AiQuotaCounter.reserved_units < limit,
            )
            .values(
                reserved_units=AiQuotaCounter.reserved_units + 1,
                updated_at=now,
                version=AiQuotaCounter.version + 1,
            )
        )
        return bool(getattr(result, "rowcount", 0))

    async def _decrement_reserved(
        self, user_id: str, period_type: str, period_start: datetime, now: datetime
    ) -> None:
        await self._session.execute(
            update(AiQuotaCounter)
            .where(
                AiQuotaCounter.user_id == user_id,
                AiQuotaCounter.period_type == period_type,
                AiQuotaCounter.period_start == period_start,
            )
            .values(
                reserved_units=case(
                    (AiQuotaCounter.reserved_units > 0, AiQuotaCounter.reserved_units - 1),
                    else_=0,
                ),
                updated_at=now,
                version=AiQuotaCounter.version + 1,
            )
        )

    async def _cleanup_stale(self, user_id: str, now: datetime) -> None:
        cutoff = now - timedelta(seconds=self._settings.ai_reservation_ttl_seconds)
        stale = (
            (
                await self._session.execute(
                    select(AiUsageEvent).where(
                        AiUsageEvent.user_id == user_id,
                        AiUsageEvent.status == "reserved",
                        AiUsageEvent.updated_at < cutoff,
                    )
                )
            )
            .scalars()
            .all()
        )
        for event in stale:
            claimed = await self._session.execute(
                update(AiUsageEvent)
                .where(
                    AiUsageEvent.id == event.id,
                    AiUsageEvent.status == "reserved",
                    AiUsageEvent.updated_at < cutoff,
                )
                .values(
                    status="released",
                    error_type="reservation_expired",
                    updated_at=now,
                )
                .execution_options(synchronize_session=False)
            )
            if not getattr(claimed, "rowcount", 0):
                continue
            event.status = "released"
            event.error_type = "reservation_expired"
            event.updated_at = now
            await self._decrement_reserved(user_id, "daily", _aware(event.daily_period_start), now)
            await self._decrement_reserved(
                user_id, "weekly", _aware(event.weekly_period_start), now
            )

    async def _counter(
        self, user_id: str, period_type: str, period_start: datetime
    ) -> AiQuotaCounter | None:
        return (
            await self._session.execute(
                select(AiQuotaCounter).where(
                    AiQuotaCounter.user_id == user_id,
                    AiQuotaCounter.period_type == period_type,
                    AiQuotaCounter.period_start == period_start,
                )
            )
        ).scalar_one_or_none()

    async def _block(self, event_id: str, reason: str, now: datetime) -> None:
        event = await self._session.get(AiUsageEvent, event_id)
        if event is not None:
            event.status = "blocked"
            event.error_type = reason
            event.updated_at = now

    async def _insert_ignore(
        self, model: type[Any], values: dict[str, Any], index_elements: list[str]
    ) -> bool:
        bind = self._session.get_bind()
        if bind.dialect.name == "postgresql":
            statement = (
                postgresql_insert(model)
                .values(**values)
                .on_conflict_do_nothing(index_elements=index_elements)
            )
            result = await self._session.execute(statement)
            return bool(getattr(result, "rowcount", 0))
        elif bind.dialect.name == "sqlite":
            sqlite_statement = (
                sqlite_insert(model)
                .values(**values)
                .on_conflict_do_nothing(index_elements=index_elements)
            )
            result = await self._session.execute(sqlite_statement)
            return bool(getattr(result, "rowcount", 0))
        else:
            raise AiError("AI_QUOTA_DATABASE_UNSUPPORTED", "AI quota database unsupported", 503)

    def _quota_error(self, status: AiQuotaStatus, reason: str) -> AiError:
        return AiError(
            "AI_QUOTA_EXCEEDED",
            "AI usage quota exceeded",
            429,
            details={"limit_reason": reason, **status.model_dump(mode="json")},
        )


def _aware(value: datetime) -> datetime:
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)
