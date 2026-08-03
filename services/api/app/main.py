from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.ai.errors import AiError
from app.ai.routes import router as ai_router
from app.config import get_settings
from app.database import dispose_engine
from app.routes import router


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    yield
    await dispose_engine()


settings = get_settings()
app = FastAPI(title=settings.app_name, version=settings.app_version, lifespan=lifespan)
app.include_router(router)
app.include_router(ai_router)


@app.middleware("http")
async def limit_ai_request_size(request: Request, call_next: Any) -> Any:
    if request.url.path.startswith("/api/v1/ai/") and request.method == "POST":
        content_length = request.headers.get("content-length")
        if content_length is not None and int(content_length) > 32_768:
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
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": exc.code, "message": exc.message}},
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(_: Request, exc: HTTPException) -> JSONResponse:
    detail = exc.detail if isinstance(exc.detail, dict) else {"message": str(exc.detail)}
    payload = {
        "error": {
            "code": detail.get("code", "http_error"),
            "message": detail.get("message", "Request failed"),
        }
    }
    return JSONResponse(status_code=exc.status_code, content=payload, headers=exc.headers)


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(_: Request, exc: RequestValidationError) -> JSONResponse:
    payload: dict[str, Any] = {
        "error": {
            "code": "validation_error",
            "message": "Request validation failed",
        },
        "details": exc.errors(),
    }
    return JSONResponse(status_code=422, content=payload)
