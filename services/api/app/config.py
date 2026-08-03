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


@lru_cache
def get_settings() -> Settings:
    return Settings()
