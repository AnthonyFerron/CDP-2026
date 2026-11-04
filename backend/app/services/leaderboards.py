"""Classements publics : une ligne par joueur, avec son meilleur résultat.

Seules les parties `completed` dont le déroulement a été entièrement chronométré par le serveur
comptent : toutes leurs énigmes ont un `completion_time_ms`. Les parties perdues, abandonnées ou
importées en sont exclues.

Égalités : deux temps égaux partagent le même rang (1, 2, 2, 4). L'ordre d'affichage reste
déterministe : à temps égal, le premier à avoir réalisé le temps passe devant.
"""

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.game_session import GameSession
from app.models.puzzle import Puzzle
from app.models.puzzle_progress import PuzzleProgress
from app.models.user import User
from app.schemas.leaderboards import LeaderboardEntry, PuzzleLeaderboardEntry
from app.services.game_sessions import COMPLETED


def format_seconds(seconds: int) -> str:
    minutes, seconds = divmod(seconds, 60)
    return f"{minutes:02d}:{seconds:02d}"


def format_ms(milliseconds: int) -> str:
    seconds, ms = divmod(milliseconds, 1000)
    return f"{format_seconds(seconds)}.{ms:03d}"


def general_leaderboard(db: Session, limit: int, offset: int) -> tuple[list[LeaderboardEntry], int]:
    total_puzzles = db.scalar(select(func.count()).select_from(Puzzle))
    if not total_puzzles:
        return [], 0

    fully_timed = (
        select(PuzzleProgress.id_game_sessions)
        .where(PuzzleProgress.solved_at.is_not(None), PuzzleProgress.completion_time_ms.is_not(None))
        .group_by(PuzzleProgress.id_game_sessions)
        .having(func.count() == total_puzzles)
    )
    best = (
        select(
            GameSession.id_game_sessions,
            GameSession.id_users,
            GameSession.elapsed_seconds,
            GameSession.finished_at,
            func.row_number()
            .over(
                partition_by=GameSession.id_users,
                order_by=(GameSession.elapsed_seconds, GameSession.finished_at, GameSession.id_game_sessions),
            )
            .label("best_rank"),
        )
        .where(GameSession.status == COMPLETED, GameSession.id_game_sessions.in_(fully_timed))
        .subquery()
    )
    ranked = (
        select(
            best.c.id_game_sessions,
            best.c.elapsed_seconds,
            best.c.finished_at,
            User.username,
            func.rank().over(order_by=best.c.elapsed_seconds).label("rank"),
        )
        .join(User, User.id_users == best.c.id_users)
        .where(best.c.best_rank == 1)
        .subquery()
    )

    total = db.scalar(select(func.count()).select_from(ranked))
    rows = db.execute(
        select(ranked)
        .order_by(ranked.c.rank, ranked.c.finished_at, ranked.c.id_game_sessions)
        .limit(limit)
        .offset(offset)
    ).all()
    entries = [
        LeaderboardEntry(
            rank=row.rank,
            username=row.username,
            elapsed_seconds=row.elapsed_seconds,
            time_formatted=format_seconds(row.elapsed_seconds),
            finished_at=row.finished_at,
        )
        for row in rows
    ]
    return entries, total


def puzzle_leaderboard(db: Session, puzzle: Puzzle, limit: int, offset: int) -> tuple[list[PuzzleLeaderboardEntry], int]:
    best = (
        select(
            PuzzleProgress.id_puzzle_progress,
            PuzzleProgress.completion_time_ms,
            PuzzleProgress.solved_at,
            GameSession.id_users,
            func.row_number()
            .over(
                partition_by=GameSession.id_users,
                order_by=(
                    PuzzleProgress.completion_time_ms,
                    PuzzleProgress.solved_at,
                    PuzzleProgress.id_puzzle_progress,
                ),
            )
            .label("best_rank"),
        )
        .join(GameSession, GameSession.id_game_sessions == PuzzleProgress.id_game_sessions)
        .where(
            PuzzleProgress.id_puzzles == puzzle.id_puzzles,
            PuzzleProgress.solved_at.is_not(None),
            PuzzleProgress.completion_time_ms.is_not(None),
            GameSession.status == COMPLETED,
        )
        .subquery()
    )
    ranked = (
        select(
            best.c.id_puzzle_progress,
            best.c.completion_time_ms,
            best.c.solved_at,
            User.username,
            func.rank().over(order_by=best.c.completion_time_ms).label("rank"),
        )
        .join(User, User.id_users == best.c.id_users)
        .where(best.c.best_rank == 1)
        .subquery()
    )

    total = db.scalar(select(func.count()).select_from(ranked))
    rows = db.execute(
        select(ranked)
        .order_by(ranked.c.rank, ranked.c.solved_at, ranked.c.id_puzzle_progress)
        .limit(limit)
        .offset(offset)
    ).all()
    entries = [
        PuzzleLeaderboardEntry(
            rank=row.rank,
            username=row.username,
            completion_time_ms=row.completion_time_ms,
            time_formatted=format_ms(row.completion_time_ms),
            solved_at=row.solved_at,
        )
        for row in rows
    ]
    return entries, total
