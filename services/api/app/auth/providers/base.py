from dataclasses import dataclass
from typing import Protocol


class AuthProviderError(RuntimeError):
    pass


@dataclass(frozen=True)
class VerifiedPhone:
    normalized_phone: str


@dataclass(frozen=True)
class VerifiedWechat:
    subject: str


class PhoneOneClickProvider(Protocol):
    async def verify(self, token: str, carrier: str | None) -> VerifiedPhone: ...


class WechatProvider(Protocol):
    async def exchange(self, code: str) -> VerifiedWechat: ...
