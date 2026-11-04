from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.docs import TAGS
from app.api.router import api_router
from app.core.config import get_settings
from app.core.errors import ApiError

DESCRIPTION = """
API de l'escape game 3D **CDP-2026**, consommée par l'export Web de Godot.

- Toutes les routes commencent par `/api/v1` ; les ressources sont au pluriel.
- Les routes protégées attendent l'en-tête `Authorization: Bearer <token>` (bouton *Authorize*).
- Les erreurs renvoient `{"detail": "message"}` ; les erreurs de validation (422) détaillent chaque champ.
- Les dates sont en UTC, au format ISO 8601.

Guide d'intégration Godot : `docs/api-godot.md` dans le dépôt.
"""

# La documentation est servie sous /api pour être joignable derrière Caddy, qui ne relaie que /api/*.
app = FastAPI(
    title="CDP-2026 API",
    description=DESCRIPTION,
    version="1.0.0",
    openapi_tags=TAGS,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
)


@app.exception_handler(ApiError)
async def handle_api_error(request: Request, exc: ApiError) -> JSONResponse:
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail}, headers=exc.headers)


cors_origins = get_settings().cors_origins
if cors_origins:
    # Origines listées explicitement ; pas de cookies : le token passe par l'en-tête Authorization.
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_credentials=False,
        allow_methods=["GET", "POST", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
        expose_headers=["Retry-After"],
        max_age=600,
    )

app.include_router(api_router)
