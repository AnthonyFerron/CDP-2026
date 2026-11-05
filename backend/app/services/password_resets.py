"""Réinitialisation du mot de passe par un lien envoyé par e-mail.

1. `request_reset` : pour une adresse e-mail, prépare l'e-mail du lien si un compte lui correspond. La
   réponse de l'API est la même dans tous les cas, et l'e-mail part après elle (tâche de fond) : ni le
   contenu, ni le code HTTP, ni le temps de réponse, ni un échec d'envoi ne révèlent si le compte existe.
2. `confirm_reset` : vérifie le jeton (JWT, voir app/core/reset_tokens.py), remplace le hash du mot de
   passe, ferme toutes les sessions du compte et annule ses codes de connexion en attente.

La limitation compte les demandes par adresse e-mail, que le compte existe ou non : un refus (429) ne
révèle donc rien non plus.
"""

import logging
import smtplib
from dataclasses import dataclass
from datetime import datetime
from urllib.parse import urlencode

from sqlalchemy import update
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.errors import BadRequestError, ServiceUnavailableError, TooManyRequestsError
from app.core.rate_limit import login_failures, password_reset_hourly, password_reset_recent
from app.core.reset_tokens import (
    ResetTokenError,
    ResetTokenExpired,
    create_reset_token,
    decode_reset_token,
    fingerprint_matches,
)
from app.core.security import hash_password
from app.models.auth_challenge import AuthChallenge
from app.models.auth_session import AuthSession
from app.models.user import User
from app.services.email import EmailSender
from app.services.users import find_by_email

logger = logging.getLogger(__name__)

HOUR_SECONDS = 3600
INVALID_LINK = "Ce lien de réinitialisation n'est pas valide. Demandez-en un nouveau depuis le jeu."
EXPIRED_LINK = "Ce lien de réinitialisation a expiré. Demandez-en un nouveau depuis le jeu."
USED_LINK = (
    "Ce lien a déjà servi, ou le mot de passe a changé depuis son envoi. Demandez-en un nouveau depuis le jeu."
)


@dataclass(frozen=True)
class ResetEmail:
    id_users: int
    to: str
    subject: str
    body: str


def requested_message() -> str:
    minutes = get_settings().password_reset_ttl_seconds // 60
    return (
        "Si un compte correspond à cette adresse, un e-mail vient de lui être envoyé avec un lien pour "
        f"choisir un nouveau mot de passe. Ce lien est valable {minutes} minutes."
    )


def reset_link(token: str) -> str:
    base = get_settings().password_reset_url
    separator = "&" if "?" in base else "?"
    return f"{base}{separator}{urlencode({'token': token})}"


def _check_rate_limit(email: str, now: datetime) -> None:
    settings = get_settings()
    timestamp = now.timestamp()
    recent_window = settings.password_reset_cooldown_seconds
    wait = password_reset_recent.retry_after(email, timestamp, 1, recent_window)
    if wait is not None:
        raise TooManyRequestsError(
            "Un lien vient d'être demandé : patientez avant d'en redemander un.",
            retry_after=wait,
        )
    wait = password_reset_hourly.retry_after(email, timestamp, settings.password_reset_max_per_hour, HOUR_SECONDS)
    if wait is not None:
        raise TooManyRequestsError(
            "Trop de liens demandés pour cette adresse : réessayez plus tard.", retry_after=wait
        )
    password_reset_recent.record_failure(email, timestamp, recent_window)
    password_reset_hourly.record_failure(email, timestamp, HOUR_SECONDS)


def request_reset(db: Session, email: str, now: datetime) -> ResetEmail | None:
    """L'e-mail à envoyer si l'adresse correspond à un compte, sinon None. À envoyer après la réponse."""
    _check_rate_limit(email, now)
    user = find_by_email(db, email)
    if user is None:
        return None

    settings = get_settings()
    token = create_reset_token(user.id_users, user.password, now, settings.password_reset_ttl_seconds)
    minutes = settings.password_reset_ttl_seconds // 60
    body = (
        f"Bonjour {user.username},\n\n"
        "Une réinitialisation du mot de passe de votre compte CodeQuest a été demandée.\n"
        "Pour choisir un nouveau mot de passe, ouvrez ce lien :\n\n"
        f"{reset_link(token)}\n\n"
        f"Il est valable {minutes} minutes et ne sert qu'une fois. Le nouveau mot de passe ferme les "
        "sessions ouvertes sur tous vos appareils.\n\n"
        "Si vous n'avez rien demandé, ignorez cet e-mail : votre mot de passe actuel reste valable.\n"
    )
    return ResetEmail(user.id_users, user.email, "Réinitialiser votre mot de passe CodeQuest", body)


def deliver(sender: EmailSender, email: ResetEmail) -> None:
    """Envoie l'e-mail du lien. Lancé après la réponse : un échec est journalisé, sans adresse ni jeton."""
    try:
        sender.send(email.to, email.subject, email.body)
    except (smtplib.SMTPException, OSError, ServiceUnavailableError):
        logger.exception("Envoi du lien de réinitialisation impossible (compte %s)", email.id_users)


def confirm_reset(db: Session, token: str, new_password: str, now: datetime) -> User:
    try:
        claims = decode_reset_token(token, now)
    except ResetTokenExpired:
        raise BadRequestError(EXPIRED_LINK) from None
    except ResetTokenError:
        raise BadRequestError(INVALID_LINK) from None

    # Hachage (lent) avant de verrouiller le compte.
    new_hash = hash_password(new_password)
    # Verrou de ligne : deux confirmations simultanées du même lien ne peuvent pas réussir toutes les deux,
    # la seconde lit le nouveau hash et son empreinte ne correspond plus.
    user = db.get(User, claims.id_users, with_for_update=True)
    if user is None or not fingerprint_matches(claims, user.password):
        raise BadRequestError(USED_LINK)

    user.password = new_hash
    db.execute(
        update(AuthSession)
        .where(AuthSession.id_users == user.id_users, AuthSession.revoked_at.is_(None))
        .values(revoked_at=now)
    )
    db.execute(
        update(AuthChallenge)
        .where(AuthChallenge.id_users == user.id_users, AuthChallenge.consumed_at.is_(None))
        .values(consumed_at=now)
    )
    db.commit()
    # Le blocage après des mots de passe erronés ne doit pas empêcher d'utiliser le nouveau.
    login_failures.reset(user.email)
    logger.info("Mot de passe réinitialisé (compte %s), sessions fermées", user.id_users)
    return user
