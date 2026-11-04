"""Parties : chronomètre, sauvegarde, transitions d'état, victoire et import d'une partie invitée.

Chronomètre, calculé uniquement avec l'heure du serveur :
- `elapsed_seconds` : temps consommé avant `timer_started_at` (pénalités comprises) ;
- `timer_started_at` : début ou reprise du chronomètre, NULL quand il est arrêté (pause ou fin).
Temps consommé à l'instant t = elapsed_seconds + (t - timer_started_at).

À l'arrêt, le temps est arrondi à la seconde supérieure : enchaîner pauses et reprises ne peut jamais
faire gagner de temps. Dès que le temps consommé atteint la durée de la partie, elle passe en
`game_over`. Ce contrôle a lieu à chaque lecture ou écriture de la partie, avant toute autre règle.

États : in_progress → completed | game_over | abandoned. Une partie terminée ne change plus.
"""

from datetime import datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.errors import ConflictError, NotFoundError, UnprocessableError
from app.models.game_session import GameSession
from app.models.puzzle import Puzzle
from app.models.puzzle_progress import PuzzleProgress
from app.models.user import User
from app.schemas.game_sessions import GameImportRequest, GameSessionCreate, GameSessionRead, GameSessionUpdate

IN_PROGRESS = "in_progress"
COMPLETED = "completed"
GAME_OVER = "game_over"
ABANDONED = "abandoned"

TIME_UP = "Temps écoulé : le volcan est entré en éruption, la partie est perdue."
PAUSED = "La partie est en pause : reprenez-la avant de continuer."


# --- Chronomètre -----------------------------------------------------------------------------------

def _ceil_div(numerator: int, denominator: int) -> int:
    return -(-numerator // denominator)


def elapsed_ms(game: GameSession, now: datetime) -> int:
    total = game.elapsed_seconds * 1000
    if game.status == IN_PROGRESS and game.timer_started_at is not None:
        total += max(0, (now - game.timer_started_at) // timedelta(milliseconds=1))
    return total


def is_paused(game: GameSession) -> bool:
    return game.status == IN_PROGRESS and game.timer_started_at is None


def _end_in_eruption(game: GameSession, finished_at: datetime) -> None:
    game.status = GAME_OVER
    game.elapsed_seconds = get_settings().game_duration_seconds
    game.timer_started_at = None
    game.finished_at = finished_at


def refresh_timer(game: GameSession, now: datetime) -> bool:
    """Passe la partie en game_over si son temps est écoulé. Renvoie True si elle a changé."""
    duration = get_settings().game_duration_seconds
    if game.status != IN_PROGRESS or elapsed_ms(game, now) < duration * 1000:
        return False
    finished_at = now
    if game.timer_started_at is not None and game.elapsed_seconds < duration:
        # Heure exacte de l'éruption, même si la partie n'est relue que bien plus tard.
        finished_at = min(now, game.timer_started_at + timedelta(seconds=duration - game.elapsed_seconds))
    _end_in_eruption(game, finished_at)
    return True


def _stop_timer(game: GameSession, now: datetime) -> None:
    duration = get_settings().game_duration_seconds
    game.elapsed_seconds = min(_ceil_div(elapsed_ms(game, now), 1000), duration)
    game.timer_started_at = None


# --- Lecture ---------------------------------------------------------------------------------------

def _untimed_game_ids(db: Session, game_ids: list[int]) -> set[int]:
    """Parties dont au moins une résolution n'a pas de temps fiable : elles ne sont pas classées."""
    if not game_ids:
        return set()
    return set(
        db.scalars(
            select(PuzzleProgress.id_game_sessions)
            .where(
                PuzzleProgress.id_game_sessions.in_(game_ids),
                PuzzleProgress.solved_at.is_not(None),
                PuzzleProgress.completion_time_ms.is_(None),
            )
            .distinct()
        )
    )


def to_read(game: GameSession, now: datetime, *, untimed: bool) -> GameSessionRead:
    duration = get_settings().game_duration_seconds
    elapsed = min(elapsed_ms(game, now), duration * 1000) / 1000
    return GameSessionRead(
        id_game_sessions=game.id_game_sessions,
        status=game.status,
        current_level=game.current_level,
        position_x=game.position_x,
        position_y=game.position_y,
        position_z=game.position_z,
        rotation_y=game.rotation_y,
        started_at=game.started_at,
        last_saved_at=game.last_saved_at,
        finished_at=game.finished_at,
        elapsed_seconds=elapsed,
        remaining_seconds=max(0.0, duration - elapsed) if game.status == IN_PROGRESS else 0.0,
        duration_seconds=duration,
        is_paused=is_paused(game),
        is_rankable=game.status in (IN_PROGRESS, COMPLETED) and not untimed,
    )


def read_game(db: Session, game: GameSession, now: datetime) -> GameSessionRead:
    return to_read(game, now, untimed=game.id_game_sessions in _untimed_game_ids(db, [game.id_game_sessions]))


def read_games(db: Session, games: list[GameSession], now: datetime) -> list[GameSessionRead]:
    untimed = _untimed_game_ids(db, [game.id_game_sessions for game in games])
    return [to_read(game, now, untimed=game.id_game_sessions in untimed) for game in games]


def get_owned_game(db: Session, user: User, game_id: int, *, lock: bool = False) -> GameSession:
    """Partie du joueur. Celle d'un autre joueur répond 404, pour ne pas révéler qu'elle existe."""
    statement = select(GameSession).where(
        GameSession.id_game_sessions == game_id, GameSession.id_users == user.id_users
    )
    if lock:
        statement = statement.with_for_update()
    game = db.scalars(statement).one_or_none()
    if game is None:
        raise NotFoundError("Partie introuvable.")
    return game


def get_game(db: Session, user: User, game_id: int, now: datetime) -> GameSession:
    game = get_owned_game(db, user, game_id, lock=True)
    if refresh_timer(game, now):
        db.commit()
    return game


def load_active_game(db: Session, user: User, game_id: int, now: datetime, *, require_running: bool) -> GameSession:
    """Partie verrouillée pour une écriture, après contrôle du chronomètre et de son état."""
    game = get_owned_game(db, user, game_id, lock=True)
    if refresh_timer(game, now):
        db.commit()
        raise ConflictError(TIME_UP)
    if game.status != IN_PROGRESS:
        raise ConflictError(f"La partie est terminée (statut : {game.status}) et ne peut plus être modifiée.")
    if require_running and game.timer_started_at is None:
        raise ConflictError(PAUSED)
    return game


def _refresh_active_games(db: Session, user: User, now: datetime) -> list[GameSession]:
    """Met à jour le chronomètre des parties en cours du joueur et renvoie celles qui le restent."""
    games = db.scalars(
        select(GameSession)
        .where(GameSession.id_users == user.id_users, GameSession.status == IN_PROGRESS)
        .with_for_update()
    ).all()
    return [game for game in games if not refresh_timer(game, now)]


def _ensure_no_active_game(db: Session, user: User, now: datetime) -> None:
    # Le verrou sur le joueur sérialise deux créations simultanées.
    db.execute(select(User.id_users).where(User.id_users == user.id_users).with_for_update())
    active = _refresh_active_games(db, user, now)
    if active:
        db.commit()
        raise ConflictError(
            f"Une partie est déjà en cours (id_game_sessions={active[0].id_game_sessions}) : "
            "reprenez-la ou abandonnez-la avant d'en commencer une autre."
        )


def list_games(
    db: Session, user: User, now: datetime, *, status: str | None, limit: int, offset: int
) -> tuple[list[GameSession], int]:
    _refresh_active_games(db, user, now)
    db.commit()

    conditions = [GameSession.id_users == user.id_users]
    if status is not None:
        conditions.append(GameSession.status == status)
    total = db.scalar(select(func.count()).select_from(GameSession).where(*conditions))
    games = db.scalars(
        select(GameSession)
        .where(*conditions)
        .order_by(GameSession.started_at.desc(), GameSession.id_game_sessions.desc())
        .limit(limit)
        .offset(offset)
    ).all()
    return list(games), total


# --- Écriture --------------------------------------------------------------------------------------

def create_game(db: Session, user: User, data: GameSessionCreate, now: datetime) -> GameSession:
    _ensure_no_active_game(db, user, now)
    game = GameSession(
        id_users=user.id_users,
        status=IN_PROGRESS,
        elapsed_seconds=0,
        current_level=data.current_level,
        position_x=data.position_x,
        position_y=data.position_y,
        position_z=data.position_z,
        rotation_y=data.rotation_y,
        started_at=now,
        last_saved_at=now,
        timer_started_at=now,
    )
    db.add(game)
    db.commit()
    return game


def save_game(db: Session, user: User, game_id: int, data: GameSessionUpdate, now: datetime) -> GameSession:
    game = load_active_game(db, user, game_id, now, require_running=False)
    for field in data.model_fields_set:
        setattr(game, field, getattr(data, field))
    game.last_saved_at = now
    db.commit()
    return game


def pause_game(db: Session, user: User, game_id: int, now: datetime) -> GameSession:
    game = load_active_game(db, user, game_id, now, require_running=False)
    if game.timer_started_at is None:
        raise ConflictError("La partie est déjà en pause.")
    _stop_timer(game, now)
    refresh_timer(game, now)
    db.commit()
    return game


def resume_game(db: Session, user: User, game_id: int, now: datetime) -> GameSession:
    game = load_active_game(db, user, game_id, now, require_running=False)
    if game.timer_started_at is not None:
        raise ConflictError("La partie n'est pas en pause.")
    game.timer_started_at = now
    db.commit()
    return game


def penalize_game(db: Session, user: User, game_id: int, now: datetime) -> GameSession:
    settings = get_settings()
    game = load_active_game(db, user, game_id, now, require_running=False)
    game.elapsed_seconds += settings.penalty_seconds
    if elapsed_ms(game, now) >= settings.game_duration_seconds * 1000:
        # La pénalité épuise le temps : l'éruption a lieu maintenant, pas avant la pénalité.
        _end_in_eruption(game, now)
    db.commit()
    return game


def abandon_game(db: Session, user: User, game_id: int, now: datetime) -> GameSession:
    game = load_active_game(db, user, game_id, now, require_running=False)
    _stop_timer(game, now)
    game.status = ABANDONED
    game.finished_at = now
    db.commit()
    return game


def complete_game(db: Session, user: User, game_id: int, placed_puzzle_ids: list[int], now: datetime) -> GameSession:
    """Victoire : toutes les énigmes résolues côté serveur et tous les livres déclarés posés."""
    game = load_active_game(db, user, game_id, now, require_running=True)

    all_ids = set(db.scalars(select(Puzzle.id_puzzles)))
    if not all_ids:
        raise ConflictError("Aucune énigme n'est configurée sur le serveur.")
    unknown = set(placed_puzzle_ids) - all_ids
    if unknown:
        raise UnprocessableError(f"Énigmes inconnues : {sorted(unknown)}.")

    solved_ids = set(
        db.scalars(
            select(PuzzleProgress.id_puzzles).where(
                PuzzleProgress.id_game_sessions == game.id_game_sessions,
                PuzzleProgress.solved_at.is_not(None),
            )
        )
    )
    if solved_ids != all_ids:
        raise ConflictError(
            f"Toutes les énigmes doivent être résolues avant la victoire ({len(solved_ids)}/{len(all_ids)})."
        )
    if set(placed_puzzle_ids) != all_ids:
        raise ConflictError(
            f"Les {len(all_ids)} livres doivent être posés au château "
            f"({len(placed_puzzle_ids)}/{len(all_ids)} indiqués)."
        )

    _stop_timer(game, now)
    game.status = COMPLETED
    game.finished_at = now
    db.commit()
    return game


def import_game(db: Session, user: User, data: GameImportRequest, now: datetime) -> GameSession:
    """Rattache au compte la progression d'un invité, jouée hors du contrôle du serveur.

    Les données sont vérifiées pour leur cohérence, mais rien ne prouve qu'elles sont authentiques :
    les résolutions importées n'ont pas de temps (`completion_time_ms` NULL), si bien que la partie
    n'apparaît jamais dans les classements. Une partie en cours est importée en pause.
    """
    settings = get_settings()
    duration = settings.game_duration_seconds
    puzzles = db.scalars(select(Puzzle).order_by(Puzzle.order_index)).all()
    by_id = {puzzle.id_puzzles: puzzle for puzzle in puzzles}

    for item in data.solved_puzzles:
        puzzle = by_id.get(item.id_puzzles)
        if puzzle is None:
            raise UnprocessableError(f"Énigme inconnue : {item.id_puzzles}.")
        if item.hints_used > puzzle.hint_count:
            raise UnprocessableError(
                f"Trop d'indices pour l'énigme {item.id_puzzles} ({item.hints_used}/{puzzle.hint_count})."
            )
    solved_ids = {item.id_puzzles for item in data.solved_puzzles}
    if solved_ids != {puzzle.id_puzzles for puzzle in puzzles[: len(solved_ids)]}:
        raise UnprocessableError("Les énigmes se résolvent dans l'ordre : la progression importée est incohérente.")

    elapsed = data.elapsed_seconds
    if elapsed > duration:
        raise UnprocessableError(f"Le temps consommé ne peut pas dépasser {duration} secondes.")
    if data.status == IN_PROGRESS and elapsed >= duration:
        raise UnprocessableError("Une partie en cours doit avoir du temps restant.")
    if data.status == GAME_OVER and elapsed < duration:
        raise UnprocessableError("Une partie perdue a forcément consommé tout son temps.")
    if data.status == COMPLETED:
        if not puzzles or len(solved_ids) != len(puzzles):
            raise UnprocessableError("Une partie gagnée doit avoir toutes ses énigmes résolues.")
        if elapsed < len(puzzles) * settings.puzzle_min_solve_seconds:
            raise UnprocessableError("Temps total invraisemblable pour une partie gagnée.")

    if data.status == IN_PROGRESS:
        _ensure_no_active_game(db, user, now)

    game = GameSession(
        id_users=user.id_users,
        status=data.status,
        elapsed_seconds=min(_ceil_div(round(elapsed * 1000), 1000), duration),
        current_level=data.current_level,
        position_x=data.position_x,
        position_y=data.position_y,
        position_z=data.position_z,
        rotation_y=data.rotation_y,
        started_at=now,
        last_saved_at=now,
        finished_at=None if data.status == IN_PROGRESS else now,
        timer_started_at=None,
    )
    db.add(game)
    db.flush()
    for item in data.solved_puzzles:
        db.add(
            PuzzleProgress(
                id_game_sessions=game.id_game_sessions,
                id_puzzles=item.id_puzzles,
                solved_at=now,
                completion_time_ms=None,
                hints_used=item.hints_used,
            )
        )
    db.commit()
    return game
