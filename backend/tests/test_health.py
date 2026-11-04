import re

from fastapi.testclient import TestClient
from sqlalchemy import create_engine

from app.api.routes import health as health_routes
from app.main import app

from conftest import UNREACHABLE_DATABASE_URL

client = TestClient(app)


def test_health():
    response = client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_database_health_reports_failure(monkeypatch):
    # Port fermé : la base est volontairement injoignable pendant ce test
    monkeypatch.setattr(health_routes, "engine", create_engine(UNREACHABLE_DATABASE_URL))

    response = client.get("/api/v1/health/database")

    assert response.status_code == 503
    assert response.json()["database"] == "disconnected"


def test_database_health_reports_success(database):
    response = client.get("/api/v1/health/database")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "connected"}


def test_swagger_documentation_is_served_under_api():
    assert client.get("/api/docs").status_code == 200
    spec = client.get("/api/openapi.json").json()
    assert spec["info"]["title"] == "CDP-2026 API"


SINGULAR_RESOURCES = {"user", "auth-challenge", "auth-session", "game-session", "puzzle", "leaderboard", "import"}
ACTIONS = {"me", "current", "database"}


def test_every_resource_in_routes_is_plural():
    paths = client.get("/api/openapi.json").json()["paths"]
    assert len(paths) >= 20
    for path in paths:
        assert path.startswith("/api/v1/"), path
        for segment in path.removeprefix("/api/v1/").split("/"):
            if segment.startswith("{") or segment in ACTIONS:
                continue
            assert segment not in SINGULAR_RESOURCES, path
            assert re.fullmatch(r"[a-z]+(-[a-z]+)*", segment), path
            assert segment.endswith("s") or segment in {"health", "progress", "puzzle-progress"}, path
