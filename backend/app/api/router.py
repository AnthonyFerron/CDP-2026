from fastapi import APIRouter

from app.api.routes import (
    auth_challenges,
    auth_sessions,
    health,
    users,
)

api_router = APIRouter(prefix="/api/v1")

for module in (
    health,
    users,
    auth_challenges,
    auth_sessions,
):
    api_router.include_router(module.router)
