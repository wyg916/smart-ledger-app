from functools import lru_cache

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


@lru_cache
def get_settings() -> Settings:
    return Settings()
