from fastapi import FastAPI
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.db.session import engine

app = FastAPI(
    title="CDP-2026 API",
    description="API de l'Escape Game 3D",
    version="1.0.0"
)

@app.get("/api/v1/health")
def health():
    return {
        "status": "ok",
        "message": "Escape Game API opérationnelle"
    }

@app.get("/api/v1/health/database")
def database_health():
    try:
        with engine.connect() as connection:
            connection.execute(text("SELECT 1"))

        return {
            "status": "ok",
            "database": "connected"
        }

    except SQLAlchemyError:
        return JSONResponse(
            status_code=503,
            content={
                "status": "error",
                "database": "disconnected"
            }
        )