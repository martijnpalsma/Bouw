"""
Configuratiebeheer voor de Building Data Agent
"""

import os
from typing import Optional
from pydantic_settings import BaseSettings
from pydantic import Field


class Config(BaseSettings):
    """Configuratie voor de Building Data Agent"""
    
    # API Configuration
    api_host: str = Field(default="0.0.0.0", env="API_HOST")
    api_port: int = Field(default=8000, env="API_PORT")
    api_debug: bool = Field(default=False, env="API_DEBUG")
    
    # BAG API
    bag_api_url: str = "https://api.bag.kadaster.nl/lvbag/individuelebevragingen/v2"
    bag_api_key: Optional[str] = Field(default=None, env="BAG_API_KEY")
    
    # Kadaster API
    kadaster_api_url: str = "https://api.pdok.nl"
    kadaster_api_key: Optional[str] = Field(default=None, env="KADASTER_API_KEY")
    
    # Energielabel API
    energielabel_api_url: str = "https://public.ep-online.nl/api/v3"
    
    # Cache configuratie
    cache_enabled: bool = Field(default=True, env="CACHE_ENABLED")
    cache_ttl: int = Field(default=3600, env="CACHE_TTL")
    cache_type: str = Field(default="disk", env="CACHE_TYPE")
    
    # Redis
    redis_host: str = Field(default="localhost", env="REDIS_HOST")
    redis_port: int = Field(default=6379, env="REDIS_PORT")
    redis_db: int = Field(default=0, env="REDIS_DB")
    redis_password: Optional[str] = Field(default=None, env="REDIS_PASSWORD")
    
    # Logging
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    log_format: str = Field(default="json", env="LOG_FORMAT")
    
    # Rate limiting
    rate_limit_enabled: bool = Field(default=True, env="RATE_LIMIT_ENABLED")
    rate_limit_requests: int = Field(default=100, env="RATE_LIMIT_REQUESTS")
    rate_limit_period: int = Field(default=60, env="RATE_LIMIT_PERIOD")
    
    # Timeout settings
    request_timeout: int = Field(default=30, env="REQUEST_TIMEOUT")
    connection_timeout: int = Field(default=10, env="CONNECTION_TIMEOUT")
    
    # Batch processing
    batch_size: int = Field(default=50, env="BATCH_SIZE")
    batch_parallel: bool = Field(default=True, env="BATCH_PARALLEL")
    max_workers: int = Field(default=5, env="MAX_WORKERS")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False


# Globale config instantie
config = Config()
