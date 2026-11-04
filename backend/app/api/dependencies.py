"""Dépendances FastAPI partagées : base de données, envoi d'e-mails et authentification."""

from typing import Annotated

from fastapi import Depends, Path
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core import clock
from app.core.errors import UnauthorizedError
from app.db.session import get_db
from app.models.auth_session import AuthSession
from app.models.user import User
from app.schemas.common import MAX_DB_ID
from app.services import auth as auth_service
from app.services.email import EmailSender, get_email_sender

bearer_scheme = HTTPBearer(
    auto_error=False,
    scheme_name="Bearer",
    description="Token renvoyé par POST /api/v1/auth-sessions, à envoyer dans `Authorization: Bearer <token>`.",
)

DbSession = Annotated[Session, Depends(get_db)]
Mailer = Annotated[EmailSender, Depends(get_email_sender)]

GameId = Annotated[int, Path(ge=1, le=MAX_DB_ID, description="Identifiant de la partie (`id_game_sessions`).")]
ProgressId = Annotated[int, Path(ge=1, le=MAX_DB_ID, description="Identifiant de la progression (`id_puzzle_progress`).")]
PuzzleId = Annotated[int, Path(ge=1, le=MAX_DB_ID, description="Identifiant de l'énigme (`id_puzzles`).")]


def get_current_auth_session(
    db: DbSession,
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer_scheme)],
) -> AuthSession:
    if credentials is None:
        raise UnauthorizedError("Authentification requise : envoyez l'en-tête Authorization: Bearer <token>.")
    auth_session = auth_service.find_valid_session(db, credentials.credentials, clock.utcnow())
    if auth_session is None:
        raise UnauthorizedError("Session invalide, expirée ou révoquée : reconnectez-vous.")
    return auth_session


CurrentAuthSession = Annotated[AuthSession, Depends(get_current_auth_session)]


def get_current_user(db: DbSession, auth_session: CurrentAuthSession) -> User:
    user = db.get(User, auth_session.id_users)
    if user is None:
        raise UnauthorizedError("Session invalide, expirée ou révoquée : reconnectez-vous.")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]
