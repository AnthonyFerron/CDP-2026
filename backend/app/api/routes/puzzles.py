from fastapi import APIRouter

from app.api.dependencies import DbSession, PuzzleId
from app.api.docs import errors
from app.schemas.puzzles import PuzzleRead
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

