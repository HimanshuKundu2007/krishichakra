from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional

BASE_DIR = Path(__file__).resolve().parent.parent

class Settings(BaseSettings):
    app_name: str = "KrishiChakra API"
    database_url: str = f"sqlite:///{BASE_DIR / 'krishichakra.db'}"
    api_prefix: str = "/api"
    cors_origins: str = "*"

    gov_price_api_url: Optional[str] = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
    gov_price_api_key: Optional[str] = None
    gov_price_api_key_header: str = "api-key"
    gov_price_auth_mode: str = "query"
    gov_price_source_name: str = "Government Market Data (AGMARKNET / data.gov.in)"
    gov_price_http_method: str = "GET"
    gov_price_request_params_json: str = '{"format": "json", "limit": "200"}'
    gov_price_records_path: str = "records"

    price_sync_hour: int = 6
    price_sync_minute: int = 30
    price_sync_timezone: str = "Asia/Kolkata"

    model_config = SettingsConfigDict(
        env_file=[str(BASE_DIR / ".env"), ".env"],
        extra="ignore"
    )

settings = Settings()

