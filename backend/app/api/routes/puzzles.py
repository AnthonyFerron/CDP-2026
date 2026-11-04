from typing import Annotated

from fastapi import APIRouter, Query

from app.api.dependencies import DbSession, PuzzleId
from app.api.docs import errors
from app.schemas.leaderboards import PuzzleLeaderboardPage
from app.schemas.puzzles import PuzzleRead
from app.services import leaderboards as leaderboards_service
from app.services import puzzle_progress as progress_service

router = APIRouter(prefix="/puzzles")

NOT_FOUND = errors({404: "Énigme introuvable."})


@router.get(
    "",
    response_model=list[PuzzleRead],
    tags=["Énigmes"],
    summary="Lister les énigmes",
    description="Les énigmes, communes à tous les joueurs, triées par `order_index` : 1 Plaine, 2 Désert, "
    "3 Marais, 4 Village (même ordre que `GameState.ZONE_ORDER`). Elles ne sont modifiables que par "
    "migration Alembic, jamais par l'API.\n\n**Authentification** : aucune.",
)
def list_puzzles(db: DbSession) -> list[PuzzleRead]:
    return [PuzzleRead.from_model(puzzle) for puzzle in progress_service.list_puzzles(db)]


@router.get(
    "/{puzzle_id}",
    response_model=PuzzleRead,
    tags=["Énigmes"],
    summary="Détail d'une énigme",
    description="**Authentification** : aucune.",
    responses=NOT_FOUND,
)
def read_puzzle(puzzle_id: PuzzleId, db: DbSession) -> PuzzleRead:
    return PuzzleRead.from_model(progress_service.get_puzzle(db, puzzle_id))


@router.get(
    "/{puzzle_id}/leaderboards",
    response_model=PuzzleLeaderboardPage,
    tags=["Classements"],
    summary="Classement d'une énigme",
    description="Meilleur temps de résolution de chaque joueur sur cette énigme, trié par "
    "`completion_time_ms` croissant. Seules comptent les parties gagnées ; les temps non fiables "
    "(import, résolution invraisemblable) sont exclus. Aucune donnée privée n'est exposée.\n\n"
    "**Authentification** : aucune.",
    responses=NOT_FOUND,
)
def read_puzzle_leaderboard(
    puzzle_id: PuzzleId,
    db: DbSession,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> PuzzleLeaderboardPage:
    puzzle = progress_service.get_puzzle(db, puzzle_id)
    items, total = leaderboards_service.puzzle_leaderboard(db, puzzle, limit, offset)
    return PuzzleLeaderboardPage(
        puzzle=PuzzleRead.from_model(puzzle), items=items, total=total, limit=limit, offset=offset
    )
