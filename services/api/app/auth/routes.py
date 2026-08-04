import logging
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import CurrentUser
from app.auth.providers.base import (
    AuthProviderError,
    PhoneOneClickProvider,
    WechatProvider,
)
from app.auth.providers.fake import FakePhoneOneClickProvider, FakeWechatProvider
from app.auth.providers.tencent_phone import TencentPhoneOneClickProvider
from app.auth.providers.wechat import HttpWechatProvider
from app.auth.schemas import (
    AuthResponse,
    DeletionConfirmPayload,
    DeletionRequestPayload,
    DeletionResponse,
    IdentityResponse,
    LogoutRequest,
    PhoneLoginRequest,
    RefreshRequest,
    ReviewLoginRequest,
    StatusResponse,
    UserView,
    WechatLoginRequest,
    WechatStateRequest,
    WechatStateResponse,
)
from app.auth.service import (
    AuthenticationError,
    IdentityConflictError,
    RateLimitError,
    ReplayError,
    confirm_deletion,
    consume_provider_token,
    consume_wechat_state,
    create_auth_session,
    create_deletion_request,
    enforce_rate_limit,
    find_or_create_identity_user,
    issue_wechat_state,
    phone_subject,
    record_login_audit,
    refresh_auth_session,
    request_fingerprint,
    review_login,
    revoke_session,
    unbind_identity,
    user_view,
    wechat_subject,
)
from app.config import Settings, get_settings
from app.database import get_session

logger = logging.getLogger("app.auth")

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])
account_router = APIRouter(prefix="/api/v1/account", tags=["account"])

SessionDependency = Annotated[AsyncSession, Depends(get_session)]
SettingsDependency = Annotated[Settings, Depends(get_settings)]


def get_phone_provider(settings: SettingsDependency) -> PhoneOneClickProvider:
    if settings.phone_auth_provider == "fake":
        if settings.environment == "production":
            raise HTTPException(
                status_code=503,
                detail={
                    "code": "PHONE_PROVIDER_NOT_CONFIGURED",
                    "message": "Phone login unavailable",
                },
            )
        return FakePhoneOneClickProvider()
    if settings.phone_auth_provider == "tencent":
        if not settings.tencent_phone_sdk_app_id or not settings.tencent_phone_app_key:
            raise HTTPException(
                status_code=503,
                detail={
                    "code": "PHONE_PROVIDER_NOT_CONFIGURED",
                    "message": "Phone login unavailable",
                },
            )
        return TencentPhoneOneClickProvider(
            settings.tencent_phone_sdk_app_id,
            settings.tencent_phone_app_key,
            settings.tencent_phone_validate_url,
        )
    raise HTTPException(
        status_code=503,
        detail={"code": "PHONE_PROVIDER_NOT_CONFIGURED", "message": "Phone login unavailable"},
    )


def get_wechat_provider(settings: SettingsDependency) -> WechatProvider:
    if settings.wechat_auth_provider == "fake":
        if settings.environment == "production":
            raise HTTPException(
                status_code=503,
                detail={
                    "code": "WECHAT_PROVIDER_NOT_CONFIGURED",
                    "message": "WeChat login unavailable",
                },
            )
        return FakeWechatProvider()
    if settings.wechat_auth_provider == "wechat":
        if not settings.wechat_app_id or not settings.wechat_app_secret:
            raise HTTPException(
                status_code=503,
                detail={
                    "code": "WECHAT_PROVIDER_NOT_CONFIGURED",
                    "message": "WeChat login unavailable",
                },
            )
        return HttpWechatProvider(
            settings.wechat_app_id, settings.wechat_app_secret, settings.wechat_api_base_url
        )
    raise HTTPException(
        status_code=503,
        detail={"code": "WECHAT_PROVIDER_NOT_CONFIGURED", "message": "WeChat login unavailable"},
    )


PhoneProviderDependency = Annotated[PhoneOneClickProvider, Depends(get_phone_provider)]
WechatProviderDependency = Annotated[WechatProvider, Depends(get_wechat_provider)]


def _request_id(request: Request) -> str:
    return str(getattr(request.state, "request_id", "missing"))


async def _rate_context(
    request: Request,
    session: AsyncSession,
    settings: Settings,
    provider: str,
    limit: int,
) -> str:
    fingerprint = await request_fingerprint(
        request.client.host if request.client else None, settings
    )
    try:
        await enforce_rate_limit(session, provider=provider, fingerprint=fingerprint, limit=limit)
    except RateLimitError as exc:
        raise HTTPException(
            status_code=429,
            detail={"code": "AUTH_RATE_LIMITED", "message": "Too many login attempts"},
        ) from exc
    return fingerprint


def _auth_error(exc: Exception) -> HTTPException:
    if isinstance(exc, RateLimitError):
        return HTTPException(
            status_code=429,
            detail={"code": "AUTH_RATE_LIMITED", "message": "Too many login attempts"},
        )
    if isinstance(exc, ReplayError):
        return HTTPException(
            status_code=409,
            detail={"code": "AUTH_REPLAY_REJECTED", "message": "Credential already used"},
        )
    if isinstance(exc, IdentityConflictError):
        return HTTPException(
            status_code=409,
            detail={
                "code": "AUTH_IDENTITY_CONFLICT",
                "message": "Identity belongs to another user",
            },
        )
    return HTTPException(
        status_code=401,
        detail={"code": "AUTH_FAILED", "message": "Authentication failed"},
    )


@router.post("/phone/one-click", response_model=AuthResponse)
async def phone_login(
    payload: PhoneLoginRequest,
    request: Request,
    session: SessionDependency,
    settings: SettingsDependency,
    provider: PhoneProviderDependency,
) -> AuthResponse:
    fingerprint = await _rate_context(request, session, settings, "phone_one_click", 8)
    try:
        await consume_provider_token(
            session, purpose="phone_token", value=payload.token, settings=settings
        )
        verified = await provider.verify(payload.token, payload.carrier)
        subject_hash, hint = phone_subject(verified.normalized_phone, settings)
        user = await find_or_create_identity_user(
            session,
            provider="phone_one_click",
            subject_hash=subject_hash,
            phone_hash=subject_hash,
            display_hint=hint,
        )
        response = await create_auth_session(
            session,
            user=user,
            installation_id=str(payload.installation_id),
            settings=settings,
        )
        await record_login_audit(
            session,
            provider="phone_one_click",
            outcome="success",
            request_id=_request_id(request),
            fingerprint=fingerprint,
            user_id=user.id,
        )
        logger.info(
            "auth provider=phone_one_click outcome=success request_id=%s", _request_id(request)
        )
        return response
    except (AuthProviderError, AuthenticationError, IdentityConflictError, ReplayError) as exc:
        await record_login_audit(
            session,
            provider="phone_one_click",
            outcome="failed",
            request_id=_request_id(request),
            fingerprint=fingerprint,
        )
        raise _auth_error(exc) from exc


@router.post("/wechat/state", response_model=WechatStateResponse)
async def wechat_state(
    payload: WechatStateRequest,
    request: Request,
    session: SessionDependency,
    settings: SettingsDependency,
) -> WechatStateResponse:
    del payload
    await _rate_context(request, session, settings, "wechat_state", 12)
    state, expires = await issue_wechat_state(session, settings)
    return WechatStateResponse(state=state, expires_in_seconds=expires)


@router.post("/wechat", response_model=AuthResponse)
async def wechat_login(
    payload: WechatLoginRequest,
    request: Request,
    session: SessionDependency,
    settings: SettingsDependency,
    provider: WechatProviderDependency,
) -> AuthResponse:
    fingerprint = await _rate_context(request, session, settings, "wechat", 8)
    try:
        await consume_wechat_state(session, payload.state, settings)
        await consume_provider_token(
            session, purpose="wechat_code", value=payload.code, settings=settings
        )
        verified = await provider.exchange(payload.code)
        user = await find_or_create_identity_user(
            session,
            provider="wechat",
            subject_hash=wechat_subject(verified.subject, settings),
            display_hint="微信",
        )
        response = await create_auth_session(
            session,
            user=user,
            installation_id=str(payload.installation_id),
            settings=settings,
        )
        await record_login_audit(
            session,
            provider="wechat",
            outcome="success",
            request_id=_request_id(request),
            fingerprint=fingerprint,
            user_id=user.id,
        )
        logger.info("auth provider=wechat outcome=success request_id=%s", _request_id(request))
        return response
    except (AuthProviderError, AuthenticationError, IdentityConflictError, ReplayError) as exc:
        await record_login_audit(
            session,
            provider="wechat",
            outcome="failed",
            request_id=_request_id(request),
            fingerprint=fingerprint,
        )
        raise _auth_error(exc) from exc


@router.post("/review-login", response_model=AuthResponse)
async def login_review_account(
    payload: ReviewLoginRequest,
    request: Request,
    session: SessionDependency,
    settings: SettingsDependency,
) -> AuthResponse:
    if not settings.review_login_enabled:
        raise HTTPException(
            status_code=503,
            detail={"code": "REVIEW_LOGIN_DISABLED", "message": "Review login unavailable"},
        )
    fingerprint = await _rate_context(request, session, settings, "play_review", 5)
    try:
        response = await review_login(
            session,
            username=payload.username,
            password=payload.password,
            installation_id=str(payload.installation_id),
            settings=settings,
        )
        await record_login_audit(
            session,
            provider="play_review",
            outcome="success",
            request_id=_request_id(request),
            fingerprint=fingerprint,
            user_id=response.user.user_id,
        )
        return response
    except AuthenticationError as exc:
        await record_login_audit(
            session,
            provider="play_review",
            outcome="failed",
            request_id=_request_id(request),
            fingerprint=fingerprint,
        )
        raise _auth_error(exc) from exc


@router.post("/refresh", response_model=AuthResponse)
async def refresh(
    payload: RefreshRequest, session: SessionDependency, settings: SettingsDependency
) -> AuthResponse:
    try:
        return await refresh_auth_session(session, payload.refresh_token, settings)
    except (AuthenticationError, ReplayError) as exc:
        raise _auth_error(exc) from exc


@router.post("/logout", response_model=StatusResponse)
async def logout(
    payload: LogoutRequest, session: SessionDependency, current: CurrentUser
) -> StatusResponse:
    await revoke_session(session, current, payload.refresh_token)
    return StatusResponse(status="logged_out")


@router.get("/me", response_model=UserView)
async def me(session: SessionDependency, current: CurrentUser) -> UserView:
    return await user_view(session, current.user)


@router.post("/identities/bind-phone", response_model=IdentityResponse)
async def bind_phone(
    payload: PhoneLoginRequest,
    session: SessionDependency,
    settings: SettingsDependency,
    current: CurrentUser,
    provider: PhoneProviderDependency,
) -> IdentityResponse:
    try:
        await consume_provider_token(
            session, purpose="phone_token", value=payload.token, settings=settings
        )
        verified = await provider.verify(payload.token, payload.carrier)
        subject_hash, hint = phone_subject(verified.normalized_phone, settings)
        await find_or_create_identity_user(
            session,
            provider="phone_one_click",
            subject_hash=subject_hash,
            phone_hash=subject_hash,
            display_hint=hint,
            bind_user_id=current.user.id,
        )
        return IdentityResponse(providers=(await user_view(session, current.user)).providers)
    except (AuthProviderError, AuthenticationError, IdentityConflictError, ReplayError) as exc:
        raise _auth_error(exc) from exc


@router.post("/identities/bind-wechat", response_model=IdentityResponse)
async def bind_wechat(
    payload: WechatLoginRequest,
    session: SessionDependency,
    settings: SettingsDependency,
    current: CurrentUser,
    provider: WechatProviderDependency,
) -> IdentityResponse:
    try:
        await consume_wechat_state(session, payload.state, settings)
        await consume_provider_token(
            session, purpose="wechat_code", value=payload.code, settings=settings
        )
        verified = await provider.exchange(payload.code)
        await find_or_create_identity_user(
            session,
            provider="wechat",
            subject_hash=wechat_subject(verified.subject, settings),
            display_hint="微信",
            bind_user_id=current.user.id,
        )
        return IdentityResponse(providers=(await user_view(session, current.user)).providers)
    except (AuthProviderError, AuthenticationError, IdentityConflictError, ReplayError) as exc:
        raise _auth_error(exc) from exc


@router.delete("/identities/{provider}", response_model=IdentityResponse)
async def delete_identity(
    provider: str, session: SessionDependency, current: CurrentUser
) -> IdentityResponse:
    if provider not in {"phone_one_click", "wechat", "play_review"}:
        raise HTTPException(
            status_code=404,
            detail={"code": "AUTH_IDENTITY_NOT_FOUND", "message": "Identity not found"},
        )
    try:
        return IdentityResponse(providers=await unbind_identity(session, current, provider))
    except AuthenticationError as exc:
        raise _auth_error(exc) from exc


@account_router.post("/deletion-request", response_model=DeletionResponse)
async def deletion_request(
    payload: DeletionRequestPayload,
    session: SessionDependency,
    settings: SettingsDependency,
    current: CurrentUser,
) -> DeletionResponse:
    return await create_deletion_request(
        session,
        context=current,
        idempotency_key=payload.idempotency_key,
        local_data_action=payload.local_data_action,
        settings=settings,
    )


@account_router.post("/deletion-confirm", response_model=DeletionResponse)
async def deletion_confirm(
    payload: DeletionConfirmPayload,
    session: SessionDependency,
    current: CurrentUser,
) -> DeletionResponse:
    del payload.confirmation
    try:
        return await confirm_deletion(session, context=current, request_id=str(payload.request_id))
    except AuthenticationError as exc:
        raise _auth_error(exc) from exc


@account_router.get("/deletion-status", response_model=DeletionResponse)
async def deletion_status(session: SessionDependency, current: CurrentUser) -> DeletionResponse:
    from sqlalchemy import select

    from app.auth.models import AccountDeletionRequest

    request = (
        await session.execute(
            select(AccountDeletionRequest)
            .where(AccountDeletionRequest.user_id == current.user.id)
            .order_by(AccountDeletionRequest.requested_at.desc())
            .limit(1)
        )
    ).scalar_one_or_none()
    if request is None:
        raise HTTPException(
            status_code=404,
            detail={"code": "DELETION_NOT_FOUND", "message": "Deletion request not found"},
        )
    return DeletionResponse(
        request_id=request.id,
        status=request.status,
        local_data_action=request.local_data_action,
    )
