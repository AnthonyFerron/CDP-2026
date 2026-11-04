"""Connexion en deux étapes : mot de passe puis code envoyé par e-mail.

1. `start_login` vérifie le mot de passe et envoie un code (table auth_challenges).
2. `create_session` vérifie le code et ouvre une session (table auth_sessions).

La vérification du code et la création de la session se font dans la même requête : le client
n'a jamais à déclarer lui-même qu'un code a été validé.

Un seul code est utilisable à la fois par compte : en émettre un nouveau invalide le précédent
(son `consumed_at` est renseigné). `consumed_at` signifie donc « plus utilisable » : utilisé ou remplacé.
"""

import logging
import smtplib
from datetime import datetime, timedelta

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.errors import (
    NotFoundError,
    ServiceUnavailableError,
    TooManyRequestsError,
    UnauthorizedError,
)
from app.core.rate_limit import login_failures
from app.core.security import (
    burn_password_check,
    generate_otp_code,
    generate_session_token,
    hash_otp_code,
    hash_password,
    hash_session_token,
    password_needs_rehash,
    verify_otp_code,
    verify_password,
)
from app.models.auth_challenge import AuthChallenge
from app.models.auth_session import AuthSession
from app.models.user import User
from app.services.email import EmailSender, send_login_code
from app.services.users import find_by_email

logger = logging.getLogger(__name__)

BAD_CREDENTIALS = "E-mail ou mot de passe incorrect."
QUOTA_WINDOW = timedelta(hours=1)


def mask_email(email: str) -> str:
    local, _, domain = email.partition("@")
    return f"{local[:1]}***@{domain}"


def challenge_created_at(challenge: AuthChallenge) -> datetime:
    # La table n'a pas de date de création : elle se déduit de l'expiration.
    return challenge.expires_at - timedelta(seconds=get_settings().otp_ttl_seconds)


def resend_available_at(challenge: AuthChallenge) -> datetime:
    return challenge_created_at(challenge) + timedelta(seconds=get_settings().otp_resend_cooldown_seconds)


def _check_hourly_quota(db: Session, user: User, now: datetime) -> None:
    settings = get_settings()
    # Créé dans la dernière heure <=> expire après (maintenant - 1 h + durée de validité).
    threshold = now - QUOTA_WINDOW + timedelta(seconds=settings.otp_ttl_seconds)
    recent = db.scalars(
        select(AuthChallenge.expires_at)
        .where(AuthChallenge.id_users == user.id_users, AuthChallenge.expires_at > threshold)
        .order_by(AuthChallenge.expires_at)
    ).all()
    if len(recent) >= settings.otp_max_per_hour:
        oldest_created = recent[0] - timedelta(seconds=settings.otp_ttl_seconds)
        wait = (oldest_created + QUOTA_WINDOW - now).total_seconds()
        raise TooManyRequestsError(
            "Trop de codes demandés pour ce compte. Réessayez plus tard.", retry_after=wait
        )


def _issue_challenge(db: Session, sender: EmailSender, user: User, now: datetime) -> AuthChallenge:
    settings = get_settings()
    db.execute(
        update(AuthChallenge)
        .where(AuthChallenge.id_users == user.id_users, AuthChallenge.consumed_at.is_(None))
        .values(consumed_at=now)
    )
    code = generate_otp_code()
    challenge = AuthChallenge(
        id_users=user.id_users,
        code=hash_otp_code(user.id_users, code),
        expires_at=now + timedelta(seconds=settings.otp_ttl_seconds),
        attempts=0,
    )
    db.add(challenge)
    db.commit()

    try:
        send_login_code(sender, user.email, user.username, code, settings.otp_ttl_seconds)
    except (smtplib.SMTPException, OSError):
        logger.exception("Envoi du code de connexion impossible (compte %s)", user.id_users)
        raise ServiceUnavailableError(
            "L'e-mail contenant le code n'a pas pu être envoyé. Réessayez dans quelques instants."
        ) from None
    return challenge


def start_login(db: Session, sender: EmailSender, email: str, password: str, now: datetime) -> AuthChallenge:
    settings = get_settings()
    window = settings.login_failure_window_seconds
    wait = login_failures.retry_after(email, now.timestamp(), settings.login_max_failures, window)
    if wait is not None:
        raise TooManyRequestsError("Trop de tentatives de connexion. Réessayez plus tard.", retry_after=wait)

    user = find_by_email(db, email, lock=True)
    if user is None:
        burn_password_check(password)
        login_failures.record_failure(email, now.timestamp(), window)
        raise UnauthorizedError(BAD_CREDENTIALS)
    if not verify_password(user.password, password):
        login_failures.record_failure(email, now.timestamp(), window)
        raise UnauthorizedError(BAD_CREDENTIALS)

    login_failures.reset(email)
    if password_needs_rehash(user.password):
        user.password = hash_password(password)
    _check_hourly_quota(db, user, now)
    return _issue_challenge(db, sender, user, now)


def resend_code(db: Session, sender: EmailSender, email: str, now: datetime) -> AuthChallenge:
    user = find_by_email(db, email, lock=True)
    latest = None
    if user is not None:
        latest = db.scalars(
            select(AuthChallenge)
            .where(AuthChallenge.id_users == user.id_users)
            .order_by(AuthChallenge.id_auth_challenges.desc())
            .limit(1)
        ).first()
    if (
        user is None
        or latest is None
        or latest.consumed_at is not None
        or challenge_created_at(latest) <= now - QUOTA_WINDOW
    ):
        raise NotFoundError(
            "Aucune connexion en attente pour cette adresse : reconnectez-vous avec votre mot de passe."
        )

    available_at = resend_available_at(latest)
    if now < available_at:
        raise TooManyRequestsError(
            "Un code vient d'être envoyé. Patientez avant d'en demander un autre.",
            retry_after=(available_at - now).total_seconds(),
        )
    _check_hourly_quota(db, user, now)
    return _issue_challenge(db, sender, user, now)


def create_session(db: Session, email: str, code: str, now: datetime) -> tuple[str, AuthSession, User]:
    settings = get_settings()
    user = find_by_email(db, email)
    if user is None:
        raise UnauthorizedError("Code invalide.")

    challenge = db.scalars(
        select(AuthChallenge)
        .where(AuthChallenge.id_users == user.id_users, AuthChallenge.consumed_at.is_(None))
        .order_by(AuthChallenge.id_auth_challenges.desc())
        .limit(1)
        .with_for_update()
    ).first()
    if challenge is None:
        raise UnauthorizedError("Aucun code en attente, ou code déjà utilisé : demandez un nouveau code.")
    if challenge.attempts >= settings.otp_max_attempts:
        raise TooManyRequestsError("Trop d'essais pour ce code : demandez un nouveau code.")
    if challenge.expires_at <= now:
        raise UnauthorizedError("Ce code a expiré : demandez un nouveau code.")

    if not verify_otp_code(challenge.code, user.id_users, code):
        challenge.attempts += 1
        db.commit()
        remaining = settings.otp_max_attempts - challenge.attempts
        if remaining <= 0:
            raise TooManyRequestsError("Trop d'essais pour ce code : demandez un nouveau code.")
        raise UnauthorizedError(f"Code incorrect. Essais restants : {remaining}.")

    challenge.consumed_at = now
    token = generate_session_token()
    auth_session = AuthSession(
        id_users=user.id_users,
        token=hash_session_token(token),
        created_at=now,
        expires_at=now + timedelta(hours=settings.session_ttl_hours),
    )
    db.add(auth_session)
    db.commit()
    return token, auth_session, user


def find_valid_session(db: Session, token: str, now: datetime) -> AuthSession | None:
    if not token or len(token) > 256:
        return None
    auth_session = db.scalars(
        select(AuthSession).where(AuthSession.token == hash_session_token(token))
    ).one_or_none()
    if auth_session is None or auth_session.revoked_at is not None or auth_session.expires_at <= now:
        return None
    return auth_session


def revoke_session(db: Session, auth_session: AuthSession, now: datetime) -> None:
    auth_session.revoked_at = now
    db.commit()

