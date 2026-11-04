from fastapi import APIRouter, status

from app.api.dependencies import CurrentUser, DbSession
from app.api.docs import AUTH_ERRORS, errors
from app.core import clock
from app.schemas.users import UserCreate, UserRead
from app.services import users as users_service

router = APIRouter(prefix="/users", tags=["Utilisateurs"])


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=UserRead,
    summary="Créer un compte",
    description="Crée un compte joueur. Le mot de passe est haché avec Argon2id et n'est jamais renvoyé. "
    "L'adresse e-mail est enregistrée en minuscules et doit être unique.\n\n"
    "**Authentification** : aucune.",
    responses=errors({409: "Un compte existe déjà avec cette adresse e-mail."}),
)
def create_user(data: UserCreate, db: DbSession) -> UserRead:
    user = users_service.create_user(db, data, clock.utcnow())
    return UserRead.model_validate(user)


@router.get(
    "/me",
    response_model=UserRead,
    summary="Consulter son profil",
    description="**Authentification** : requise.",
    responses=AUTH_ERRORS,
)
def read_me(user: CurrentUser) -> UserRead:
    return UserRead.model_validate(user)
