from collections.abc import Iterator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings

DATABASE_URL = get_settings().database_url

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    expire_on_commit=False
)


def get_db() -> Iterator[Session]:
    """Session SQLAlchemy d'une requête : toute écriture non validée est annulée à la fermeture."""
    with SessionLocal() as db:
        yield db
