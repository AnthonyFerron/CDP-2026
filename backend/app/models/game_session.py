
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class GameSession(Base):
    __tablename__ = "game_sessions"

    id_game_sessions: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    id_users: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id_users"),
        nullable=False
    )

    status: Mapped[str] = mapped_column(
        String(20),
        default="in_progress",
        nullable=False
    )

    elapsed_seconds: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    current_level: Mapped[str] = mapped_column(
        String(50),
        nullable=False
    )

    position_x: Mapped[float] = mapped_column(
        Float,
        default=0.0,
        nullable=False
    )

    position_y: Mapped[float] = mapped_column(
        Float,
        default=0.0,
        nullable=False
    )

    position_z: Mapped[float] = mapped_column(
        Float,
        default=0.0,
        nullable=False
    )

    rotation_y: Mapped[float] = mapped_column(
        Float,
        default=0.0,
        nullable=False
    )

    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    last_saved_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False
    )

    finished_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

    timer_started_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )

