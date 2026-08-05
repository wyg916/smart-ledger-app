from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="SMART_LEDGER_",
        extra="ignore",
    )

    app_name: str = "smart-ledger-api"
    app_version: str = "0.1.0"
    environment: str = "development"
    database_url: str = (
        "postgresql+asyncpg://ledger_dev:ledger_dev@127.0.0.1:54329/smart_ledger_dev"
    )
    moonshot_api_key: str = Field(default="", validation_alias="MOONSHOT_API_KEY")
    kimi_base_url: str = Field(
        default="https://api.moonshot.cn/v1", validation_alias="KIMI_BASE_URL"
    )
    kimi_fast_model: str = Field(default="kimi-k2.6", validation_alias="KIMI_FAST_MODEL")
    kimi_reasoning_model: str = Field(default="kimi-k2.6", validation_alias="KIMI_REASONING_MODEL")
    kimi_ai_enabled: bool = Field(default=False, validation_alias="KIMI_AI_ENABLED")
    kimi_provider: str = Field(default="kimi", validation_alias="KIMI_PROVIDER")
    kimi_live_test: bool = Field(default=False, validation_alias="KIMI_LIVE_TEST")
    kimi_chat_model: str = Field(default="kimi-k2.6", validation_alias="KIMI_CHAT_MODEL")
    kimi_vision_model: str = Field(default="kimi-k2.6", validation_alias="KIMI_VISION_MODEL")
    telemetry_enabled: bool = Field(default=True, validation_alias="TELEMETRY_ENABLED")
    internal_metrics_token: str = Field(default="", validation_alias="INTERNAL_METRICS_TOKEN")
    analytics_raw_retention_days: int = Field(
        default=90, ge=30, le=730, validation_alias="ANALYTICS_RAW_RETENTION_DAYS"
    )
    analytics_aggregate_retention_days: int = Field(
        default=400, ge=90, le=3650, validation_alias="ANALYTICS_AGGREGATE_RETENTION_DAYS"
    )
    ai_free_daily_limit: int = Field(
        default=2, ge=1, le=100, validation_alias="AI_FREE_DAILY_LIMIT"
    )
    ai_free_weekly_limit: int = Field(
        default=10, ge=1, le=500, validation_alias="AI_FREE_WEEKLY_LIMIT"
    )
    ai_review_daily_limit: int = Field(
        default=50, ge=1, le=1000, validation_alias="AI_REVIEW_DAILY_LIMIT"
    )
    ai_review_weekly_limit: int = Field(
        default=250, ge=1, le=5000, validation_alias="AI_REVIEW_WEEKLY_LIMIT"
    )
    ai_internal_test_daily_limit: int = Field(
        default=100, ge=1, le=5000, validation_alias="AI_INTERNAL_TEST_DAILY_LIMIT"
    )
    ai_internal_test_weekly_limit: int = Field(
        default=500, ge=1, le=20000, validation_alias="AI_INTERNAL_TEST_WEEKLY_LIMIT"
    )
    ai_reservation_ttl_seconds: int = Field(
        default=600, ge=60, le=3600, validation_alias="AI_RESERVATION_TTL_SECONDS"
    )
    ai_model_pricing_json: str = Field(default="{}", validation_alias="AI_MODEL_PRICING_JSON")
    user_timezone_change_cooldown_hours: int = Field(
        default=24, ge=1, le=168, validation_alias="USER_TIMEZONE_CHANGE_COOLDOWN_HOURS"
    )
    auth_jwt_secret: str = Field(default="development-only", validation_alias="AUTH_JWT_SECRET")
    auth_identity_pepper: str = Field(
        default="development-only", validation_alias="AUTH_IDENTITY_PEPPER"
    )
    auth_access_token_minutes: int = Field(
        default=15, ge=5, le=60, validation_alias="AUTH_ACCESS_TOKEN_MINUTES"
    )
    auth_refresh_token_days: int = Field(
        default=30, ge=1, le=90, validation_alias="AUTH_REFRESH_TOKEN_DAYS"
    )
    phone_auth_provider: str = Field(default="fake", validation_alias="PHONE_AUTH_PROVIDER")
    tencent_phone_sdk_app_id: str = Field(default="", validation_alias="TENCENT_PHONE_SDK_APP_ID")
    tencent_phone_app_key: str = Field(default="", validation_alias="TENCENT_PHONE_APP_KEY")
    tencent_phone_validate_url: str = Field(
        default="https://yun.tim.qq.com/v5/rapidauth/validate",
        validation_alias="TENCENT_PHONE_VALIDATE_URL",
    )
    wechat_auth_provider: str = Field(default="fake", validation_alias="WECHAT_AUTH_PROVIDER")
    wechat_app_id: str = Field(default="", validation_alias="WECHAT_APP_ID")
    wechat_app_secret: str = Field(default="", validation_alias="WECHAT_APP_SECRET")
    wechat_api_base_url: str = Field(
        default="https://api.weixin.qq.com", validation_alias="WECHAT_API_BASE_URL"
    )
    review_login_enabled: bool = Field(default=False, validation_alias="REVIEW_LOGIN_ENABLED")
    public_base_url: str = Field(
        default="https://www.znjz.site", validation_alias="PUBLIC_BASE_URL"
    )

    def production_configuration_errors(self) -> list[str]:
        if self.environment != "production":
            return []
        errors: list[str] = []
        if len(self.auth_jwt_secret) < 32 or self.auth_jwt_secret == "development-only":
            errors.append("AUTH_JWT_SECRET")
        if len(self.auth_identity_pepper) < 32 or self.auth_identity_pepper == "development-only":
            errors.append("AUTH_IDENTITY_PEPPER")
        if self.phone_auth_provider != "tencent":
            errors.append("PHONE_AUTH_PROVIDER")
        if not self.tencent_phone_sdk_app_id or not self.tencent_phone_app_key:
            errors.append("TENCENT_PHONE_CONFIGURATION")
        if self.wechat_auth_provider != "wechat":
            errors.append("WECHAT_AUTH_PROVIDER")
        if not self.wechat_app_id or not self.wechat_app_secret:
            errors.append("WECHAT_CONFIGURATION")
        if self.kimi_provider == "fake":
            errors.append("KIMI_PROVIDER")
        if self.kimi_ai_enabled and not self.moonshot_api_key:
            errors.append("MOONSHOT_API_KEY")
        if not self.internal_metrics_token:
            errors.append("INTERNAL_METRICS_TOKEN")
        database = self.database_url.lower()
        if (
            not database.startswith("postgresql+asyncpg://")
            or "localhost" in database
            or "127.0.0.1" in database
            or "ledger_dev" in database
            or "smart_ledger_dev" in database
        ):
            errors.append("DATABASE_URL")
        if not self.public_base_url.startswith("https://"):
            errors.append("PUBLIC_BASE_URL")
        return errors


@lru_cache
def get_settings() -> Settings:
    return Settings()
