from typing import Annotated

from fastapi import Depends, Header, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.service import AuthContext, AuthenticationError, authenticate_access_token
from app.config import Settings, get_settings
from app.database import get_session


async def require_current_user(
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
    authorization: Annotated[str | None, Header()] = None,
) -> AuthContext:
    try:
        return await authenticate_access_token(session, authorization, settings)
    except AuthenticationError as exc:
        raise HTTPException(
            status_code=401,
            detail={"code": "AUTH_UNAUTHORIZED", "message": "Authentication required"},
        ) from exc


async def optional_current_user(
    session: Annotated[AsyncSession, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
    authorization: Annotated[str | None, Header()] = None,
) -> AuthContext | None:
    if authorization is None:
        return None
    return await require_current_user(session, settings, authorization)


CurrentUser = Annotated[AuthContext, Depends(require_current_user)]
OptionalCurrentUser = Annotated[AuthContext | None, Depends(optional_current_user)]
