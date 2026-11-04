from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.models.puzzle import Puzzle
from app.models.puzzle_progress import PuzzleProgress
from app.schemas.common import DbId
from app.schemas.game_sessions import GameStatus


class PuzzleRead(BaseModel):
    id_puzzles: int
    title: str
    order_index: int = Field(description="Ordre de l'énigme : 1 Plaine, 2 Désert, 3 Marais, 4 Village.")
    hints_count: int = Field(description="Nombre d'indices disponibles (colonne `hint_count` en base).")

    @classmethod
    def from_model(cls, puzzle: Puzzle) -> "PuzzleRead":
        return cls(
            id_puzzles=puzzle.id_puzzles,
            title=puzzle.title,
            order_index=puzzle.order_index,
            hints_count=puzzle.hint_count,
        )


class PuzzleProgressStart(BaseModel):
    model_config = ConfigDict(extra="forbid", json_schema_extra={"examples": [{"id_puzzles": 1}]})

    id_puzzles: DbId


class PuzzleProgressUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid", json_schema_extra={"examples": [{"solved": True}]})

    solved: Literal[True] = Field(description="Seule transition autorisée : énigme non résolue → résolue.")


class PuzzleProgressRead(BaseModel):
    id_puzzle_progress: int
    id_game_sessions: int
    id_puzzles: int
    is_solved: bool = Field(description="Vrai si l'énigme est résolue, donc si le livre est obtenu.")
    solved_at: datetime | None
    completion_time_ms: int | None = Field(
        description="Temps de jeu entre la résolution précédente (ou le début de la partie) et celle-ci, "
        "mesuré par le serveur. Null si la mesure n'est pas fiable (import, résolution invraisemblable)."
    )
    hints_used: int
    hints_remaining: int

    @classmethod
    def from_model(cls, progress: PuzzleProgress, puzzle: Puzzle) -> "PuzzleProgressRead":
        return cls(
            id_puzzle_progress=progress.id_puzzle_progress,
            id_game_sessions=progress.id_game_sessions,
            id_puzzles=progress.id_puzzles,
            is_solved=progress.solved_at is not None,
            solved_at=progress.solved_at,
            completion_time_ms=progress.completion_time_ms,
            hints_used=progress.hints_used,
            hints_remaining=max(0, puzzle.hint_count - progress.hints_used),
        )


class PuzzleState(BaseModel):
    id_puzzles: int
    title: str
    order_index: int
    hints_count: int
    is_unlocked: bool = Field(description="Vrai si l'énigme précédente est résolue (ou si c'est la première).")
    id_puzzle_progress: int | None = Field(description="Null tant que l'énigme n'a pas été commencée.")
    is_started: bool
    is_solved: bool = Field(description="Vrai si le livre de cette énigme est obtenu.")
    solved_at: datetime | None
    completion_time_ms: int | None
    hints_used: int
    hints_remaining: int


class GameProgressRead(BaseModel):
    id_game_sessions: int
    status: GameStatus
    is_paused: bool
    elapsed_seconds: float
    remaining_seconds: float
    duration_seconds: int
    books_obtained: int = Field(description="Nombre d'énigmes résolues, donc de livres obtenus.")
    total_books: int
    can_complete: bool = Field(
        description="Vrai si toutes les énigmes sont résolues et la partie active : il reste à poser les livres "
        "puis à appeler POST /completions."
    )
    puzzles: list[PuzzleState]
