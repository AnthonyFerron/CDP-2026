
from sqlalchemy import Integer, String, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Puzzle(Base):
    __tablename__ = "puzzles"

    __table_args__ = (
        CheckConstraint("hint_count >= 0", name="ck_puzzles_hint_count"),
    )

    id_puzzles: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    title: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    order_index: Mapped[int] = mapped_column(
        Integer,
        unique=True,
        nullable=False
    )

    hint_count: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )
