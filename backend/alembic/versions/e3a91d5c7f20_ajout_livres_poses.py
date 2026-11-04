"""ajout_livres_poses

Revision ID: e3a91d5c7f20
Revises: 7b2f4c9e1a35
Create Date: 2026-11-04 14:00:00.000000

Mémorise le dépôt de chaque livre au château : puzzle_progress.placed_at.
Migration additive, compatible avec les données existantes : la colonne est nullable (aucun livre
n'est considéré comme posé), et la contrainte est vraie pour toute ligne où placed_at est NULL.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e3a91d5c7f20'
down_revision: Union[str, Sequence[str], None] = '7b2f4c9e1a35'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('puzzle_progress', sa.Column('placed_at', sa.DateTime(timezone=True), nullable=True))
    op.create_check_constraint(
        'ck_puzzle_progress_placed_after_solved',
        'puzzle_progress',
        'placed_at IS NULL OR (solved_at IS NOT NULL AND placed_at >= solved_at)',
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint('ck_puzzle_progress_placed_after_solved', 'puzzle_progress', type_='check')
    op.drop_column('puzzle_progress', 'placed_at')
