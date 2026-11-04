"""Migrations Alembic : rejouables, cohérentes avec les modèles, sans perte de données existantes."""

import pytest
from alembic import command
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.db.session import engine

from conftest import DATA_TABLES, alembic_config

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
