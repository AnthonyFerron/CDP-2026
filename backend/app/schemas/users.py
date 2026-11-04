import re
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

_USERNAME_RE = re.compile(r"^[\w .'-]+$")


def normalize_email(value: str) -> str:
    value = value.strip().lower()
    if len(value) > 255:
        raise ValueError("L'adresse e-mail ne doit pas dépasser 255 caractères.")
    return value


class UserCreate(BaseModel):
    model_config = ConfigDict(
        extra="forbid",
        json_schema_extra={
            "examples": [{"username": "Devlyn", "email": "devlyn@example.com", "password": "Volcan2026"}]
        },
    )

    username: str = Field(
        min_length=3,
        max_length=50,
        description="Nom affiché dans les classements : lettres, chiffres, espaces, `_ - . '`.",
    )
    email: EmailStr = Field(description="Adresse unique, qui reçoit les codes de connexion.")
    password: str = Field(
        min_length=8,
        max_length=128,
        description="8 à 128 caractères, avec au moins une lettre et un chiffre.",
    )

    @field_validator("username", mode="before")
    @classmethod
    def _strip_username(cls, value: object) -> object:
        return " ".join(value.split()) if isinstance(value, str) else value

    @field_validator("username")
    @classmethod
    def _check_username(cls, value: str) -> str:
        if not _USERNAME_RE.match(value):
            raise ValueError("Le nom ne peut contenir que des lettres, des chiffres, des espaces et _ - . '")
        return value

    @field_validator("email")
    @classmethod
    def _normalize_email(cls, value: str) -> str:
        return normalize_email(value)

    @field_validator("password")
    @classmethod
    def _check_password(cls, value: str) -> str:
        if not any(char.isalpha() for char in value) or not any(char.isdigit() for char in value):
            raise ValueError("Le mot de passe doit contenir au moins une lettre et un chiffre.")
        return value


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id_users: int
    username: str
    email: str
    created_at: datetime
