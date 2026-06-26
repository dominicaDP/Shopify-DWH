"""
Central configuration for the production Shopify -> Exasol ETL.

Every connection detail and run setting comes from environment variables (loaded
from a .env file in development, or injected by the systemd service on the ETL
host). This is the ONLY module that reads os.environ — everything else takes a
`Settings` object. That keeps secrets out of source and out of scattered
`load_dotenv` calls, and makes the two target schemas configurable for
productisation (a different merchant deploy just points at different schemas).

Usage:
    from shopify_dwh.config import load_settings
    settings = load_settings()
    settings.exasol.dsn, settings.shopify.token, ...
"""

from __future__ import annotations

import logging
import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv


class ConfigError(RuntimeError):
    """Raised when required configuration is missing or invalid."""


# The .env lives at the etl project root (code/etl/.env), one level above this package.
DEFAULT_ENV_PATH = Path(__file__).resolve().parent.parent / ".env"

_TRUTHY = {"1", "true", "yes", "on"}


def _env(name: str, default: str | None = None, *, required: bool = False) -> str | None:
    value = os.environ.get(name, default)
    if required and not value:
        raise ConfigError(f"Missing required environment variable: {name}")
    return value


def _bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.strip().lower() in _TRUTHY


@dataclass(frozen=True)
class ShopifyConfig:
    shop_domain: str
    api_version: str
    token: str
    scopes: str
    client_id: str | None
    client_secret: str | None
    redirect_uri: str | None


@dataclass(frozen=True)
class ExasolConfig:
    dsn: str
    user: str
    password: str
    stg_schema: str
    dwh_schema: str
    encryption: bool
    certificate_validation: bool


@dataclass(frozen=True)
class Settings:
    shopify: ShopifyConfig
    exasol: ExasolConfig
    log_level: str


def load_settings(env_path: Path | None = None) -> Settings:
    """Build a Settings object from the environment (loading .env first)."""
    load_dotenv(env_path or DEFAULT_ENV_PATH)

    shopify = ShopifyConfig(
        shop_domain=_env("SHOPIFY_SHOP_DOMAIN", required=True),
        api_version=_env("SHOPIFY_API_VERSION", required=True),
        token=_env("SHOPIFY_ACCESS_TOKEN", "") or "",
        scopes=_env("SHOPIFY_SCOPES", "") or "",
        client_id=_env("SHOPIFY_CLIENT_ID"),
        client_secret=_env("SHOPIFY_CLIENT_SECRET"),
        redirect_uri=_env("SHOPIFY_REDIRECT_URI"),
    )

    exasol = ExasolConfig(
        dsn=_env("EXASOL_DSN", required=True),
        user=_env("EXASOL_USER", required=True),
        password=_env("EXASOL_PASSWORD", required=True),
        stg_schema=_env("EXASOL_STG_SCHEMA", "SHOPIFY_STG"),
        dwh_schema=_env("EXASOL_DWH_SCHEMA", "SHOPIFY_DWH"),
        # Secure-by-default for production: encrypt the wire and validate the cert.
        # The local POC set both off (self-signed Docker box); a real host has a
        # real cert, so we only relax these via explicit env override.
        encryption=_bool("EXASOL_ENCRYPTION", True),
        certificate_validation=_bool("EXASOL_CERTIFICATE_VALIDATION", True),
    )

    return Settings(
        shopify=shopify,
        exasol=exasol,
        log_level=_env("LOG_LEVEL", "INFO") or "INFO",
    )


def configure_logging(settings: Settings | None = None) -> None:
    """Apply a consistent log format/level for any entry point."""
    level = (settings.log_level if settings else "INFO").upper()
    logging.basicConfig(
        level=getattr(logging, level, logging.INFO),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
