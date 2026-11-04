
from datetime import datetime

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Integer,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class PuzzleProgress(Base):
    __tablename__ = "puzzle_progress"

    __table_args__ = (
        UniqueConstraint(
            "id_game_sessions",
            "id_puzzles",
            name="uq_puzzle_progress_game_puzzle"
        ),
        CheckConstraint(
            "hints_used >= 0",
            name="ck_puzzle_progress_hints_used"
        ),
        CheckConstraint(
            "completion_time_ms > 0",
            name="ck_puzzle_progress_completion_time"
        ),
        # Un livre ne se pose au château qu'une fois son énigme résolue.
        CheckConstraint(
            "placed_at IS NULL OR (solved_at IS NOT NULL AND placed_at >= solved_at)",
            name="ck_puzzle_progress_placed_after_solved"
        ),
    )

    id_puzzle_progress: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    id_game_sessions: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("game_sessions.id_game_sessions"),
        nullable=False
    )

    id_puzzles: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("puzzles.id_puzzles"),
        nullable=False
    )

    solved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    completion_time_ms: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True
    )

    # Colonne conservée sans être utilisée : les indices des énigmes sont gérés dans Godot.
    hints_used: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    # Date à laquelle le livre de l'énigme a été posé sur son piédestal, au château.
    placed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )
