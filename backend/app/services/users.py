from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.errors import ConflictError
from app.core.security import hash_password
from app.models.user import User
from app.schemas.users import UserCreate

EMAIL_TAKEN = "Un compte existe déjà avec cette adresse e-mail."


def find_by_email(db: Session, email: str, *, lock: bool = False) -> User | None:
    statement = select(User).where(func.lower(User.email) == email.lower())
    if lock:
        statement = statement.with_for_update()
    return db.scalars(statement).one_or_none()


def create_user(db: Session, data: UserCreate, now: datetime) -> User:
    if find_by_email(db, data.email) is not None:
        raise ConflictError(EMAIL_TAKEN)

    user = User(
        username=data.username,
        email=data.email,
        password=hash_password(data.password),
        created_at=now,
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError:
        # Deux inscriptions simultanées avec la même adresse : la contrainte unique tranche.
        db.rollback()
        raise ConflictError(EMAIL_TAKEN) from None
    return user
