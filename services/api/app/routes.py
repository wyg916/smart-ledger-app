from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import SQLAlchemyError

from app.config import Settings, get_settings
from app.database import DatabaseProbe, get_database_probe
from app.schemas import ErrorResponse, ServiceStatus, VersionResponse

router = APIRouter()


def _service_status(settings: Settings, state: str) -> ServiceStatus:
    return ServiceStatus(
        status=state,
        service=settings.app_name,
        version=settings.app_version,
        environment=settings.environment,
    )


@router.get("/health/live", response_model=ServiceStatus)
async def liveness(settings: Annotated[Settings, Depends(get_settings)]) -> ServiceStatus:
    return _service_status(settings, "ok")


@router.get(
    "/health/ready",
    response_model=ServiceStatus,
    responses={status.HTTP_503_SERVICE_UNAVAILABLE: {"model": ErrorResponse}},
)
async def readiness(
    settings: Annotated[Settings, Depends(get_settings)],
    probe: Annotated[DatabaseProbe, Depends(get_database_probe)],
) -> ServiceStatus:
    try:
        await probe()
    except (OSError, SQLAlchemyError) as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={"code": "database_unavailable", "message": "Database is not ready"},
        ) from exc
    return _service_status(settings, "ready")


@router.get("/version", response_model=VersionResponse)
async def version(settings: Annotated[Settings, Depends(get_settings)]) -> VersionResponse:
    return VersionResponse(
        service=settings.app_name,
        version=settings.app_version,
        environment=settings.environment,
    )
