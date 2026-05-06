from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    service_name: str = "idp-platform"
    environment: Literal["dev", "staging", "prod"] = "dev"
    log_level: str = "INFO"
    json_logs: bool = True
    aws_region: str = "us-east-2"

    @property
    def docs_enabled(self) -> bool:
        return self.environment != "prod"


settings = Settings()
