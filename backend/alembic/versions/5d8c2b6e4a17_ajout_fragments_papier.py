"""ajout_fragments_papier

Revision ID: 5d8c2b6e4a17
Revises: e3a91d5c7f20
Create Date: 2026-11-04 14:05:00.000000

Fragments de papier ramassés dans la mairie (énigme du Village), pour qu'ils restent acquis à la
reprise d'une partie. Un fragment est identifié par son numéro, de 0 à 9, et ne peut être ramassé
qu'une fois par partie. Nouvelle table : aucune donnée existante n'est touchée.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5d8c2b6e4a17'
down_revision: Union[str, Sequence[str], None] = 'e3a91d5c7f20'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('paper_fragments',
    sa.Column('id_paper_fragments', sa.Integer(), autoincrement=True, nullable=False),
    sa.Column('id_game_sessions', sa.Integer(), nullable=False),
    sa.Column('fragment_index', sa.Integer(), nullable=False),
    sa.Column('collected_at', sa.DateTime(timezone=True), nullable=False),
    sa.CheckConstraint('fragment_index >= 0 AND fragment_index < 10', name='ck_paper_fragments_fragment_index'),
    sa.ForeignKeyConstraint(['id_game_sessions'], ['game_sessions.id_game_sessions'], ),
    sa.PrimaryKeyConstraint('id_paper_fragments'),
    sa.UniqueConstraint('id_game_sessions', 'fragment_index', name='uq_paper_fragments_game_fragment')
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table('paper_fragments')
