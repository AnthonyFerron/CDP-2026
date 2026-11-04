"""Configuration des tests.

Les tests d'API utilisent une base PostgreSQL dédiée, donnée par TEST_DATABASE_URL. Par sécurité, son
nom doit contenir « test » : son schéma est entièrement recréé au début de la session, puis les
tables sont vidées avant chaque test. Sans TEST_DATABASE_URL, ces tests sont ignorés en local et
font échouer la CI.

Le temps est simulé (fixture `clock`) et les e-mails restent en mémoire (fixture `outbox`).
"""

import os
import re
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest
from sqlalchemy.engine import make_url

BACKEND_DIR = Path(__file__).resolve().parents[1]
TEST_DATABASE_URL = os.environ.get("TEST_DATABASE_URL", "")
UNREACHABLE_DATABASE_URL = "postgresql+psycopg://user:password@127.0.0.1:1/unavailable"

if TEST_DATABASE_URL:
    _database_name = make_url(TEST_DATABASE_URL).database or ""
    if "test" not in _database_name.lower():
        raise RuntimeError(
            f"TEST_DATABASE_URL vise la base « {_database_name} » : son nom doit contenir « test », "
            "car les tests la vident entièrement."
        )

# Valeurs fixées avant d'importer l'application, pour qu'un .env local ne change rien aux tests.
os.environ.update(
    {
        "DATABASE_URL": TEST_DATABASE_URL or UNREACHABLE_DATABASE_URL,
        "SECRET_KEY": "secret-de-test-uniquement",
        "EMAIL_BACKEND": "memory",
        "CORS_ALLOWED_ORIGINS": "",
        "OTP_TTL_SECONDS": "600",
        "OTP_MAX_ATTEMPTS": "5",
        "OTP_RESEND_COOLDOWN_SECONDS": "60",
        "OTP_MAX_PER_HOUR": "5",
        "SESSION_TTL_HOURS": "168",
        "LOGIN_MAX_FAILURES": "10",
        "LOGIN_FAILURE_WINDOW_SECONDS": "900",
        "GAME_DURATION_SECONDS": "3600",
        "PENALTY_SECONDS": "300",
        "PUZZLE_MIN_SOLVE_SECONDS": "30",
    }
)

from alembic import command  # noqa: E402
from alembic.config import Config  # noqa: E402
from argon2 import PasswordHasher  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import text  # noqa: E402

from app.core import clock as clock_module  # noqa: E402
from app.core import security  # noqa: E402
from app.core.rate_limit import login_failures  # noqa: E402
from app.db.session import engine  # noqa: E402
from app.main import app  # noqa: E402
from app.services.email import MemoryEmailSender, get_email_sender  # noqa: E402

# Même algorithme (Argon2id), paramètres allégés pour que les tests restent rapides.
security._password_hasher = PasswordHasher(time_cost=1, memory_cost=1024, parallelism=1)

DATA_TABLES = "users, auth_challenges, auth_sessions, game_sessions, puzzle_progress"
DEFAULT_PASSWORD = "Volcan2026"
START = datetime(2026, 11, 4, 12, 0, tzinfo=timezone.utc)


def alembic_config() -> Config:
    config = Config(str(BACKEND_DIR / "alembic.ini"))
    config.set_main_option("script_location", str(BACKEND_DIR / "alembic"))
    return config


@pytest.fixture(scope="session")
def database():
    """Base de test recréée de zéro avec les migrations Alembic, énigmes comprises."""
    if not TEST_DATABASE_URL:
        if os.environ.get("CI"):
            pytest.fail("TEST_DATABASE_URL est obligatoire en CI.")
        pytest.skip("TEST_DATABASE_URL n'est pas défini : tests d'API ignorés.")
    with engine.begin() as connection:
        connection.execute(text("DROP SCHEMA public CASCADE"))
        connection.execute(text("CREATE SCHEMA public"))
    command.upgrade(alembic_config(), "head")
    return engine


class FakeClock:
    def __init__(self) -> None:
        self.now = START

    def __call__(self) -> datetime:
        return self.now

    def advance(self, seconds: float = 0, **kwargs: float) -> None:
        self.now += timedelta(seconds=seconds, **kwargs)


@pytest.fixture
def clock(monkeypatch) -> FakeClock:
    fake = FakeClock()
    monkeypatch.setattr(clock_module, "utcnow", fake)
    return fake


@pytest.fixture
def outbox() -> MemoryEmailSender:
    return MemoryEmailSender()


@pytest.fixture
def client(database, clock, outbox):
    with engine.begin() as connection:
        connection.execute(text(f"TRUNCATE {DATA_TABLES} RESTART IDENTITY CASCADE"))
    login_failures.clear()
    app.dependency_overrides[get_email_sender] = lambda: outbox
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


def bearer(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


class Api:
    """Raccourcis pour écrire les scénarios de test."""

    def __init__(self, client: TestClient, outbox: MemoryEmailSender, clock: FakeClock):
        self.client = client
        self.outbox = outbox
        self.clock = clock

    # --- Comptes ---

    def register(self, username: str = "Devlyn", email: str = "devlyn@example.com", password: str = DEFAULT_PASSWORD):
        response = self.client.post("/api/v1/users", json={"username": username, "email": email, "password": password})
        assert response.status_code == 201, response.text
        return response.json()

    def last_code(self, email: str) -> str:
        message = next(mail for mail in reversed(self.outbox.outbox) if mail.to == email)
        return re.search(r"\b(\d{6})\b", message.body).group(1)

    def login(self, email: str = "devlyn@example.com", password: str = DEFAULT_PASSWORD) -> str:
        response = self.client.post("/api/v1/auth-challenges", json={"email": email, "password": password})
        assert response.status_code == 201, response.text
        response = self.client.post("/api/v1/auth-sessions", json={"email": email, "code": self.last_code(email)})
        assert response.status_code == 201, response.text
        return response.json()["token"]

    def player(self, username: str = "Devlyn", email: str | None = None) -> dict[str, str]:
        email = email or f"{username.lower().replace(' ', '.')}@example.com"
        self.register(username, email)
        return bearer(self.login(email))

    # --- Parties ---

    def puzzles(self) -> list[dict]:
        return self.client.get("/api/v1/puzzles").json()

    def create_game(self, headers, **body) -> dict:
        response = self.client.post("/api/v1/game-sessions", json=body, headers=headers)
        assert response.status_code == 201, response.text
        return response.json()

    def game(self, headers, game_id: int) -> dict:
        return self.client.get(f"/api/v1/game-sessions/{game_id}", headers=headers).json()

    def start(self, headers, game_id: int, puzzle_id: int):
        return self.client.post(
            f"/api/v1/game-sessions/{game_id}/puzzle-progress", json={"id_puzzles": puzzle_id}, headers=headers
        )

    def solve(self, headers, game_id: int, progress_id: int):
        return self.client.patch(
            f"/api/v1/game-sessions/{game_id}/puzzle-progress/{progress_id}", json={"solved": True}, headers=headers
        )

    def start_and_solve(self, headers, game_id: int, puzzle_id: int, seconds: float) -> dict:
        response = self.start(headers, game_id, puzzle_id)
        assert response.status_code in (200, 201), response.text
        self.clock.advance(seconds)
        response = self.solve(headers, game_id, response.json()["id_puzzle_progress"])
        assert response.status_code == 200, response.text
        return response.json()

    def complete(self, headers, game_id: int, placed: list[int] | None = None):
        placed = [puzzle["id_puzzles"] for puzzle in self.puzzles()] if placed is None else placed
        return self.client.post(
            f"/api/v1/game-sessions/{game_id}/completions", json={"placed_puzzle_ids": placed}, headers=headers
        )

    def win(self, headers, splits: tuple[float, ...] = (60, 60, 60, 60), final_walk: float = 30) -> dict:
        """Joue une partie complète : chaque énigme résolue après `splits[i]` secondes."""
        game = self.create_game(headers)
        for puzzle, seconds in zip(self.puzzles(), splits, strict=True):
            self.start_and_solve(headers, game["id_game_sessions"], puzzle["id_puzzles"], seconds)
        self.clock.advance(final_walk)
        response = self.complete(headers, game["id_game_sessions"])
        assert response.status_code == 200, response.text
        return response.json()


@pytest.fixture
def api(client, outbox, clock) -> Api:
    return Api(client, outbox, clock)
