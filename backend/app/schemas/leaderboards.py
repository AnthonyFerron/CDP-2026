from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import Page
from app.schemas.puzzles import PuzzleRead


class LeaderboardEntry(BaseModel):
    rank: int = Field(description="Position. Deux temps égaux partagent la même position.")
    username: str
    elapsed_seconds: int = Field(description="Temps total de la partie, pauses exclues, pénalités incluses.")
    time_formatted: str = Field(examples=["42:07"], description="Temps au format MM:SS.")
    finished_at: datetime


class PuzzleLeaderboardEntry(BaseModel):
    rank: int
    username: str
    completion_time_ms: int
    time_formatted: str = Field(examples=["03:12.480"], description="Temps au format MM:SS.mmm.")
    solved_at: datetime


class LeaderboardPage(Page[LeaderboardEntry]):
    pass


class PuzzleLeaderboardPage(Page[PuzzleLeaderboardEntry]):
    puzzle: PuzzleRead
