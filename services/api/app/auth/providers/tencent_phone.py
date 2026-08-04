import hashlib
import secrets
import time
from typing import Any

import httpx

from app.auth.providers.base import AuthProviderError, VerifiedPhone


class TencentPhoneOneClickProvider:
    def __init__(self, sdk_app_id: str, app_key: str, validate_url: str) -> None:
        self._sdk_app_id = sdk_app_id
        self._app_key = app_key
        self._validate_url = validate_url

    async def verify(self, token: str, carrier: str | None) -> VerifiedPhone:
        random_value = "".join(secrets.choice("0123456789") for _ in range(10))
        timestamp = str(int(time.time()))
        signature_input = f"appkey={self._app_key}&random={random_value}&time={timestamp}"
        signature = hashlib.sha256(signature_input.encode("utf-8")).hexdigest()
        payload: dict[str, Any] = {"sig": signature, "time": timestamp, "token": token}
        if carrier is not None:
            payload["carrier"] = carrier
        try:
            async with httpx.AsyncClient(timeout=httpx.Timeout(8.0, connect=4.0)) as client:
                response = await client.post(
                    self._validate_url,
                    params={"sdkappid": self._sdk_app_id, "random": random_value},
                    json=payload,
                )
                response.raise_for_status()
                body = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            raise AuthProviderError("phone provider unavailable") from exc
        if not isinstance(body, dict) or body.get("result") != 0:
            raise AuthProviderError("phone verification failed")
        mobile = body.get("mobile")
        if not isinstance(mobile, str):
            raise AuthProviderError("phone provider response invalid")
        return VerifiedPhone(normalized_phone=_normalize_phone(mobile))


def _normalize_phone(value: str) -> str:
    compact = "".join(character for character in value if character.isdigit() or character == "+")
    if compact.startswith("+86"):
        national = compact[3:]
    elif compact.startswith("86") and len(compact) == 13:
        national = compact[2:]
    else:
        national = compact
    if len(national) != 11 or not national.startswith("1") or not national.isdigit():
        raise AuthProviderError("phone provider response invalid")
    return f"+86{national}"
