from fastapi import APIRouter, status

from app.api.dependencies import CurrentUser, DbSession, GameId
from app.api.docs import GAME_ERRORS, errors
from app.core import clock
from app.schemas.puzzles import PaperFragmentCollect, PaperFragmentRead
from app.services import puzzle_progress as progress_service

router = APIRouter(prefix="/game-sessions/{game_id}/paper-fragments", tags=["Énigmes"])

AUTH = "\n\n**Authentification** : requise. La partie doit appartenir au joueur connecté."


@router.get(
    "",
    response_model=list[PaperFragmentRead],
    summary="Lister les fragments de papier ramassés",
    description="Fragments de papier de la mairie (énigme du Village) déjà ramassés dans cette partie, triés "
    "par numéro. À la reprise d'une partie, Godot masque ces fragments et les remet dans le carnet." + AUTH,
    responses=GAME_ERRORS,
)
def list_paper_fragments(game_id: GameId, user: CurrentUser, db: DbSession) -> list[PaperFragmentRead]:
    fragments = progress_service.list_fragments(db, user, game_id, clock.utcnow())
    return [PaperFragmentRead.from_model(fragment) for fragment in fragments]


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=PaperFragmentRead,
    summary="Ramasser un fragment de papier",
    description="Enregistre un des 10 fragments de papier cachés dans la mairie, identifié par son numéro "
    "de 0 à 9 (`PaperFragment.fragment` dans Godot). Chaque fragment ne se ramasse qu'une fois par partie.\n\n"
    "Le Village doit être ouvert (énigme du Marais résolue) ; refusé en pause, après la fin de la partie "
    "ou quand le temps est écoulé. Ce ne sont pas des indices consommés : ils ne changent ni le temps ni "
    "le classement." + AUTH,
    responses={
        **GAME_ERRORS,
        **errors({409: "Fragment déjà ramassé, Village pas encore ouvert, partie en pause ou terminée, ou temps écoulé."}),
    },
)
def collect_paper_fragment(
    game_id: GameId, data: PaperFragmentCollect, user: CurrentUser, db: DbSession
) -> PaperFragmentRead:
    fragment = progress_service.collect_fragment(db, user, game_id, data.fragment_index, clock.utcnow())
    return PaperFragmentRead.from_model(fragment)
