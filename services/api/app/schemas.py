from pydantic import BaseModel


class ServiceStatus(BaseModel):
    status: str
    service: str
    version: str
    environment: str


class VersionResponse(BaseModel):
    service: str
    version: str
    environment: str


class ErrorDetail(BaseModel):
    code: str
    message: str


class ErrorResponse(BaseModel):
    error: ErrorDetail
