"""Jetons de réinitialisation du mot de passe : des JWT signés en HS256 avec PyJWT.

- **Clé** : dérivée de SECRET_KEY par HMAC-SHA256 avec une étiquette propre à cet usage. Elle ne sert qu'à
  ces jetons : ni les codes 2FA ni un futur autre usage de SECRET_KEY ne partagent la même clé.
- **Contenu** : l'identifiant du compte (`sub`), l'émetteur et l'usage (`iss`, `aud`), les dates (`iat`,
  `exp`) et `pwd`, une empreinte HMAC du hash actuel du mot de passe. Ni l'adresse e-mail ni le hash ne
  figurent dans le jeton, dont le contenu est lisible par qui le détient.
- **Usage unique** : changer le mot de passe change son hash (Argon2 tire un nouveau sel à chaque fois),
  donc l'empreinte. Dès que le mot de passe change, tous les jetons émis avant lui deviennent invalides,
  y compris celui qui a servi : aucune table de jetons n'est nécessaire.
- **Dates** : vérifiées avec l'horloge passée par l'appelant (`clock.utcnow()`), comme tout le code
  métier, et non avec celle de PyJWT, qui ne peut pas être simulée dans les tests.
"""

import base64
import hashlib
import hmac
from dataclasses import dataclass
from datetime import datetime

import jwt

from app.core.config import get_secret_key
from app.schemas.common import MAX_DB_ID

ALGORITHM = "HS256"
ISSUER = "codequest-api"
AUDIENCE = "codequest:password-reset"
# Tolérance pour un `iat` légèrement dans le futur (horloges de plusieurs processus).
_CLOCK_SKEW_SECONDS = 60
_MAX_TOKEN_LENGTH = 2048
_REQUIRED_CLAIMS = ["sub", "iss", "aud", "iat", "exp", "pwd"]


class ResetTokenError(Exception):
    """Jeton refusé : signature, format ou contenu invalide."""


class ResetTokenExpired(ResetTokenError):
    """Jeton authentique, mais expiré."""


@dataclass(frozen=True)
class ResetClaims:
    id_users: int
    password_fingerprint: str


def _derive(label: bytes) -> bytes:
    return hmac.new(get_secret_key(), label, hashlib.sha256).digest()


def _signing_key() -> bytes:
    return _derive(b"codequest/password-reset/jwt-hs256/v1")


def password_fingerprint(password_hash: str) -> str:
    """Empreinte du hash du mot de passe, mise dans le jeton : elle change à chaque changement de mot de passe."""
    digest = hmac.new(
        _derive(b"codequest/password-reset/fingerprint/v1"), password_hash.encode(), hashlib.sha256
    ).digest()
    return base64.urlsafe_b64encode(digest[:16]).rstrip(b"=").decode()


def create_reset_token(id_users: int, password_hash: str, now: datetime, ttl_seconds: int) -> str:
    issued_at = int(now.timestamp())
    payload = {
        "sub": str(id_users),
        "iss": ISSUER,
        "aud": AUDIENCE,
        "iat": issued_at,
        "exp": issued_at + ttl_seconds,
        "pwd": password_fingerprint(password_hash),
    }
    return jwt.encode(payload, _signing_key(), algorithm=ALGORITHM)


def decode_reset_token(token: str, now: datetime) -> ResetClaims:
    """Vérifie la signature, l'usage et l'expiration ; l'empreinte est comparée ensuite, au hash en base."""
    if not token or len(token) > _MAX_TOKEN_LENGTH:
        raise ResetTokenError("jeton vide ou trop long")
    try:
        payload = jwt.decode(
            token,
            _signing_key(),
            algorithms=[ALGORITHM],
            audience=AUDIENCE,
            issuer=ISSUER,
            options={
                "require": _REQUIRED_CLAIMS,
                # Dates vérifiées ci-dessous avec l'horloge du serveur.
                "verify_exp": False,
                "verify_iat": False,
                "verify_nbf": False,
            },
        )
    except jwt.InvalidTokenError as exc:
        raise ResetTokenError(type(exc).__name__) from None

    issued_at, expires_at = payload["iat"], payload["exp"]
    subject, fingerprint = payload["sub"], payload["pwd"]
    if not all(isinstance(value, int) and not isinstance(value, bool) for value in (issued_at, expires_at)):
        raise ResetTokenError("dates illisibles")
    if not (isinstance(subject, str) and subject.isascii() and subject.isdigit()):
        raise ResetTokenError("compte illisible")
    if not 1 <= int(subject) <= MAX_DB_ID:
        raise ResetTokenError("compte hors limites")
    if not (isinstance(fingerprint, str) and fingerprint and fingerprint.isascii()):
        raise ResetTokenError("empreinte illisible")

    timestamp = now.timestamp()
    if issued_at > timestamp + _CLOCK_SKEW_SECONDS:
        raise ResetTokenError("émis dans le futur")
    if expires_at <= timestamp:
        raise ResetTokenExpired("expiré")
    return ResetClaims(id_users=int(subject), password_fingerprint=fingerprint)


def fingerprint_matches(claims: ResetClaims, password_hash: str) -> bool:
    return hmac.compare_digest(claims.password_fingerprint, password_fingerprint(password_hash))
