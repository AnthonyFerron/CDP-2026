from fastapi import APIRouter, BackgroundTasks, status

from app.api.dependencies import DbSession, Mailer
from app.api.docs import errors
from app.core import clock
from app.core.config import get_settings
from app.schemas.auth import PasswordResetConfirm, PasswordResetDone, PasswordResetRequest, PasswordResetRequested
from app.services import password_resets as reset_service

router = APIRouter(prefix="/password-resets", tags=["Authentification"])


@router.post(
    "",
    status_code=status.HTTP_202_ACCEPTED,
    response_model=PasswordResetRequested,
    summary="Mot de passe oublié : demander un lien par e-mail",
    description="Si l'adresse correspond à un compte, envoie à cette adresse un lien "
    "`https://codequest.anthonyferron.com/reinitialisation?token=<jeton>` (réglage `PASSWORD_RESET_URL`). "
    "Le jeton est un JWT signé (HS256), valable 30 minutes, qui ne sert qu'une fois : il cesse de valoir "
    "dès que le mot de passe change.\n\n"
    "La réponse est **toujours la même** (202), que le compte existe ou non : l'e-mail part après la "
    "réponse, et un échec d'envoi n'est que journalisé. Une même adresse peut faire une demande par minute "
    "et cinq par heure, qu'elle corresponde à un compte ou non (429 au-delà).\n\n"
    "**Authentification** : aucune.",
    responses=errors({429: None}),
)
def request_password_reset(
    data: PasswordResetRequest, db: DbSession, mailer: Mailer, background: BackgroundTasks
) -> PasswordResetRequested:
    email = reset_service.request_reset(db, data.email, clock.utcnow())
    if email is not None:
        background.add_task(reset_service.deliver, mailer, email)
    return PasswordResetRequested(
        message=reset_service.requested_message(),
        expires_in_minutes=get_settings().password_reset_ttl_seconds // 60,
    )


@router.post(
    "/confirmations",
    response_model=PasswordResetDone,
    summary="Choisir un nouveau mot de passe avec le jeton du lien",
    description="Vérifie le jeton du lien (signature, usage, expiration, mot de passe inchangé depuis "
    "l'envoi), puis remplace le mot de passe. Le nouveau suit les règles de l'inscription : 8 à 128 "
    "caractères, avec au moins une lettre et un chiffre.\n\n"
    "Toutes les sessions du compte sont fermées et les codes de connexion en attente annulés : le joueur "
    "se reconnecte avec le nouveau mot de passe. Le lien, et tous ceux envoyés avant lui, ne valent plus.\n\n"
    "**Authentification** : aucune (le jeton du lien en tient lieu).",
    responses=errors(
        {400: "Lien invalide, expiré, déjà utilisé ou antérieur au dernier changement de mot de passe."}
    ),
)
def confirm_password_reset(data: PasswordResetConfirm, db: DbSession) -> PasswordResetDone:
    reset_service.confirm_reset(db, data.token, data.password, clock.utcnow())
    return PasswordResetDone(
        message="Votre mot de passe a été modifié. Retournez dans le jeu pour vous connecter avec le nouveau."
    )
