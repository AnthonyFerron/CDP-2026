from fastapi import APIRouter
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.db.session import engine

router = APIRouter(prefix="/health", tags=["Santé"])


@router.get("", summary="État de l'API")
def health():
    return {
        "status": "ok",
        "message": "Escape Game API opérationnelle"
    }


@router.get(
    "/database",
    summary="État de la connexion à PostgreSQL",
    responses={503: {"description": "Base de données injoignable."}},
)
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
