import httpx

from app.auth.providers.base import AuthProviderError, VerifiedWechat


class HttpWechatProvider:
    def __init__(self, app_id: str, app_secret: str, api_base_url: str) -> None:
        self._app_id = app_id
        self._app_secret = app_secret
        self._api_base_url = api_base_url.rstrip("/")

    async def exchange(self, code: str) -> VerifiedWechat:
        try:
            async with httpx.AsyncClient(timeout=httpx.Timeout(8.0, connect=4.0)) as client:
                response = await client.get(
                    f"{self._api_base_url}/sns/oauth2/access_token",
                    params={
                        "appid": self._app_id,
                        "secret": self._app_secret,
                        "code": code,
                        "grant_type": "authorization_code",
                    },
                )
                response.raise_for_status()
                body = response.json()
        except (httpx.HTTPError, ValueError) as exc:
            raise AuthProviderError("wechat provider unavailable") from exc
        if not isinstance(body, dict) or "errcode" in body:
            raise AuthProviderError("wechat verification failed")
        union_id = body.get("unionid")
        open_id = body.get("openid")
        if isinstance(union_id, str) and union_id:
            return VerifiedWechat(subject=f"unionid:{union_id}")
        if isinstance(open_id, str) and open_id:
            return VerifiedWechat(subject=f"openid:{self._app_id}:{open_id}")
        raise AuthProviderError("wechat provider response invalid")
