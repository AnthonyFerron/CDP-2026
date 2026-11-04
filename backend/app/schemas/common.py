from typing import Annotated, Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")

MAX_DB_ID = 2_147_483_647
DbId = Annotated[int, Field(ge=1, le=MAX_DB_ID)]


class ErrorResponse(BaseModel):
    """Erreur renvoyée par l'API. Les erreurs de validation (422) détaillent chaque champ dans une liste."""

    detail: str = Field(examples=["Partie introuvable."])


class Page(BaseModel, Generic[T]):
    items: list[T]
    total: int = Field(description="Nombre total d'éléments, toutes pages confondues.")
    limit: int
    offset: int
