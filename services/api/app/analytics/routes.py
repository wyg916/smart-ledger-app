import hmac
from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.analytics.models import AnalyticsInstallation
from app.analytics.schemas import (
    EventBatchRequest,
    EventBatchResponse,
    InstallationRequest,
    InstallationResponse,
    MetricsOverview,
    SessionEndRequest,
    SessionResponse,
    SessionStartRequest,
)
from app.analytics.service import (
    end_session,
    find_installation_by_token,
    ingest_events,
    metrics_overview,
    register_installation,
    start_session,
)
from app.config import Settings, get_settings
from app.database import get_session

router = APIRouter(prefix="/api/v1/telemetry", tags=["telemetry"])
internal_router = APIRouter(prefix="/api/v1/internal", tags=["internal"])

SessionDependency = Annotated[AsyncSession, Depends(get_session)]
SettingsDependency = Annotated[Settings, Depends(get_settings)]


def _bearer(authorization: str | None) -> str:
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail={"code": "TELEMETRY_UNAUTHORIZED", "message": "Installation token required"},
        )
    return authorization.removeprefix("Bearer ").strip()


async def get_authenticated_installation(
    session: SessionDependency,
    authorization: Annotated[str | None, Header()] = None,
) -> AnalyticsInstallation:
    installation = await find_installation_by_token(session, _bearer(authorization))
    if installation is None:
        raise HTTPException(
            status_code=401,
            detail={"code": "TELEMETRY_UNAUTHORIZED", "message": "Installation token invalid"},
        )
    return installation


InstallationDependency = Annotated[AnalyticsInstallation, Depends(get_authenticated_installation)]


@router.post("/installations", response_model=InstallationResponse)
async def create_installation(
    payload: InstallationRequest,
    session: SessionDependency,
    settings: SettingsDependency,
) -> InstallationResponse:
    if not settings.telemetry_enabled:
        raise HTTPException(
            status_code=503,
            detail={"code": "TELEMETRY_DISABLED", "message": "Telemetry is disabled"},
        )
    _, token = await register_installation(session, payload)
    return InstallationResponse(installation_token=token)


@router.post("/sessions/start", response_model=SessionResponse)
async def create_session(
    payload: SessionStartRequest,
    session: SessionDependency,
    installation: InstallationDependency,
) -> SessionResponse:
    await start_session(session, installation, payload)
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
    settings: SettingsDependency,
    authorization: Annotated[str | None, Header()] = None,
    days: Annotated[int, Query(ge=1, le=30)] = 30,
) -> MetricsOverview:
    expected = settings.internal_metrics_token
    supplied = _bearer(authorization)
    if not expected or not hmac.compare_digest(supplied, expected):
        raise HTTPException(
            status_code=401,
            detail={"code": "METRICS_UNAUTHORIZED", "message": "Internal metrics token invalid"},
        )
    return await metrics_overview(session, days)
