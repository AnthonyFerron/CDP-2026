"""Progression des énigmes d'une partie.

Un livre est obtenu quand son énigme est résolue : `puzzle_progress.solved_at IS NOT NULL`.

Le temps d'une résolution (`completion_time_ms`) est mesuré par le serveur : c'est le temps de jeu
(pauses exclues, pénalités incluses) écoulé depuis la résolution précédente, ou depuis le début de la
partie pour la première énigme. Le client n'envoie jamais de durée.

Le serveur ne peut pas vérifier qu'une énigme a réellement été résolue : la logique des énigmes vit
dans Godot et leurs solutions sont publiques. Il garantit en revanche l'ordre des énigmes, l'unicité
des résolutions, la mesure du temps et le respect du chronomètre. Une résolution plus rapide que
`PUZZLE_MIN_SOLVE_SECONDS` est acceptée (le jeu continue) mais sans temps : la partie sort du classement.
"""

from datetime import datetime

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.errors import ConflictError, NotFoundError, UnprocessableError
from app.models.game_session import GameSession
from app.models.puzzle import Puzzle
from app.models.puzzle_progress import PuzzleProgress
from app.models.user import User
from app.schemas.puzzles import GameProgressRead, PuzzleState
from app.services.game_sessions import (
    IN_PROGRESS,
    elapsed_ms,
    get_game,
    is_paused,
    load_active_game,
    to_read,
)


def list_puzzles(db: Session) -> list[Puzzle]:
    return list(db.scalars(select(Puzzle).order_by(Puzzle.order_index)))


def get_puzzle(db: Session, puzzle_id: int) -> Puzzle:
    puzzle = db.get(Puzzle, puzzle_id)
    if puzzle is None:
        raise NotFoundError("Énigme introuvable.")
    return puzzle


def _progress_rows(db: Session, game: GameSession) -> list[PuzzleProgress]:
    return list(
        db.scalars(
            select(PuzzleProgress)
            .where(PuzzleProgress.id_game_sessions == game.id_game_sessions)
            .order_by(PuzzleProgress.id_puzzle_progress)
        )
    )


def _check_unlocked(db: Session, game: GameSession, puzzle: Puzzle) -> None:
    previous = db.scalars(
        select(Puzzle)
        .where(Puzzle.order_index < puzzle.order_index)
        .order_by(Puzzle.order_index.desc())
        .limit(1)
    ).first()
    if previous is None:
        return
    solved = db.scalar(
        select(PuzzleProgress.id_puzzle_progress).where(
            PuzzleProgress.id_game_sessions == game.id_game_sessions,
            PuzzleProgress.id_puzzles == previous.id_puzzles,
            PuzzleProgress.solved_at.is_not(None),
        )
    )
    if solved is None:
        raise ConflictError(f"Énigme verrouillée : résolvez d'abord « {previous.title} ».")


def _get_progress(db: Session, game: GameSession, progress_id: int) -> PuzzleProgress:
    progress = db.scalars(
        select(PuzzleProgress)
        .where(
            PuzzleProgress.id_puzzle_progress == progress_id,
            PuzzleProgress.id_game_sessions == game.id_game_sessions,
        )
        .with_for_update()
    ).one_or_none()
    if progress is None:
        raise NotFoundError("Progression introuvable pour cette partie.")
    return progress


def list_progress(db: Session, user: User, game_id: int, now: datetime) -> list[tuple[PuzzleProgress, Puzzle]]:
    game = get_game(db, user, game_id, now)
    puzzles = {puzzle.id_puzzles: puzzle for puzzle in list_puzzles(db)}
    return [(row, puzzles[row.id_puzzles]) for row in _progress_rows(db, game)]


def start_puzzle(
    db: Session, user: User, game_id: int, puzzle_id: int, now: datetime
) -> tuple[PuzzleProgress, Puzzle, bool]:
    """Commence une énigme. Idempotent : renvoie la progression existante si elle a déjà commencé."""
    game = load_active_game(db, user, game_id, now, require_running=True)
    puzzle = db.get(Puzzle, puzzle_id)
    if puzzle is None:
        raise UnprocessableError(f"Énigme inconnue : {puzzle_id}.")

    existing = db.scalars(
        select(PuzzleProgress).where(
            PuzzleProgress.id_game_sessions == game.id_game_sessions,
            PuzzleProgress.id_puzzles == puzzle_id,
        )
    ).one_or_none()
    if existing is not None:
        return existing, puzzle, False

    _check_unlocked(db, game, puzzle)
    progress = PuzzleProgress(id_game_sessions=game.id_game_sessions, id_puzzles=puzzle_id, hints_used=0)
    db.add(progress)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        existing = db.scalars(
            select(PuzzleProgress).where(
                PuzzleProgress.id_game_sessions == game_id,
                PuzzleProgress.id_puzzles == puzzle_id,
            )
        ).one()
        return existing, puzzle, False
    return progress, puzzle, True


def _split_ms(game: GameSession, previous_times: list[int | None], now: datetime) -> int | None:
    if any(time is None for time in previous_times):
        # Une résolution précédente n'a pas de temps fiable : plus de référence pour mesurer celle-ci.
        return None
    split = elapsed_ms(game, now) - sum(previous_times)
    if split < get_settings().puzzle_min_solve_seconds * 1000:
        return None
    return max(1, split)


def solve_puzzle(db: Session, user: User, game_id: int, progress_id: int, now: datetime) -> tuple[PuzzleProgress, Puzzle]:
    game = load_active_game(db, user, game_id, now, require_running=True)
    progress = _get_progress(db, game, progress_id)
    puzzle = db.get(Puzzle, progress.id_puzzles)
    if progress.solved_at is not None:
        raise ConflictError("Cette énigme est déjà résolue : son livre est déjà obtenu.")
    _check_unlocked(db, game, puzzle)

    previous_times = list(
        db.scalars(
            select(PuzzleProgress.completion_time_ms).where(
                PuzzleProgress.id_game_sessions == game.id_game_sessions,
                PuzzleProgress.solved_at.is_not(None),
            )
        )
    )
    progress.completion_time_ms = _split_ms(game, previous_times, now)
    progress.solved_at = now
    db.commit()
    return progress, puzzle


def use_hint(db: Session, user: User, game_id: int, progress_id: int, now: datetime) -> tuple[PuzzleProgress, Puzzle]:
    game = load_active_game(db, user, game_id, now, require_running=True)
    progress = _get_progress(db, game, progress_id)
    puzzle = db.get(Puzzle, progress.id_puzzles)
    if progress.solved_at is not None:
        raise ConflictError("Cette énigme est déjà résolue : plus besoin d'indice.")
    if progress.hints_used >= puzzle.hint_count:
        raise ConflictError("Plus aucun indice disponible pour cette énigme.")
    progress.hints_used += 1
    db.commit()
    return progress, puzzle


def game_progress(db: Session, user: User, game_id: int, now: datetime) -> GameProgressRead:
    game = get_game(db, user, game_id, now)
    puzzles = list_puzzles(db)
    rows = {row.id_puzzles: row for row in _progress_rows(db, game)}
    solved = {puzzle_id for puzzle_id, row in rows.items() if row.solved_at is not None}

    states = []
    for index, puzzle in enumerate(puzzles):
        row = rows.get(puzzle.id_puzzles)
        hints_used = row.hints_used if row else 0
        states.append(
            PuzzleState(
                id_puzzles=puzzle.id_puzzles,
                title=puzzle.title,
                order_index=puzzle.order_index,
                hints_count=puzzle.hint_count,
                is_unlocked=index == 0 or puzzles[index - 1].id_puzzles in solved,
                id_puzzle_progress=row.id_puzzle_progress if row else None,
                is_started=row is not None,
                is_solved=puzzle.id_puzzles in solved,
                solved_at=row.solved_at if row else None,
                completion_time_ms=row.completion_time_ms if row else None,
                hints_used=hints_used,
                hints_remaining=max(0, puzzle.hint_count - hints_used),
            )
        )

    timer = to_read(game, now, untimed=False)
    return GameProgressRead(
        id_game_sessions=game.id_game_sessions,
        status=game.status,
        is_paused=is_paused(game),
        elapsed_seconds=timer.elapsed_seconds,
        remaining_seconds=timer.remaining_seconds,
        duration_seconds=timer.duration_seconds,
        books_obtained=len(solved),
        total_books=len(puzzles),
        can_complete=game.status == IN_PROGRESS and bool(puzzles) and len(solved) == len(puzzles),
        puzzles=states,
    )
