"""ajout_enigmes

Revision ID: 7b2f4c9e1a35
Revises: 28803cd8c266
Create Date: 2026-11-04 10:00:00.000000

Insère les quatre énigmes du jeu, dans l'ordre des zones de Godot (GameState.ZONE_ORDER).
Migration de données uniquement : aucun changement de schéma.
Idempotente : une énigme dont l'order_index existe déjà n'est ni dupliquée ni modifiée.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7b2f4c9e1a35'
down_revision: Union[str, Sequence[str], None] = '28803cd8c266'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# (order_index, titre, hint_count) — Plaine, Désert, Marais, Village
# Aucun indice suivi en base : ceux des énigmes sont visuels et restent dans Godot.
PUZZLES = [
    (1, "La discussion oubliée", 0),
    (2, "Les runes de l'algorithme", 0),
    (3, "Le tombeau des lettres oubliées", 0),
    (4, "Les cinq codes oubliés", 0),
]


def upgrade() -> None:
    """Upgrade schema."""
    statement = sa.text(
        "INSERT INTO puzzles (title, order_index, hint_count) "
        "VALUES (:title, :order_index, :hint_count) "
        "ON CONFLICT (order_index) DO NOTHING"
    )
    for order_index, title, hint_count in PUZZLES:
        op.execute(statement.bindparams(title=title, order_index=order_index, hint_count=hint_count))


def downgrade() -> None:
    """Downgrade schema."""
    # Les énigmes déjà jouées sont conservées : les supprimer effacerait des progressions.
    op.execute(
        sa.text(
            "DELETE FROM puzzles p WHERE p.order_index IN (1, 2, 3, 4) "
            "AND NOT EXISTS (SELECT 1 FROM puzzle_progress pp WHERE pp.id_puzzles = p.id_puzzles)"
        )
    )
