
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class AuthChallenge(Base):
    __tablename__ = "auth_challenges"

    id_auth_challenges: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True
    )

    id_users: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id_users"),
        nullable=False
    )

    code: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )

    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    attempts: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    consumed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )
