from typing import Annotated

from fastapi import APIRouter, Query, status

from app.api.dependencies import CurrentUser, DbSession, GameId
from app.api.docs import GAME_ERRORS, errors
from app.core import clock
from app.schemas.common import Page
from app.schemas.game_sessions import (
    CompletionRequest,
    GameImportRequest,
    GameSessionCreate,
    GameSessionRead,
    GameSessionUpdate,
    GameStatus,
)
from app.schemas.puzzles import GameProgressRead
from app.services import game_sessions as games
from app.services.puzzle_progress import game_progress

router = APIRouter(prefix="/game-sessions", tags=["Parties"])

AUTH = "\n\n**Authentification** : requise. Une partie d'un autre joueur répond 404."
ACTIVE_CONFLICTS = "Partie terminée, ou temps écoulé (la partie vient de passer en `game_over`)."


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=GameSessionRead,
    summary="Créer une partie",
    description="Crée une partie et démarre son chronomètre aussitôt. À appeler quand le chronomètre démarre "
    "dans Godot (fin de la mission confiée par le roi et Merlon).\n\n"
    "Un joueur n'a qu'une partie en cours à la fois : si une partie est encore en cours, la reprendre "
    "ou l'abandonner d'abord (409)." + AUTH,
    responses=errors({401: None, 409: "Une partie est déjà en cours pour ce joueur."}),
)
def create_game_session(data: GameSessionCreate, user: CurrentUser, db: DbSession) -> GameSessionRead:
    now = clock.utcnow()
    return games.read_game(db, games.create_game(db, user, data, now), now)


@router.get(
    "",
    response_model=Page[GameSessionRead],
    summary="Lister ses parties",
    description="Parties du joueur, de la plus récente à la plus ancienne. Filtrer sur `status=in_progress` "
    "pour retrouver la partie à reprendre, par exemple sur un autre appareil." + AUTH,
    responses=errors({401: None}),
)
def list_game_sessions(
    user: CurrentUser,
    db: DbSession,
    status_filter: Annotated[GameStatus | None, Query(alias="status", description="Filtre sur l'état.")] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> Page[GameSessionRead]:
    now = clock.utcnow()
    items, total = games.list_games(db, user, now, status=status_filter, limit=limit, offset=offset)
    return Page[GameSessionRead](items=games.read_games(db, items, now), total=total, limit=limit, offset=offset)


@router.post(
    "/imports",
    status_code=status.HTTP_201_CREATED,
    response_model=GameSessionRead,
    summary="Importer la progression d'un invité",
    description="Rattache au compte connecté une partie jouée en invité, lue dans la sauvegarde locale de Godot.\n\n"
    "Le serveur vérifie la cohérence des données (énigmes existantes et résolues dans l'ordre, indices dans "
    "la limite, temps compris entre 0 et la durée de la partie, état compatible avec le temps), mais ne peut "
    "pas prouver qu'elles sont authentiques. La partie importée n'entre donc **jamais** dans les classements "
    "(`is_rankable: false` dès qu'une énigme importée est résolue).\n\n"
    "Une partie `in_progress` est importée **en pause** : appeler `/resumptions` quand le joueur reprend. "
    "Elle est refusée (409) si une autre partie est déjà en cours." + AUTH,
    responses=errors({401: None, 409: "Une partie est déjà en cours pour ce joueur."}),
)
def import_game_session(data: GameImportRequest, user: CurrentUser, db: DbSession) -> GameSessionRead:
    now = clock.utcnow()
    return games.read_game(db, games.import_game(db, user, data, now), now)


@router.get(
    "/{game_id}",
    response_model=GameSessionRead,
    summary="Récupérer une partie",
    description="État complet de la partie, avec le temps consommé et le temps restant calculés à l'instant "
    "de la requête. Si le temps est écoulé, la partie passe en `game_over`." + AUTH,
    responses=GAME_ERRORS,
)
def read_game_session(game_id: GameId, user: CurrentUser, db: DbSession) -> GameSessionRead:
    now = clock.utcnow()
    return games.read_game(db, games.get_game(db, user, game_id, now), now)


@router.patch(
    "/{game_id}",
    response_model=GameSessionRead,
    summary="Sauvegarder la position",
    description="Enregistre le niveau et la position du joueur. Seuls `current_level`, `position_x`, "
    "`position_y`, `position_z` et `rotation_y` sont acceptés : tout autre champ (`status`, "
    "`elapsed_seconds`…) est refusé avec une erreur 422. Possible en pause." + AUTH,
    responses={**GAME_ERRORS, **errors({409: ACTIVE_CONFLICTS})},
)
def save_game_session(game_id: GameId, data: GameSessionUpdate, user: CurrentUser, db: DbSession) -> GameSessionRead:
    now = clock.utcnow()
    return games.read_game(db, games.save_game(db, user, game_id, data, now), now)


@router.post(
    "/{game_id}/pauses",
    response_model=GameSessionRead,
    summary="Mettre en pause",
    description="Arrête le chronomètre. Le temps consommé est arrondi à la seconde supérieure." + AUTH,
    responses={**GAME_ERRORS, **errors({409: "Partie déjà en pause, terminée, ou temps écoulé."})},
)
def pause_game_session(game_id: GameId, user: CurrentUser, db: DbSession) -> GameSessionRead:
    now = clock.utcnow()
    return games.read_game(db, games.pause_game(db, user, game_id, now), now)


@router.post(
    "/{game_id}/resumptions",
    response_model=GameSessionRead,
    summary="Reprendre après une pause",
    description="Relance le chronomètre." + AUTH,
    responses={**GAME_ERRORS, **errors({409: "Partie pas en pause, ou terminée."})},
)
def resume_game_session(game_id: GameId, user: CurrentUser, db: DbSession) -> GameSessionRead:
    now = clock.utcnow()
    return games.read_game(db, games.resume_game(db, user, game_id, now), now)


@router.post(
    "/{game_id}/penalties",
    response_model=GameSessionRead,
    summary="Appliquer une pénalité de temps",
    description="Retire 5 minutes au temps restant, après une mauvaise validation d'énigme "
    "(`GameState.penalize()` dans Godot). Si le temps tombe à zéro, la partie passe en `game_over` : "
    "vérifier `status` dans la réponse." + AUTH,
    responses={**GAME_ERRORS, **errors({409: ACTIVE_CONFLICTS})},
)
def penalize_game_session(game_id: GameId, user: CurrentUser, db: DbSession) -> GameSessionRead:
    now = clock.utcnow()
    return games.read_game(db, games.penalize_game(db, user, game_id, now), now)


@router.post(
    "/{game_id}/completions",
    response_model=GameSessionRead,
    summary="Valider la victoire",
    description="Termine la partie en victoire si, avant la fin du temps :\n"
    "- toutes les énigmes sont résolues côté serveur ;\n"
    "- `placed_puzzle_ids` liste exactement les livres de toutes les énigmes, posés au château.\n\n"
    "Le serveur ne garde pas trace des livres posés (aucune colonne dédiée) : cette liste est une "
    "déclaration du client, vérifiée seulement contre les énigmes résolues. Le temps total est figé." + AUTH,
    responses={
        **GAME_ERRORS,
        **errors({409: "Énigmes non résolues, livres manquants, partie en pause ou terminée, ou temps écoulé."}),
    },
)
def complete_game_session(
    game_id: GameId, data: CompletionRequest, user: CurrentUser, db: DbSession
) -> GameSessionRead:
    now = clock.utcnow()
    return games.read_game(db, games.complete_game(db, user, game_id, data.placed_puzzle_ids, now), now)


@router.post(
    "/{game_id}/abandonments",
    response_model=GameSessionRead,
    summary="Abandonner",
    description="Termine la partie en abandon. Elle n'apparaîtra dans aucun classement." + AUTH,
    responses={**GAME_ERRORS, **errors({409: ACTIVE_CONFLICTS})},
)
def abandon_game_session(game_id: GameId, user: CurrentUser, db: DbSession) -> GameSessionRead:
    now = clock.utcnow()
    return games.read_game(db, games.abandon_game(db, user, game_id, now), now)


@router.get(
    "/{game_id}/progress",
    response_model=GameProgressRead,
    summary="Récupérer la progression",
    description="Vue d'ensemble pour Godot : chronomètre, livres obtenus et état de chaque énigme "
    "(verrouillée, commencée, résolue, indices). Un livre est obtenu quand son énigme est résolue." + AUTH,
    responses=GAME_ERRORS,
)
def read_game_progress(game_id: GameId, user: CurrentUser, db: DbSession) -> GameProgressRead:
    return game_progress(db, user, game_id, clock.utcnow())
