import os

# Port fermé : la base est volontairement injoignable pendant ces tests
os.environ["DATABASE_URL"] = "postgresql+psycopg://user:password@127.0.0.1:1/test"

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/api/v1/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_database_health_reports_failure():
    response = client.get("/api/v1/health/database")

    assert response.status_code == 503
    assert response.json()["database"] == "disconnected"
