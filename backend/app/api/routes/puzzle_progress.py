from fastapi import APIRouter, Response, status

from app.api.dependencies import CurrentUser, DbSession, GameId, ProgressId
from app.api.docs import GAME_ERRORS, errors
from app.core import clock
from app.schemas.puzzles import PuzzleProgressRead, PuzzleProgressStart, PuzzleProgressUpdate
from app.services import puzzle_progress as progress_service

router = APIRouter(prefix="/game-sessions/{game_id}/puzzle-progress", tags=["Énigmes"])

AUTH = "\n\n**Authentification** : requise. La partie doit appartenir au joueur connecté."
PLAY_CONFLICTS = "Partie en pause, terminée, ou temps écoulé."


@router.get(
    "",
    response_model=list[PuzzleProgressRead],
    summary="Lister la progression des énigmes",
    description="Une ligne par énigme commencée. `is_solved` indique que le livre est obtenu." + AUTH,
    responses=GAME_ERRORS,
)
def list_puzzle_progress(game_id: GameId, user: CurrentUser, db: DbSession) -> list[PuzzleProgressRead]:
    rows = progress_service.list_progress(db, user, game_id, clock.utcnow())
    return [PuzzleProgressRead.from_model(row, puzzle) for row, puzzle in rows]


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=PuzzleProgressRead,
    summary="Commencer une énigme",
    description="Crée la progression d'une énigme, à l'entrée dans sa zone. Nécessaire avant d'utiliser un "
    "indice ou d'enregistrer la résolution.\n\n"
    "Idempotent : si l'énigme est déjà commencée, renvoie la progression existante avec le code 200. Les "
    "énigmes se commencent dans l'ordre (`order_index`) : la précédente doit être résolue." + AUTH,
    responses={
        200: {"model": PuzzleProgressRead, "description": "Énigme déjà commencée : progression existante."},
        **GAME_ERRORS,
        **errors({409: "Énigme verrouillée, partie en pause ou terminée, ou temps écoulé."}),
    },
)
def start_puzzle(
    game_id: GameId, data: PuzzleProgressStart, user: CurrentUser, db: DbSession, response: Response
) -> PuzzleProgressRead:
    progress, puzzle, created = progress_service.start_puzzle(db, user, game_id, data.id_puzzles, clock.utcnow())
    if not created:
        response.status_code = status.HTTP_200_OK
    return PuzzleProgressRead.from_model(progress, puzzle)


@router.patch(
    "/{progress_id}",
    response_model=PuzzleProgressRead,
    summary="Enregistrer la résolution d'une énigme",
    description="Seul changement autorisé : `{\"solved\": true}`. Le serveur date la résolution et mesure "
    "`completion_time_ms` avec son propre chronomètre ; le joueur obtient le livre de l'énigme.\n\n"
    "Limite : le serveur ne peut pas vérifier que l'énigme a réellement été résolue dans Godot. Il garantit "
    "l'ordre, l'unicité et la mesure du temps ; une résolution plus rapide que le minimum plausible est "
    "acceptée mais sort la partie du classement." + AUTH,
    responses={
        **GAME_ERRORS,
        **errors({409: "Énigme déjà résolue ou verrouillée, partie en pause ou terminée, ou temps écoulé."}),
    },
)
def solve_puzzle(
    game_id: GameId, progress_id: ProgressId, data: PuzzleProgressUpdate, user: CurrentUser, db: DbSession
) -> PuzzleProgressRead:
    progress, puzzle = progress_service.solve_puzzle(db, user, game_id, progress_id, clock.utcnow())
    return PuzzleProgressRead.from_model(progress, puzzle)


@router.post(
    "/{progress_id}/hints",
    response_model=PuzzleProgressRead,
    summary="Utiliser un indice",
    description="Consomme un indice de l'énigme, dans la limite de `hints_count`. Le texte des indices "
    "reste dans Godot." + AUTH,
    responses={
        **GAME_ERRORS,
        **errors({409: "Plus d'indice disponible, énigme déjà résolue, ou " + PLAY_CONFLICTS.lower()}),
    },
)
def use_hint(game_id: GameId, progress_id: ProgressId, user: CurrentUser, db: DbSession) -> PuzzleProgressRead:
    progress, puzzle = progress_service.use_hint(db, user, game_id, progress_id, clock.utcnow())
    return PuzzleProgressRead.from_model(progress, puzzle)
