import hmac
import html
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from fastapi.responses import HTMLResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.analytics.models import AnalyticsInstallation, utc_now
from app.analytics.schemas import (
    AiQuotaMetrics,
    AiUsageMetrics,
    EventBatchRequest,
    EventBatchResponse,
    InstallationRequest,
    InstallationResponse,
    MetricsDimensions,
    MetricsOverview,
    MetricsRetention,
    MetricsTimeseries,
    SessionEndRequest,
    SessionResponse,
    SessionStartRequest,
)
from app.analytics.service import (
    ALLOWED_DIMENSIONS,
    ai_quota_metrics,
    ai_usage_metrics,
    end_session,
    feature_ranking,
    find_installation_by_token,
    ingest_events,
    metrics_dimensions,
    metrics_overview,
    metrics_retention,
    metrics_timeseries,
    register_installation,
    start_session,
)
from app.auth.dependencies import OptionalCurrentUser
from app.config import Settings, get_settings
from app.database import get_session

router = APIRouter(prefix="/api/v1/telemetry", tags=["telemetry"])
internal_router = APIRouter(prefix="/api/v1/internal", tags=["internal"])
page_router = APIRouter(tags=["internal"])

SessionDependency = Annotated[AsyncSession, Depends(get_session)]
SettingsDependency = Annotated[Settings, Depends(get_settings)]


def _bearer(authorization: str | None, *, code: str, message: str) -> str:
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail={"code": code, "message": message})
    return authorization.removeprefix("Bearer ").strip()


async def get_authenticated_installation(
    session: SessionDependency,
    authorization: Annotated[str | None, Header()] = None,
) -> AnalyticsInstallation:
    token = _bearer(
        authorization,
        code="TELEMETRY_UNAUTHORIZED",
        message="Installation token required",
    )
    installation = await find_installation_by_token(session, token)
    if installation is None:
        raise HTTPException(
            status_code=401,
            detail={"code": "TELEMETRY_UNAUTHORIZED", "message": "Installation token invalid"},
        )
    return installation


InstallationDependency = Annotated[AnalyticsInstallation, Depends(get_authenticated_installation)]


async def require_metrics_access(
    settings: SettingsDependency,
    authorization: Annotated[str | None, Header()] = None,
) -> None:
    supplied = _bearer(
        authorization,
        code="METRICS_UNAUTHORIZED",
        message="Internal metrics token required",
    )
    expected = settings.internal_metrics_token
    if not expected or not hmac.compare_digest(supplied, expected):
        raise HTTPException(
            status_code=401,
            detail={"code": "METRICS_UNAUTHORIZED", "message": "Internal metrics token invalid"},
        )


MetricsAccess = Annotated[None, Depends(require_metrics_access)]


@dataclass(frozen=True, slots=True)
class MetricsQuery:
    start_date: date
    end_date: date
    filters: dict[str, str | None]


def metrics_query(
    start_date: Annotated[date | None, Query()] = None,
    end_date: Annotated[date | None, Query()] = None,
    days: Annotated[int | None, Query(ge=1, le=400)] = None,
    platform: Annotated[str | None, Query(max_length=16)] = None,
    android_version: Annotated[str | None, Query(max_length=32)] = None,
    app_version: Annotated[str | None, Query(max_length=32)] = None,
    application_id: Annotated[str | None, Query(max_length=128)] = None,
    auth_provider: Annotated[str | None, Query(max_length=32)] = None,
    user_type: Annotated[str | None, Query(max_length=16)] = None,
    release_channel: Annotated[str | None, Query(max_length=40)] = None,
    feature: Annotated[str | None, Query(max_length=40)] = None,
    network_type: Annotated[str | None, Query(max_length=16)] = None,
    ai_feature: Annotated[str | None, Query(max_length=32)] = None,
    ai_status: Annotated[str | None, Query(max_length=16)] = None,
    error_type: Annotated[str | None, Query(max_length=64)] = None,
    model: Annotated[str | None, Query(max_length=80)] = None,
) -> MetricsQuery:
    resolved_end = end_date or utc_now().date()
    resolved_start = start_date or resolved_end - timedelta(days=(days or 30) - 1)
    if resolved_start > resolved_end or (resolved_end - resolved_start).days >= 400:
        raise HTTPException(
            status_code=422,
            detail={"code": "METRICS_DATE_RANGE_INVALID", "message": "Date range is invalid"},
        )
    filters = {
        "platform": platform,
        "android_version": android_version,
        "app_version": app_version,
        "application_id": application_id,
        "auth_provider": auth_provider,
        "user_type": user_type,
        "release_channel": release_channel,
        "feature": feature,
        "network_type": network_type,
        "ai_feature": ai_feature,
        "ai_status": ai_status,
        "error_type": error_type,
        "model": model,
    }
    if auth_provider and auth_provider not in {
        "phone_one_click",
        "wechat",
        "play_review",
        "unknown",
    }:
        raise HTTPException(
            status_code=422,
            detail={"code": "METRICS_FILTER_INVALID", "message": "auth_provider is invalid"},
        )
    if user_type and user_type not in {"new", "returning"}:
        raise HTTPException(
            status_code=422,
            detail={"code": "METRICS_FILTER_INVALID", "message": "user_type is invalid"},
        )
    if network_type and network_type not in {"wifi", "mobile", "offline", "unknown"}:
        raise HTTPException(
            status_code=422,
            detail={"code": "METRICS_FILTER_INVALID", "message": "network_type is invalid"},
        )
    return MetricsQuery(resolved_start, resolved_end, filters)


MetricsQueryDependency = Annotated[MetricsQuery, Depends(metrics_query)]


@router.post("/installations", response_model=InstallationResponse)
async def create_installation(
    payload: InstallationRequest,
    session: SessionDependency,
    settings: SettingsDependency,
    current: OptionalCurrentUser,
) -> InstallationResponse:
    if not settings.telemetry_enabled:
        raise HTTPException(
            status_code=503,
            detail={"code": "TELEMETRY_DISABLED", "message": "Telemetry is disabled"},
        )
    try:
        _, token = await register_installation(
            session,
            payload,
            user=current.user if current is not None else None,
            auth_provider=current.auth_session.auth_provider if current is not None else "unknown",
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=422,
            detail={"code": "TELEMETRY_INSTALLATION_REJECTED", "message": str(exc)},
        ) from exc
    return InstallationResponse(installation_token=token)


@router.post("/sessions/start", response_model=SessionResponse)
async def create_session(
    payload: SessionStartRequest,
    session: SessionDependency,
    installation: InstallationDependency,
) -> SessionResponse:
    try:
        await start_session(session, installation, payload)
    except ValueError as exc:
        raise HTTPException(
            status_code=422,
            detail={"code": "TELEMETRY_SESSION_REJECTED", "message": str(exc)},
        ) from exc
    return SessionResponse(status="started")


@router.post("/sessions/end", response_model=SessionResponse)
async def close_session(
    payload: SessionEndRequest,
    session: SessionDependency,
    installation: InstallationDependency,
) -> SessionResponse:
    if not await end_session(session, installation, payload):
        raise HTTPException(
            status_code=404,
            detail={"code": "SESSION_NOT_FOUND", "message": "Session not found"},
        )
    return SessionResponse(status="ended")


@router.post("/events/batch", response_model=EventBatchResponse)
async def create_events(
    payload: EventBatchRequest,
    session: SessionDependency,
    installation: InstallationDependency,
) -> EventBatchResponse:
    try:
        accepted, duplicates = await ingest_events(session, installation, payload)
    except ValueError as exc:
        raise HTTPException(
            status_code=422,
            detail={"code": "TELEMETRY_EVENT_REJECTED", "message": str(exc)},
        ) from exc
    return EventBatchResponse(accepted=accepted, duplicates=duplicates)


@internal_router.get("/metrics/overview", response_model=MetricsOverview)
async def overview(
    session: SessionDependency,
    query: MetricsQueryDependency,
    _: MetricsAccess,
    identity_scope: Annotated[
        Literal["authenticated", "anonymous_legacy"], Query()
    ] = "authenticated",
) -> MetricsOverview:
    return await metrics_overview(
        session,
        query.start_date,
        query.end_date,
        query.filters,
        identity_scope=identity_scope,
    )


@internal_router.get("/metrics/timeseries", response_model=MetricsTimeseries)
async def timeseries(
    session: SessionDependency, query: MetricsQueryDependency, _: MetricsAccess
) -> MetricsTimeseries:
    return await metrics_timeseries(session, query.start_date, query.end_date, query.filters)


@internal_router.get("/metrics/dimensions", response_model=MetricsDimensions)
async def dimensions(
    session: SessionDependency,
    query: MetricsQueryDependency,
    _: MetricsAccess,
    dimension: Annotated[str, Query(max_length=32)] = "feature",
) -> MetricsDimensions:
    if dimension not in ALLOWED_DIMENSIONS:
        raise HTTPException(
            status_code=422,
            detail={"code": "METRICS_DIMENSION_INVALID", "message": "Dimension is invalid"},
        )
    return await metrics_dimensions(
        session, query.start_date, query.end_date, dimension, query.filters
    )


@internal_router.get("/metrics/retention", response_model=MetricsRetention)
async def retention(
    session: SessionDependency, query: MetricsQueryDependency, _: MetricsAccess
) -> MetricsRetention:
    return await metrics_retention(session, query.start_date, query.end_date)


@internal_router.get("/metrics/ai-usage", response_model=AiUsageMetrics)
async def ai_usage(
    session: SessionDependency,
    settings: SettingsDependency,
    query: MetricsQueryDependency,
    _: MetricsAccess,
) -> AiUsageMetrics:
    return await ai_usage_metrics(
        session, query.start_date, query.end_date, query.filters, settings
    )


@internal_router.get("/metrics/ai-quota", response_model=AiQuotaMetrics)
async def ai_quota(
    session: SessionDependency, query: MetricsQueryDependency, _: MetricsAccess
) -> AiQuotaMetrics:
    return await ai_quota_metrics(session, query.start_date, query.end_date, query.filters)


@page_router.get("/internal/metrics", response_class=HTMLResponse)
async def metrics_page(
    session: SessionDependency,
    settings: SettingsDependency,
    _: MetricsAccess,
) -> HTMLResponse:
    end_date = utc_now().date()
    start_date = end_date - timedelta(days=29)
    filters: dict[str, str | None] = {}
    overview_value = await metrics_overview(session, start_date, end_date, filters)
    timeseries_value = await metrics_timeseries(session, start_date, end_date, filters)
    usage = await ai_usage_metrics(session, start_date, end_date, filters, settings)
    quota = await ai_quota_metrics(session, start_date, end_date, filters)
    providers = await metrics_dimensions(session, start_date, end_date, "auth_provider", filters)
    versions = await metrics_dimensions(session, start_date, end_date, "app_version", filters)
    features = await feature_ranking(session, start_date, end_date)
    trend_rows = "".join(
        f"<tr><td>{point.metric_date}</td><td>{point.dau}</td>"
        f"<td>{point.active_installations}</td><td>{point.sessions}</td></tr>"
        for point in timeseries_value.points
    )
    feature_rows = "".join(
        f"<li>{html.escape(item.name)}：{item.count}</li>" for item in features[:10]
    )
    provider_rows = "".join(
        f"<li>{html.escape(item.value)}：{item.users}</li>" for item in providers.values
    )
    version_rows = "".join(
        f"<li>{html.escape(item.value)}：{item.users}</li>" for item in versions.values
    )
    body = f"""<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>智能记账运营指标</title>
<style>body{{font:14px/1.5 system-ui;margin:24px;color:#352b28}}.cards{{display:grid;
grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px}}article{{padding:14px;
border:1px solid #eadfd9;border-radius:12px}}table{{width:100%;border-collapse:collapse}}
td,th{{padding:6px;border-bottom:1px solid #eee;text-align:right}}
td:first-child,th:first-child{{text-align:left}}
</style></head><body><h1>智能记账运营指标</h1><p>{start_date} 至 {end_date} · authenticated user</p>
<section class="cards"><article>DAU<br><strong>{overview_value.dau}</strong></article>
<article>WAU<br><strong>{overview_value.wau}</strong></article>
<article>MAU<br><strong>{overview_value.mau}</strong></article>
<article>新增用户<br><strong>{overview_value.new_users}</strong></article>
<article>新增安装<br><strong>{overview_value.new_installations}</strong></article>
<article>AI 调用/成功率<br><strong>{usage.calls} / {usage.success_rate}</strong></article>
<article>配额拦截<br><strong>{quota.blocked}</strong></article>
<article>Token<br><strong>{usage.total_tokens}</strong></article>
<article>D1 / D7<br><strong>{overview_value.d1_retention} /
{overview_value.d7_retention}</strong></article></section>
<h2>最近 30 天活跃趋势</h2><table><thead><tr><th>日期</th><th>DAU</th>
<th>设备</th><th>会话</th></tr></thead>
<tbody>{trend_rows}</tbody></table><h2>功能使用排行</h2><ol>{feature_rows}</ol>
<h2>登录 Provider 分布</h2><ul>{provider_rows}</ul><h2>App 版本分布</h2><ul>{version_rows}</ul>
<p>页面只展示聚合数据，不包含手机号、微信身份、财务内容或 AI 正文。</p></body></html>"""
    return HTMLResponse(body)
