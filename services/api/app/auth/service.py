import hmac
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from uuid import uuid4

from sqlalchemy import delete, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.analytics.models import AnalyticsEvent, AnalyticsInstallation, AnalyticsSession, utc_now
from app.auth.models import (
    AccountDeletionRequest,
    AuthIdentity,
    AuthLoginAudit,
    AuthReplayToken,
    RefreshToken,
    ReviewAccount,
    User,
    UserAuthSession,
    UserInstallation,
)
from app.auth.schemas import AuthResponse, DeletionResponse, TokenPair, UserView
from app.auth.tokens import (
    AccessTokenError,
    create_access_token,
    decode_access_token,
    new_password_hash,
    opaque_token,
    password_hash,
    private_hash,
    token_hash,
)
from app.config import Settings


class AuthenticationError(ValueError):
    pass


class IdentityConflictError(ValueError):
    pass


class ReplayError(ValueError):
    pass


class RateLimitError(ValueError):
    pass


@dataclass(frozen=True)
class AuthContext:
    user: User
    auth_session: UserAuthSession


def _aware(value: datetime) -> datetime:
    return value.replace(tzinfo=UTC) if value.tzinfo is None else value.astimezone(UTC)


async def request_fingerprint(client_host: str | None, settings: Settings) -> str:
    return private_hash(client_host or "unknown", settings.auth_identity_pepper)


async def enforce_rate_limit(
    session: AsyncSession,
    *,
    provider: str,
    fingerprint: str,
    limit: int,
    window_seconds: int = 60,
) -> None:
    since = utc_now() - timedelta(seconds=window_seconds)
    count = await session.scalar(
        select(func.count(AuthLoginAudit.id)).where(
            AuthLoginAudit.provider == provider,
            AuthLoginAudit.request_fingerprint == fingerprint,
            AuthLoginAudit.created_at >= since,
        )
    )
    if int(count or 0) >= limit:
        raise RateLimitError("authentication rate limit exceeded")


async def record_login_audit(
    session: AsyncSession,
    *,
    provider: str,
    outcome: str,
    request_id: str,
    fingerprint: str,
    user_id: str | None = None,
) -> None:
    session.add(
        AuthLoginAudit(
            id=str(uuid4()),
            user_id=user_id,
            provider=provider,
            outcome=outcome,
            request_id=request_id,
            request_fingerprint=fingerprint,
            created_at=utc_now(),
        )
    )
    await session.commit()


async def issue_wechat_state(session: AsyncSession, settings: Settings) -> tuple[str, int]:
    state = opaque_token()
    expires_in = 300
    session.add(
        AuthReplayToken(
            id=str(uuid4()),
            purpose="wechat_state",
            token_hash=private_hash(state, settings.auth_identity_pepper),
            expires_at=utc_now() + timedelta(seconds=expires_in),
            created_at=utc_now(),
        )
    )
    await session.commit()
    return state, expires_in


async def consume_wechat_state(session: AsyncSession, state: str, settings: Settings) -> None:
    digest = private_hash(state, settings.auth_identity_pepper)
    row = (
        await session.execute(
            select(AuthReplayToken).where(
                AuthReplayToken.purpose == "wechat_state",
                AuthReplayToken.token_hash == digest,
            )
        )
    ).scalar_one_or_none()
    now = utc_now()
    if row is None or row.used_at is not None or _aware(row.expires_at) <= now:
        raise ReplayError("wechat state invalid or already used")
    row.used_at = now
    await session.commit()


async def consume_provider_token(
    session: AsyncSession, *, purpose: str, value: str, settings: Settings
) -> None:
    digest = private_hash(value, settings.auth_identity_pepper)
    exists = (
        await session.execute(
            select(AuthReplayToken.id).where(
                AuthReplayToken.purpose == purpose,
                AuthReplayToken.token_hash == digest,
            )
        )
    ).scalar_one_or_none()
    if exists is not None:
        raise ReplayError("provider token already used")
    now = utc_now()
    session.add(
        AuthReplayToken(
            id=str(uuid4()),
            purpose=purpose,
            token_hash=digest,
            expires_at=now + timedelta(minutes=10),
            used_at=now,
            created_at=now,
        )
    )
    await session.commit()


def phone_subject(normalized_phone: str, settings: Settings) -> tuple[str, str]:
    digest = private_hash(f"phone:{normalized_phone}", settings.auth_identity_pepper)
    hint = f"+86*******{normalized_phone[-4:]}"
    return digest, hint


def wechat_subject(subject: str, settings: Settings) -> str:
    return private_hash(f"wechat:{subject}", settings.auth_identity_pepper)


async def find_or_create_identity_user(
    session: AsyncSession,
    *,
    provider: str,
    subject_hash: str,
    display_hint: str | None,
    phone_hash: str | None = None,
    bind_user_id: str | None = None,
) -> User:
    identity = (
        await session.execute(
            select(AuthIdentity).where(
                AuthIdentity.provider == provider,
                AuthIdentity.provider_subject_hash == subject_hash,
            )
        )
    ).scalar_one_or_none()
    if identity is not None:
        if bind_user_id is not None and identity.user_id != bind_user_id:
            raise IdentityConflictError("identity belongs to another user")
        user = await session.get(User, identity.user_id)
        if user is None or user.status != "active":
            raise AuthenticationError("user is unavailable")
        return user

    if phone_hash is not None:
        phone_owner = (
            await session.execute(select(AuthIdentity).where(AuthIdentity.phone_hash == phone_hash))
        ).scalar_one_or_none()
        if phone_owner is not None and phone_owner.user_id != bind_user_id:
            raise IdentityConflictError("phone identity belongs to another user")

    now = utc_now()
    user = await session.get(User, bind_user_id) if bind_user_id is not None else None
    if bind_user_id is not None and (user is None or user.status != "active"):
        raise AuthenticationError("user is unavailable")
    if user is None:
        user = User(id=str(uuid4()), status="active", created_at=now, updated_at=now)
        session.add(user)
        await session.flush()
    session.add(
        AuthIdentity(
            id=str(uuid4()),
            user_id=user.id,
            provider=provider,
            provider_subject_hash=subject_hash,
            phone_hash=phone_hash,
            display_hint=display_hint,
            created_at=now,
            updated_at=now,
        )
    )
    user.updated_at = now
    await session.commit()
    return user


async def _providers(session: AsyncSession, user_id: str) -> list[str]:
    values = (
        await session.execute(
            select(AuthIdentity.provider)
            .where(AuthIdentity.user_id == user_id)
            .order_by(AuthIdentity.provider)
        )
    ).scalars()
    return list(values)


async def user_view(session: AsyncSession, user: User) -> UserView:
    return UserView(
        user_id=user.id, status=user.status, providers=await _providers(session, user.id)
    )


async def _new_token_pair(
    session: AsyncSession,
    auth_session: UserAuthSession,
    settings: Settings,
    *,
    replaced: RefreshToken | None = None,
) -> TokenPair:
    access_token, access_expires = create_access_token(
        user_id=auth_session.user_id,
        session_id=auth_session.id,
        secret=settings.auth_jwt_secret,
        lifetime_minutes=settings.auth_access_token_minutes,
    )
    refresh_value = opaque_token()
    refresh_row = RefreshToken(
        id=str(uuid4()),
        session_id=auth_session.id,
        token_hash=token_hash(refresh_value),
        created_at=utc_now(),
        expires_at=auth_session.expires_at,
    )
    session.add(refresh_row)
    if replaced is not None:
        replaced.used_at = utc_now()
        replaced.replaced_by_token_id = refresh_row.id
    await session.commit()
    return TokenPair(
        access_token=access_token,
        refresh_token=refresh_value,
        access_expires_at=access_expires,
        refresh_expires_at=_aware(auth_session.expires_at),
    )


async def create_auth_session(
    session: AsyncSession,
    *,
    user: User,
    installation_id: str,
    settings: Settings,
) -> AuthResponse:
    now = utc_now()
    auth_session = UserAuthSession(
        id=str(uuid4()),
        user_id=user.id,
        installation_id=installation_id,
        created_at=now,
        last_seen_at=now,
        expires_at=now + timedelta(days=settings.auth_refresh_token_days),
    )
    session.add(auth_session)
    installation = (
        await session.execute(
            select(UserInstallation).where(
                UserInstallation.user_id == user.id,
                UserInstallation.installation_id == installation_id,
            )
        )
    ).scalar_one_or_none()
    if installation is None:
        session.add(
            UserInstallation(
                id=str(uuid4()),
                user_id=user.id,
                installation_id=installation_id,
                created_at=now,
                last_seen_at=now,
            )
        )
    else:
        installation.last_seen_at = now
    await session.flush()
    tokens = await _new_token_pair(session, auth_session, settings)
    return AuthResponse(
        user=await user_view(session, user),
        tokens=tokens,
        session_id=auth_session.id,
    )


async def authenticate_access_token(
    session: AsyncSession, authorization: str | None, settings: Settings
) -> AuthContext:
    if authorization is None or not authorization.startswith("Bearer "):
        raise AuthenticationError("access token required")
    raw = authorization.removeprefix("Bearer ").strip()
    try:
        claims = decode_access_token(raw, settings.auth_jwt_secret)
    except AccessTokenError as exc:
        raise AuthenticationError("access token invalid") from exc
    auth_session = await session.get(UserAuthSession, str(claims["sid"]))
    now = utc_now()
    if (
        auth_session is None
        or auth_session.user_id != claims["sub"]
        or auth_session.revoked_at is not None
        or _aware(auth_session.expires_at) <= now
    ):
        raise AuthenticationError("session invalid")
    user = await session.get(User, auth_session.user_id)
    if user is None or user.status not in {"active", "deletion_pending"}:
        raise AuthenticationError("user unavailable")
    auth_session.last_seen_at = now
    return AuthContext(user=user, auth_session=auth_session)


async def refresh_auth_session(
    session: AsyncSession, raw_refresh_token: str, settings: Settings
) -> AuthResponse:
    row = (
        await session.execute(
            select(RefreshToken).where(RefreshToken.token_hash == token_hash(raw_refresh_token))
        )
    ).scalar_one_or_none()
    now = utc_now()
    if row is None or row.revoked_at is not None or _aware(row.expires_at) <= now:
        raise AuthenticationError("refresh token invalid")
    auth_session = await session.get(UserAuthSession, row.session_id)
    if auth_session is None or auth_session.revoked_at is not None:
        raise AuthenticationError("session invalid")
    if row.used_at is not None:
        auth_session.revoked_at = now
        await session.execute(
            update(RefreshToken)
            .where(RefreshToken.session_id == auth_session.id)
            .values(revoked_at=now)
        )
        await session.commit()
        raise ReplayError("refresh token replay detected")
    user = await session.get(User, auth_session.user_id)
    if user is None or user.status != "active":
        raise AuthenticationError("user unavailable")
    tokens = await _new_token_pair(session, auth_session, settings, replaced=row)
    return AuthResponse(
        user=await user_view(session, user),
        tokens=tokens,
        session_id=auth_session.id,
    )


async def revoke_session(
    session: AsyncSession, context: AuthContext, raw_refresh_token: str | None = None
) -> None:
    now = utc_now()
    context.auth_session.revoked_at = now
    await session.execute(
        update(RefreshToken)
        .where(RefreshToken.session_id == context.auth_session.id)
        .values(revoked_at=now)
    )
    if raw_refresh_token is not None:
        await session.execute(
            update(RefreshToken)
            .where(RefreshToken.token_hash == token_hash(raw_refresh_token))
            .values(revoked_at=now)
        )
    await session.commit()


async def review_login(
    session: AsyncSession,
    *,
    username: str,
    password: str,
    installation_id: str,
    settings: Settings,
) -> AuthResponse:
    username_digest = private_hash(f"review:{username.casefold()}", settings.auth_identity_pepper)
    account = (
        await session.execute(
            select(ReviewAccount).where(ReviewAccount.username_hash == username_digest)
        )
    ).scalar_one_or_none()
    if (
        account is None
        or not account.enabled
        or not hmac.compare_digest(
            password_hash(password, account.password_salt), account.password_hash
        )
    ):
        raise AuthenticationError("review credentials invalid")
    user = await session.get(User, account.user_id)
    if user is None or user.status != "active":
        raise AuthenticationError("review user unavailable")
    return await create_auth_session(
        session, user=user, installation_id=installation_id, settings=settings
    )


async def provision_review_account(
    session: AsyncSession, *, username: str, password: str, settings: Settings
) -> str:
    username_digest = private_hash(f"review:{username.casefold()}", settings.auth_identity_pepper)
    existing = (
        await session.execute(
            select(ReviewAccount).where(ReviewAccount.username_hash == username_digest)
        )
    ).scalar_one_or_none()
    now = utc_now()
    salt, digest = new_password_hash(password)
    if existing is not None:
        existing.password_salt = salt
        existing.password_hash = digest
        existing.enabled = True
        existing.rotated_at = now
        await session.commit()
        return existing.user_id
    user = User(id=str(uuid4()), status="active", created_at=now, updated_at=now)
    session.add(user)
    await session.flush()
    session.add(
        ReviewAccount(
            id=str(uuid4()),
            user_id=user.id,
            username_hash=username_digest,
            password_salt=salt,
            password_hash=digest,
            enabled=True,
            created_at=now,
            rotated_at=now,
        )
    )
    session.add(
        AuthIdentity(
            id=str(uuid4()),
            user_id=user.id,
            provider="play_review",
            provider_subject_hash=username_digest,
            created_at=now,
            updated_at=now,
        )
    )
    await session.commit()
    return user.id


async def unbind_identity(session: AsyncSession, context: AuthContext, provider: str) -> list[str]:
    identities = (
        (await session.execute(select(AuthIdentity).where(AuthIdentity.user_id == context.user.id)))
        .scalars()
        .all()
    )
    target = [item for item in identities if item.provider == provider]
    if not target:
        raise AuthenticationError("identity not found")
    if len(identities) <= len(target):
        raise AuthenticationError("cannot remove last login identity")
    for item in target:
        await session.delete(item)
    await session.commit()
    return await _providers(session, context.user.id)


async def create_deletion_request(
    session: AsyncSession,
    *,
    context: AuthContext,
    idempotency_key: str,
    local_data_action: str,
    settings: Settings,
) -> DeletionResponse:
    digest = private_hash(
        f"deletion:{context.user.id}:{idempotency_key}", settings.auth_identity_pepper
    )
    existing = (
        await session.execute(
            select(AccountDeletionRequest).where(
                AccountDeletionRequest.idempotency_key_hash == digest
            )
        )
    ).scalar_one_or_none()
    if existing is None:
        existing = AccountDeletionRequest(
            id=str(uuid4()),
            user_id=context.user.id,
            idempotency_key_hash=digest,
            status="requested",
            local_data_action=local_data_action,
            requested_at=utc_now(),
        )
        session.add(existing)
        context.user.status = "deletion_pending"
        context.user.updated_at = utc_now()
        await session.commit()
    return DeletionResponse(
        request_id=existing.id,
        status=existing.status,
        local_data_action=existing.local_data_action,
    )


async def confirm_deletion(
    session: AsyncSession, *, context: AuthContext, request_id: str
) -> DeletionResponse:
    request = await session.get(AccountDeletionRequest, request_id)
    if request is None or request.user_id != context.user.id:
        raise AuthenticationError("deletion request not found")
    if request.status == "completed":
        return DeletionResponse(
            request_id=request.id,
            status="completed",
            local_data_action=request.local_data_action,
        )
    now = utc_now()
    await session.execute(delete(AuthIdentity).where(AuthIdentity.user_id == context.user.id))
    await session.execute(delete(ReviewAccount).where(ReviewAccount.user_id == context.user.id))
    await session.execute(
        delete(UserInstallation).where(UserInstallation.user_id == context.user.id)
    )
    await session.execute(
        update(UserAuthSession)
        .where(UserAuthSession.user_id == context.user.id)
        .values(revoked_at=now)
    )
    auth_session_ids = select(UserAuthSession.id).where(UserAuthSession.user_id == context.user.id)
    await session.execute(
        update(RefreshToken)
        .where(RefreshToken.session_id.in_(auth_session_ids))
        .values(revoked_at=now)
    )
    await session.execute(
        update(AnalyticsInstallation)
        .where(AnalyticsInstallation.user_id == context.user.id)
        .values(user_id=None)
    )
    await session.execute(
        update(AnalyticsSession)
        .where(AnalyticsSession.user_id == context.user.id)
        .values(user_id=None)
    )
    await session.execute(
        update(AnalyticsEvent).where(AnalyticsEvent.user_id == context.user.id).values(user_id=None)
    )
    context.user.status = "deleted"
    context.user.deleted_at = now
    context.user.updated_at = now
    request.status = "completed"
    request.confirmed_at = now
    request.completed_at = now
    await session.commit()
    return DeletionResponse(
        request_id=request.id,
        status="completed",
        local_data_action=request.local_data_action,
    )
