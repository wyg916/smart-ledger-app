from dataclasses import dataclass


@dataclass(slots=True)
class AiError(Exception):
    code: str
    message: str
    status_code: int
    retryable: bool = False


def map_upstream_status(status_code: int) -> AiError:
    if status_code in {401, 403}:
        return AiError("AI_UPSTREAM_AUTH_ERROR", "AI provider authentication failed", 502)
    if status_code == 429:
        return AiError("AI_RATE_LIMITED", "AI provider is rate limited", 429, True)
    if status_code in {502, 503, 504}:
        return AiError("AI_UPSTREAM_ERROR", "AI provider is unavailable", 503, True)
    return AiError("AI_UPSTREAM_ERROR", "AI provider request failed", 502)
