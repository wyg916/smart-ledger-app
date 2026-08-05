from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.ai.errors import AiError
from app.ai.routes import router as ai_router
from app.analytics.routes import internal_router, page_router
from app.analytics.routes import router as analytics_router
from app.auth.routes import account_router
from app.auth.routes import router as auth_router
from app.config import get_settings
from app.database import dispose_engine
from app.public_routes import router as public_router
from app.routes import router


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    errors = get_settings().production_configuration_errors()
    if errors:
        raise RuntimeError(f"Production configuration invalid: {','.join(errors)}")
    yield
    await dispose_engine()


settings = get_settings()
app = FastAPI(title=settings.app_name, version=settings.app_version, lifespan=lifespan)
app.include_router(router)
app.include_router(ai_router)
app.include_router(analytics_router)
app.include_router(internal_router)
app.include_router(page_router)
app.include_router(auth_router)
app.include_router(account_router)
app.include_router(public_router)


@app.middleware("http")
async def request_context(request: Request, call_next: Any) -> Any:
    candidate = request.headers.get("x-request-id", "")
    request_id = (
        candidate
        if candidate.isascii() and candidate.replace("-", "").isalnum() and len(candidate) <= 64
        else str(uuid4())
    )
    request.state.request_id = request_id
    response = await call_next(request)
    response.headers["x-request-id"] = request_id
    return response


@app.middleware("http")
async def limit_ai_request_size(request: Request, call_next: Any) -> Any:
    limited_path = request.url.path.startswith(("/api/v1/ai/", "/api/v1/auth/", "/api/v1/account/"))
    if limited_path and request.method == "POST":
        content_length = request.headers.get("content-length")
        limit = 8 * 1024 * 1024 + 65_536 if request.url.path.endswith("analyze-image") else 32_768
        try:
            too_large = content_length is not None and int(content_length) > limit
        except ValueError:
            too_large = True
        if too_large:
            return JSONResponse(
                status_code=413,
                content={
                    "error": {
                        "code": "AI_REQUEST_TOO_LARGE",
                        "message": "AI request body is too large",
                    }
                },
            )
    return await call_next(request)


@app.exception_handler(AiError)
async def ai_exception_handler(_: Request, exc: AiError) -> JSONResponse:
    details = exc.details or {}
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": exc.code, "message": exc.message}, **details},
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(_: Request, exc: HTTPException) -> JSONResponse:
    detail = exc.detail if isinstance(exc.detail, dict) else {"message": str(exc.detail)}
    extras = {key: value for key, value in detail.items() if key not in {"code", "message"}}
    payload = {
        "error": {
            "code": detail.get("code", "http_error"),
            "message": detail.get("message", "Request failed"),
        },
        **extras,
    }
    return JSONResponse(status_code=exc.status_code, content=payload, headers=exc.headers)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(_: Request, exc: RequestValidationError) -> JSONResponse:
    details = [
        {
            "type": error.get("type", "value_error"),
            "loc": list(error.get("loc", ())),
            "msg": error.get("msg", "Invalid value"),
        }
        for error in exc.errors()
    ]
    payload: dict[str, Any] = {
        "error": {
            "code": "validation_error",
            "message": "Request validation failed",
        },
        "details": details,
    }
    return JSONResponse(status_code=422, content=payload)
