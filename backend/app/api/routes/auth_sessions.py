from fastapi import APIRouter, Response, status

from app.api.dependencies import CurrentAuthSession, DbSession
from app.api.docs import AUTH_ERRORS, errors
from app.core import clock
from app.schemas.auth import SessionCreate, SessionRead
from app.schemas.users import UserRead
from app.services import auth as auth_service

router = APIRouter(prefix="/auth-sessions", tags=["Authentification"])


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=SessionRead,
    summary="Étape 2 : valider le code et ouvrir une session",
    description="Vérifie le code reçu par e-mail et, s'il est bon, ouvre une session dans la même requête : "
    "il n'existe pas de route séparée de « vérification » que le client pourrait contourner.\n\n"
    "Le token renvoyé est valable 7 jours ; le serveur n'en garde qu'une empreinte SHA-256. Chaque appareil "
    "ouvre sa propre session.\n\n"
    "**Authentification** : aucune.",
    responses=errors(
        {
            401: "Code incorrect, expiré, déjà utilisé ou remplacé par un code plus récent.",
            429: "Trop d'essais pour ce code : en demander un nouveau.",
        }
    ),
)
def create_session(data: SessionCreate, db: DbSession) -> SessionRead:
    token, auth_session, user = auth_service.create_session(db, data.email, data.code, clock.utcnow())
    return SessionRead(token=token, expires_at=auth_session.expires_at, user=UserRead.model_validate(user))


@router.delete(
    "/current",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Se déconnecter",
    description="Révoque la session du token envoyé. Les sessions des autres appareils restent ouvertes.\n\n"
    "**Authentification** : requise.",
    responses=AUTH_ERRORS,
)
def delete_current_session(auth_session: CurrentAuthSession, db: DbSession) -> Response:
    auth_service.revoke_session(db, auth_session, clock.utcnow())
    return Response(status_code=status.HTTP_204_NO_CONTENT)
