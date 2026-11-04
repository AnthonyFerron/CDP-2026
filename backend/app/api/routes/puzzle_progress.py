from fastapi import APIRouter, Response, status

from app.api.dependencies import CurrentUser, DbSession, GameId, ProgressId
from app.api.docs import GAME_ERRORS, errors
from app.core import clock
from app.schemas.puzzles import PuzzleProgressRead, PuzzleProgressStart, PuzzleProgressUpdate
from app.services import puzzle_progress as progress_service

router = APIRouter(prefix="/game-sessions/{game_id}/puzzle-progress", tags=["Énigmes"])

AUTH = "\n\n**Authentification** : requise. La partie doit appartenir au joueur connecté."


@router.get(
    "",
    response_model=list[PuzzleProgressRead],
    summary="Lister la progression des énigmes",
    description="Une ligne par énigme commencée. `is_solved` indique que le livre est obtenu, `is_placed` "
    "qu'il est posé au château." + AUTH,
    responses=GAME_ERRORS,
)
def list_puzzle_progress(game_id: GameId, user: CurrentUser, db: DbSession) -> list[PuzzleProgressRead]:
    rows = progress_service.list_progress(db, user, game_id, clock.utcnow())
    return [PuzzleProgressRead.from_model(row) for row in rows]


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=PuzzleProgressRead,
    summary="Commencer une énigme",
    description="Crée la progression d'une énigme, à l'entrée dans sa zone. Nécessaire avant d'enregistrer "
    "la résolution, qui se fait sur cette progression.\n\n"
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
    progress, _, created = progress_service.start_puzzle(db, user, game_id, data.id_puzzles, clock.utcnow())
    if not created:
        response.status_code = status.HTTP_200_OK
    return PuzzleProgressRead.from_model(progress)


@router.patch(
    "/{progress_id}",
    response_model=PuzzleProgressRead,
    summary="Enregistrer la résolution d'une énigme",
    description="Seul changement autorisé : `{\"solved\": true}`. Le serveur date la résolution et mesure "
    "`completion_time_ms` avec son propre chronomètre ; le joueur obtient le livre de l'énigme.\n\n"
    "Limite : le serveur ne peut pas vérifier que l'énigme a réellement été résolue dans Godot. Il garantit "
    "l'ordre, l'unicité et la mesure du temps ; une résolution en moins de 30 secondes est acceptée mais "
    "sort la partie du classement." + AUTH,
    responses={
        **GAME_ERRORS,
        **errors({409: "Énigme déjà résolue ou verrouillée, partie en pause ou terminée, ou temps écoulé."}),
    },
)
def solve_puzzle(
    game_id: GameId, progress_id: ProgressId, data: PuzzleProgressUpdate, user: CurrentUser, db: DbSession
) -> PuzzleProgressRead:
    progress = progress_service.solve_puzzle(db, user, game_id, progress_id, clock.utcnow())
    return PuzzleProgressRead.from_model(progress)


@router.post(
    "/{progress_id}/placements",
    response_model=PuzzleProgressRead,
    summary="Poser un livre au château",
    description="Pose le livre de cette énigme sur son piédestal, dans la salle des livres du château "
    "(`GameState.place_book()` dans Godot). Le dépôt est conservé : il survit à la reprise de la partie, "
    "y compris sur un autre appareil.\n\n"
    "Le livre doit être obtenu (énigme résolue) et ne se pose qu'une fois. Comme toute action de jeu, le "
    "dépôt est refusé en pause, après la fin de la partie ou quand le temps est écoulé." + AUTH,
    responses={
        **GAME_ERRORS,
        **errors({409: "Livre non obtenu ou déjà posé, partie en pause ou terminée, ou temps écoulé."}),
    },
)
def place_book(game_id: GameId, progress_id: ProgressId, user: CurrentUser, db: DbSession) -> PuzzleProgressRead:
    progress = progress_service.place_book(db, user, game_id, progress_id, clock.utcnow())
    return PuzzleProgressRead.from_model(progress)
