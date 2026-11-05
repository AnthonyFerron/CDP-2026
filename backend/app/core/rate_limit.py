"""Limitation des échecs de connexion et des demandes de réinitialisation du mot de passe, en mémoire.

Suffisant pour l'unique conteneur API du projet. Avec plusieurs processus ou conteneurs, chacun
aurait son propre compteur : il faudrait alors un stockage partagé (Redis ou table dédiée).
"""

import threading
from collections import deque

_MAX_KEYS = 10_000


class FailureLimiter:
    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._failures: dict[str, deque[float]] = {}

    def _prune(self, key: str, now: float, window: float) -> deque[float]:
        failures = self._failures.get(key)
        if failures is None:
            return deque()
        while failures and failures[0] <= now - window:
            failures.popleft()
        if not failures:
            del self._failures[key]
        return failures

    def retry_after(self, key: str, now: float, max_failures: int, window: float) -> float | None:
        """Secondes à attendre si la limite est atteinte, sinon None."""
        with self._lock:
            failures = self._prune(key, now, window)
            if len(failures) < max_failures:
                return None
            return failures[0] + window - now

    def record_failure(self, key: str, now: float, window: float) -> None:
        with self._lock:
            if key not in self._failures and len(self._failures) >= _MAX_KEYS:
                for stale_key in list(self._failures):
                    self._prune(stale_key, now, window)
            self._failures.setdefault(key, deque()).append(now)

    def reset(self, key: str) -> None:
        with self._lock:
            self._failures.pop(key, None)

    def clear(self) -> None:
        with self._lock:
            self._failures.clear()


login_failures = FailureLimiter()

# Demandes de réinitialisation du mot de passe, par adresse e-mail (que le compte existe ou non) : une
# fenêtre courte (délai entre deux envois) et une fenêtre d'une heure. Deux compteurs, car `record_failure`
# nettoie toutes les clés d'un compteur avec la même fenêtre.
password_reset_recent = FailureLimiter()
password_reset_hourly = FailureLimiter()
