"""Progression des énigmes d'une partie : résolutions, livres posés au château, fragments de papier.

Un livre est obtenu quand son énigme est résolue (`puzzle_progress.solved_at`), puis posé au château
(`puzzle_progress.placed_at`). Les indices des énigmes vivent dans Godot et ne sont pas suivis ici ;
seuls les fragments de papier du Village, des objets à ramasser, sont sauvegardés (`paper_fragments`).

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
from app.models.paper_fragment import PAPER_FRAGMENT_COUNT, PAPER_FRAGMENT_PUZZLE_ORDER, PaperFragment
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


def list_progress(db: Session, user: User, game_id: int, now: datetime) -> list[PuzzleProgress]:
    return _progress_rows(db, get_game(db, user, game_id, now))


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
    progress = PuzzleProgress(id_game_sessions=game.id_game_sessions, id_puzzles=puzzle_id)
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


def solve_puzzle(db: Session, user: User, game_id: int, progress_id: int, now: datetime) -> PuzzleProgress:
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
    return progress


def place_book(db: Session, user: User, game_id: int, progress_id: int, now: datetime) -> PuzzleProgress:
    """Pose le livre d'une énigme résolue sur son piédestal, une seule fois."""
    game = load_active_game(db, user, game_id, now, require_running=True)
    progress = _get_progress(db, game, progress_id)
    if progress.solved_at is None:
        puzzle = db.get(Puzzle, progress.id_puzzles)
        raise ConflictError(f"Livre non obtenu : résolvez d'abord « {puzzle.title} ».")
    if progress.placed_at is not None:
        raise ConflictError("Ce livre est déjà posé au château.")
    progress.placed_at = now
    db.commit()
    return progress


def _fragment_puzzle(db: Session) -> Puzzle:
    puzzle = db.scalars(select(Puzzle).where(Puzzle.order_index == PAPER_FRAGMENT_PUZZLE_ORDER)).one_or_none()
    if puzzle is None:
        raise ConflictError("L'énigme du Village n'est pas configurée sur le serveur.")
    return puzzle


def list_fragments(db: Session, user: User, game_id: int, now: datetime) -> list[PaperFragment]:
    game = get_game(db, user, game_id, now)
    return _fragment_rows(db, game)


def _fragment_rows(db: Session, game: GameSession) -> list[PaperFragment]:
    return list(
        db.scalars(
            select(PaperFragment)
            .where(PaperFragment.id_game_sessions == game.id_game_sessions)
            .order_by(PaperFragment.fragment_index)
        )
    )


def collect_fragment(db: Session, user: User, game_id: int, fragment_index: int, now: datetime) -> PaperFragment:
    """Ramasse un fragment de papier. Chacun des 10 fragments ne se ramasse qu'une fois par partie."""
    if not 0 <= fragment_index < PAPER_FRAGMENT_COUNT:
        raise UnprocessableError(f"Fragment inconnu : {fragment_index}.")
    game = load_active_game(db, user, game_id, now, require_running=True)
    _check_unlocked(db, game, _fragment_puzzle(db))

    already = db.scalar(
        select(PaperFragment.id_paper_fragments).where(
            PaperFragment.id_game_sessions == game.id_game_sessions,
            PaperFragment.fragment_index == fragment_index,
        )
    )
    if already is not None:
        raise ConflictError(f"Le fragment {fragment_index} est déjà ramassé.")

    fragment = PaperFragment(id_game_sessions=game.id_game_sessions, fragment_index=fragment_index, collected_at=now)
    db.add(fragment)
    try:
        db.commit()
    except IntegrityError:
        # Deux ramassages simultanés du même fragment : la contrainte unique tranche.
        db.rollback()
        raise ConflictError(f"Le fragment {fragment_index} est déjà ramassé.") from None
    return fragment


def game_progress(db: Session, user: User, game_id: int, now: datetime) -> GameProgressRead:
    game = get_game(db, user, game_id, now)
    puzzles = list_puzzles(db)
    rows = {row.id_puzzles: row for row in _progress_rows(db, game)}
    solved = {puzzle_id for puzzle_id, row in rows.items() if row.solved_at is not None}

    placed = {puzzle_id for puzzle_id, row in rows.items() if row.placed_at is not None}

    states = []
    for index, puzzle in enumerate(puzzles):
        row = rows.get(puzzle.id_puzzles)
        states.append(
            PuzzleState(
                id_puzzles=puzzle.id_puzzles,
                title=puzzle.title,
                order_index=puzzle.order_index,
                is_unlocked=index == 0 or puzzles[index - 1].id_puzzles in solved,
                id_puzzle_progress=row.id_puzzle_progress if row else None,
                is_started=row is not None,
                is_solved=puzzle.id_puzzles in solved,
                solved_at=row.solved_at if row else None,
                completion_time_ms=row.completion_time_ms if row else None,
                is_placed=puzzle.id_puzzles in placed,
                placed_at=row.placed_at if row else None,
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
        books_placed=len(placed),
        total_books=len(puzzles),
        can_complete=game.status == IN_PROGRESS and bool(puzzles) and len(placed) == len(puzzles),
        collected_fragments=[fragment.fragment_index for fragment in _fragment_rows(db, game)],
        total_fragments=PAPER_FRAGMENT_COUNT,
        puzzles=states,
    )
