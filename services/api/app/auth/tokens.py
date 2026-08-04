import base64
import hashlib
import hmac
import json
import secrets
from datetime import UTC, datetime, timedelta
from typing import Any, cast
from uuid import uuid4


class AccessTokenError(ValueError):
    pass


def opaque_token() -> str:
    return secrets.token_urlsafe(48)


def token_hash(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def private_hash(value: str, pepper: str) -> str:
    return hmac.new(pepper.encode("utf-8"), value.encode("utf-8"), hashlib.sha256).hexdigest()


def _b64encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def _b64decode(value: str) -> bytes:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def create_access_token(
    *, user_id: str, session_id: str, secret: str, lifetime_minutes: int
) -> tuple[str, datetime]:
    now = datetime.now(UTC)
    expires = now + timedelta(minutes=lifetime_minutes)
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {
        "sub": user_id,
        "sid": session_id,
        "jti": str(uuid4()),
        "type": "access",
        "iat": int(now.timestamp()),
        "exp": int(expires.timestamp()),
    }
    encoded_header = _b64encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
    encoded_payload = _b64encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signing_input = f"{encoded_header}.{encoded_payload}"
    signature = hmac.new(
        secret.encode("utf-8"), signing_input.encode("ascii"), hashlib.sha256
    ).digest()
    return f"{signing_input}.{_b64encode(signature)}", expires


def decode_access_token(token: str, secret: str) -> dict[str, Any]:
    try:
        encoded_header, encoded_payload, encoded_signature = token.split(".")
        signing_input = f"{encoded_header}.{encoded_payload}"
        expected = hmac.new(
            secret.encode("utf-8"), signing_input.encode("ascii"), hashlib.sha256
        ).digest()
        supplied = _b64decode(encoded_signature)
        if not hmac.compare_digest(expected, supplied):
            raise AccessTokenError("signature invalid")
        header = json.loads(_b64decode(encoded_header))
        payload = cast(dict[str, Any], json.loads(_b64decode(encoded_payload)))
    except (ValueError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise AccessTokenError("token malformed") from exc
    if header != {"alg": "HS256", "typ": "JWT"}:
        raise AccessTokenError("header invalid")
    if payload.get("type") != "access" or not payload.get("sub") or not payload.get("sid"):
        raise AccessTokenError("claims invalid")
    if not isinstance(payload.get("exp"), int) or payload["exp"] <= int(
        datetime.now(UTC).timestamp()
    ):
        raise AccessTokenError("token expired")
    return payload


def password_hash(password: str, salt_hex: str) -> str:
    return hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), bytes.fromhex(salt_hex), 310_000
    ).hex()


def new_password_hash(password: str) -> tuple[str, str]:
    salt = secrets.token_hex(32)
    return salt, password_hash(password, salt)
