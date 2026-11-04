from fastapi import APIRouter, status

from app.api.dependencies import DbSession, Mailer
from app.api.docs import errors
from app.core import clock
from app.core.config import get_settings
from app.models.auth_challenge import AuthChallenge
from app.schemas.auth import ChallengeRead, LoginRequest, ResendRequest
from app.services import auth as auth_service

router = APIRouter(prefix="/auth-challenges", tags=["Authentification"])


def _to_read(challenge: AuthChallenge, email: str) -> ChallengeRead:
    return ChallengeRead(
        id_auth_challenges=challenge.id_auth_challenges,
        email_masked=auth_service.mask_email(email),
        expires_at=challenge.expires_at,
        resend_available_at=auth_service.resend_available_at(challenge),
        max_attempts=get_settings().otp_max_attempts,
    )


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=ChallengeRead,
    summary="Étape 1 : vérifier le mot de passe et envoyer un code",
    description="Vérifie l'e-mail et le mot de passe, puis envoie un code à six chiffres à l'adresse du compte. "
    "Le code est valable 10 minutes, ne sert qu'une fois et autorise 5 essais. Demander un nouveau code "
    "invalide le précédent.\n\n"
    "Après 10 échecs de mot de passe en 15 minutes sur une même adresse, la connexion est bloquée "
    "temporairement (429). Un compte peut recevoir au plus 5 codes par heure.\n\n"
    "**Authentification** : aucune.",
    responses=errors(
        {
            401: "E-mail ou mot de passe incorrect (le message ne précise pas lequel).",
            429: None,
            503: "L'e-mail n'a pas pu être envoyé.",
        }
    ),
)
def create_challenge(data: LoginRequest, db: DbSession, mailer: Mailer) -> ChallengeRead:
    challenge = auth_service.start_login(db, mailer, data.email, data.password, clock.utcnow())
    return _to_read(challenge, data.email)


@router.post(
    "/resends",
    status_code=status.HTTP_201_CREATED,
    response_model=ChallengeRead,
    summary="Renvoyer un code",
    description="Envoie un nouveau code pour une connexion commencée depuis moins d'une heure et pas encore "
    "terminée. L'ancien code devient invalide. Un délai de 60 secondes sépare deux envois.\n\n"
    "**Authentification** : aucune.",
    responses=errors(
        {
            404: "Aucune connexion en attente pour cette adresse : recommencer l'étape 1.",
            429: None,
            503: "L'e-mail n'a pas pu être envoyé.",
        }
    ),
)
def resend_challenge(data: ResendRequest, db: DbSession, mailer: Mailer) -> ChallengeRead:
    challenge = auth_service.resend_code(db, mailer, data.email, clock.utcnow())
    return _to_read(challenge, data.email)
