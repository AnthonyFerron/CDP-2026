from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.models.paper_fragment import PAPER_FRAGMENT_COUNT, PaperFragment
from app.models.puzzle import Puzzle
from app.models.puzzle_progress import PuzzleProgress
from app.schemas.common import DbId
from app.schemas.game_sessions import GameStatus


class PuzzleRead(BaseModel):
    id_puzzles: int
    title: str
    order_index: int = Field(description="Ordre de l'énigme : 1 Plaine, 2 Désert, 3 Marais, 4 Village.")

    @classmethod
    def from_model(cls, puzzle: Puzzle) -> "PuzzleRead":
        return cls(id_puzzles=puzzle.id_puzzles, title=puzzle.title, order_index=puzzle.order_index)


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
    is_placed: bool = Field(description="Vrai si le livre est posé sur son piédestal, au château.")
    placed_at: datetime | None

    @classmethod
    def from_model(cls, progress: PuzzleProgress) -> "PuzzleProgressRead":
        return cls(
            id_puzzle_progress=progress.id_puzzle_progress,
            id_game_sessions=progress.id_game_sessions,
            id_puzzles=progress.id_puzzles,
            is_solved=progress.solved_at is not None,
            solved_at=progress.solved_at,
            completion_time_ms=progress.completion_time_ms,
            is_placed=progress.placed_at is not None,
            placed_at=progress.placed_at,
        )


class PuzzleState(BaseModel):
    id_puzzles: int
    title: str
    order_index: int
    is_unlocked: bool = Field(description="Vrai si l'énigme précédente est résolue (ou si c'est la première).")
    id_puzzle_progress: int | None = Field(description="Null tant que l'énigme n'a pas été commencée.")
    is_started: bool
    is_solved: bool = Field(description="Vrai si le livre de cette énigme est obtenu.")
    solved_at: datetime | None
    completion_time_ms: int | None
    is_placed: bool = Field(description="Vrai si le livre est posé au château.")
    placed_at: datetime | None


class PaperFragmentCollect(BaseModel):
    model_config = ConfigDict(extra="forbid", json_schema_extra={"examples": [{"fragment_index": 3}]})

    fragment_index: int = Field(
        ge=0,
        lt=PAPER_FRAGMENT_COUNT,
        description="Numéro du fragment, de 0 à 9 : `PaperFragment.fragment` dans Godot.",
    )


class PaperFragmentRead(BaseModel):
    fragment_index: int
    collected_at: datetime

    @classmethod
    def from_model(cls, fragment: PaperFragment) -> "PaperFragmentRead":
        return cls(fragment_index=fragment.fragment_index, collected_at=fragment.collected_at)


class GameProgressRead(BaseModel):
    id_game_sessions: int
    status: GameStatus
    is_paused: bool
    elapsed_seconds: float
    remaining_seconds: float
    duration_seconds: int
    books_obtained: int = Field(description="Nombre d'énigmes résolues, donc de livres obtenus.")
    books_placed: int = Field(description="Nombre de livres posés au château.")
    total_books: int
    can_complete: bool = Field(
        description="Vrai si tous les livres sont posés et la partie active : il reste à appeler POST /completions."
    )
    collected_fragments: list[int] = Field(
        description="Numéros des fragments de papier ramassés (énigme du Village), triés."
    )
    total_fragments: int = Field(description="Nombre de fragments à trouver.")
    puzzles: list[PuzzleState]
