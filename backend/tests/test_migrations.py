"""Migrations Alembic : rejouables, cohérentes avec les modèles, sans perte de données existantes."""

import threading

import pytest
from alembic import command
from sqlalchemy import create_engine, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.pool import NullPool

from app.db.session import engine

from conftest import DATA_TABLES, TEST_DATABASE_URL, alembic_config

SEED = "7b2f4c9e1a35"  # énigmes ; la production est à la révision précédente, 28803cd8c266


def puzzles() -> list[tuple]:
    with engine.connect() as connection:
        return connection.execute(text("SELECT id_puzzles, order_index FROM puzzles ORDER BY order_index")).all()


def test_puzzle_seed_is_idempotent(database):
    before = puzzles()

    # Rejoue la migration des énigmes sur une base qui les contient déjà
    command.stamp(alembic_config(), "28803cd8c266")
    command.upgrade(alembic_config(), SEED)
    command.stamp(alembic_config(), "head")

    assert puzzles() == before
    assert len(before) == 4


def test_puzzle_seed_tracks_no_hints(database):
    # Les indices des énigmes sont visuels et restent dans Godot
    with engine.connect() as connection:
        hint_counts = connection.execute(text("SELECT hint_count FROM puzzles ORDER BY order_index")).scalars().all()
    assert hint_counts == [0, 0, 0, 0]


def test_models_match_the_migrations(database):
    # Échoue si un modèle SQLAlchemy décrit une structure absente des migrations, ou l'inverse
    command.check(alembic_config())


def test_new_migrations_keep_existing_data(database):
    with engine.begin() as connection:
        connection.execute(text(f"TRUNCATE {DATA_TABLES} RESTART IDENTITY CASCADE"))
    command.downgrade(alembic_config(), SEED)
    try:
        # Données créées avant l'ajout des livres posés et des fragments
        with engine.begin() as connection:
            connection.execute(text(
                "INSERT INTO users (username, email, password) VALUES ('Ancien', 'ancien@example.com', 'hash')"
            ))
            connection.execute(text(
                "INSERT INTO game_sessions (id_users, status, elapsed_seconds, current_level, position_x, "
                "position_y, position_z, rotation_y) VALUES (1, 'in_progress', 120, 'plaine', 1, 2, 3, 0)"
            ))
            connection.execute(text(
                "INSERT INTO puzzle_progress (id_game_sessions, id_puzzles, solved_at, completion_time_ms, hints_used) "
                "SELECT 1, id_puzzles, CASE WHEN order_index = 1 THEN now() END, "
                "CASE WHEN order_index = 1 THEN 95000 END, 0 FROM puzzles WHERE order_index <= 2"
            ))
    finally:
        command.upgrade(alembic_config(), "head")

    with engine.connect() as connection:
        game = connection.execute(text("SELECT status, elapsed_seconds, current_level FROM game_sessions")).one()
        rows = connection.execute(
            text("SELECT solved_at IS NOT NULL, completion_time_ms, placed_at FROM puzzle_progress ORDER BY id_puzzles")
        ).all()
        fragments = connection.execute(text("SELECT count(*) FROM paper_fragments")).scalar()
    assert tuple(game) == ("in_progress", 120, "plaine")
    assert [tuple(row) for row in rows] == [(True, 95000, None), (False, None, None)]
    assert fragments == 0

    # Les livres déjà obtenus peuvent être posés, pas les autres
    with engine.begin() as connection:
        connection.execute(text("UPDATE puzzle_progress SET placed_at = now() WHERE solved_at IS NOT NULL"))
    with pytest.raises(IntegrityError):
        with engine.begin() as connection:
            connection.execute(text("UPDATE puzzle_progress SET placed_at = now() WHERE solved_at IS NULL"))


def test_concurrent_migrations_wait_for_each_other(database):
    lock = "SELECT {}(hashtext('cdp2026_alembic'))"
    errors = []

    def migrate():
        try:
            command.upgrade(alembic_config(), "head")
        except Exception as exc:  # remonté dans le test principal
            errors.append(exc)

    holder_engine = create_engine(TEST_DATABASE_URL, poolclass=NullPool)
    with holder_engine.connect() as holder:
        # Une première migration (simulée) détient le verrou
        holder.execute(text(lock.format("pg_advisory_lock")))
        holder.commit()
        other = threading.Thread(target=migrate)
        other.start()
        try:
            other.join(timeout=3)
            assert other.is_alive(), "la seconde migration aurait dû attendre le verrou"
        finally:
            holder.execute(text(lock.format("pg_advisory_unlock")))
            holder.commit()
    holder_engine.dispose()

    other.join(timeout=60)
    assert not other.is_alive()
    assert errors == []
