"""Heure du serveur, en UTC.

Tout le code métier passe par `clock.utcnow()` (et non `datetime.now()`) : les tests peuvent ainsi
avancer le temps sans attendre, par exemple pour vérifier la défaite au bout du chronomètre.
"""

from datetime import datetime, timezone


def utcnow() -> datetime:
    return datetime.now(timezone.utc)
