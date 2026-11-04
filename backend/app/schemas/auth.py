from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.schemas.users import UserRead, normalize_email


class _EmailBody(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: EmailStr

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        return normalize_email(value)


class LoginRequest(_EmailBody):
    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={"examples": [{"email": "devlyn@example.com", "password": "Volcan2026"}]},
    )

    password: str = Field(min_length=1, max_length=128)


class ResendRequest(_EmailBody):
    model_config = ConfigDict(extra="forbid", json_schema_extra={"examples": [{"email": "devlyn@example.com"}]})


class ChallengeRead(BaseModel):
    id_auth_challenges: int
    email_masked: str = Field(description="Adresse à afficher au joueur, par exemple `d***@example.com`.")
    expires_at: datetime = Field(description="Fin de validité du code (10 minutes).")
    resend_available_at: datetime = Field(description="Date à partir de laquelle un nouveau code peut être demandé.")
    max_attempts: int = Field(description="Nombre d'essais autorisés pour ce code.")


class SessionCreate(_EmailBody):
    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={"examples": [{"email": "devlyn@example.com", "code": "042917"}]},
    )

    code: str = Field(pattern=r"^\d{6}$", description="Code à six chiffres reçu par e-mail.")


class SessionRead(BaseModel):
    token: str = Field(
        description="Token à envoyer dans l'en-tête `Authorization: Bearer <token>`. "
        "Il n'est renvoyé qu'une fois : le serveur n'en garde qu'une empreinte."
    )
    token_type: Literal["bearer"] = "bearer"
    expires_at: datetime
    user: UserRead
