
from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base

# Les fragments de papier cachés dans la mairie, pour l'énigme du Village. Leur numéro va de 0 à 9,
# comme `PaperFragment.fragment` et l'index de `Village.FRAGMENTS` dans Godot.
PAPER_FRAGMENT_COUNT = 10
# order_index de l'énigme à laquelle appartiennent les fragments.
PAPER_FRAGMENT_PUZZLE_ORDER = 4


class PaperFragment(Base):
    """Fragment de papier ramassé pendant une partie."""

    __tablename__ = "paper_fragments"

    __table_args__ = (
        UniqueConstraint(
            "id_game_sessions",
            "fragment_index",
            name="uq_paper_fragments_game_fragment"
        ),
        CheckConstraint(
            f"fragment_index >= 0 AND fragment_index < {PAPER_FRAGMENT_COUNT}",
            name="ck_paper_fragments_fragment_index"
        ),
    )

    id_paper_fragments: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    id_game_sessions: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("game_sessions.id_game_sessions"),
        nullable=False
    )

    fragment_index: Mapped[int] = mapped_column(
        Integer,
        nullable=False
    )

    collected_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )
