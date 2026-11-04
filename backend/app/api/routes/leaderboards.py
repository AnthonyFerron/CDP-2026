from typing import Annotated

from fastapi import APIRouter, Query

from app.api.dependencies import DbSession
from app.schemas.leaderboards import LeaderboardPage
from app.services import leaderboards as leaderboards_service

router = APIRouter(prefix="/leaderboards", tags=["Classements"])


@router.get(
    "",
    response_model=LeaderboardPage,
    summary="Classement général",
    description="Meilleure partie gagnée de chaque joueur, triée par temps total croissant. Seules comptent "
    "les parties `completed` entièrement chronométrées par le serveur : les parties perdues, abandonnées ou "
    "importées sont exclues. Deux temps égaux partagent le même rang ; à temps égal, le premier à l'avoir "
    "réalisé est affiché d'abord. Aucune donnée privée (e-mail, identifiant) n'est exposée.\n\n"
    "**Authentification** : aucune.",
)
def read_leaderboard(
    db: DbSession,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> LeaderboardPage:
    items, total = leaderboards_service.general_leaderboard(db, limit, offset)
    return LeaderboardPage(items=items, total=total, limit=limit, offset=offset)
