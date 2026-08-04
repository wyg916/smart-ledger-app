from app.auth.providers.base import (
    AuthProviderError,
    VerifiedPhone,
    VerifiedWechat,
)


class FakePhoneOneClickProvider:
    async def verify(self, token: str, carrier: str | None) -> VerifiedPhone:
        del carrier
        if token != "synthetic-phone-token":
            raise AuthProviderError("phone verification failed")
        return VerifiedPhone(normalized_phone="+8610000000000")


class FakeWechatProvider:
    async def exchange(self, code: str) -> VerifiedWechat:
        if code != "synthetic-wechat-code":
            raise AuthProviderError("wechat verification failed")
        return VerifiedWechat(subject="synthetic-wechat-subject")
