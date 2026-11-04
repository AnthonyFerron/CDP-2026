"""Configuration de l'API, lue dans les variables d'environnement.

Toutes les valeurs sont documentées dans backend/.env.example. Aucun secret n'a de valeur par défaut
utilisable en production.
"""

import logging
import secrets
from functools import lru_cache
from typing import Literal

from dotenv import load_dotenv
from pydantic import SecretStr
from pydantic_settings import BaseSettings

load_dotenv()

logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    database_url: str

    # Secret serveur qui sert à hacher les codes 2FA (HMAC-SHA256). S'il est vide, une clé aléatoire
    # est tirée au démarrage : cela fonctionne, mais les codes en attente sont perdus à chaque redémarrage.
    secret_key: SecretStr = SecretStr("")

    # Double authentification par e-mail
    otp_ttl_seconds: int = 600
    otp_max_attempts: int = 5
    otp_resend_cooldown_seconds: int = 60
    otp_max_per_hour: int = 5

    # Sessions et connexion
    session_ttl_hours: int = 168
    login_max_failures: int = 10
    login_failure_window_seconds: int = 900

    # Règles de la partie
    game_duration_seconds: int = 3600
    penalty_seconds: int = 300
    # En dessous de ce temps, une résolution est acceptée mais la partie n'est plus classée.
    puzzle_min_solve_seconds: int = 30

    # Envoi des e-mails : "smtp" en production, "console" en développement (le code s'affiche dans
    # les logs de l'API), "memory" pour les tests.
    email_backend: Literal["console", "smtp", "memory"] = "console"
    email_from: str = "CodeQuest <no-reply@localhost>"
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: SecretStr = SecretStr("")
    smtp_security: Literal["starttls", "ssl", "none"] = "starttls"
    smtp_timeout_seconds: float = 10.0

    # Origines autorisées à appeler l'API depuis un autre domaine, séparées par des virgules.
    # Vide en production : le jeu et l'API sont servis sur le même domaine par Caddy.
    cors_allowed_origins: str = ""

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.cors_allowed_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


@lru_cache
def get_secret_key() -> bytes:
    """Clé HMAC des codes 2FA : SECRET_KEY, ou une clé aléatoire propre à ce processus."""
    configured = get_settings().secret_key.get_secret_value()
    if configured:
        return configured.encode()
    logger.warning(
        "SECRET_KEY n'est pas défini : une clé temporaire est utilisée, "
        "les codes de connexion en attente seront invalides après un redémarrage."
    )
    return secrets.token_bytes(32)
