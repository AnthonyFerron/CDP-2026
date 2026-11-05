from fastapi import APIRouter

from app.api.routes import (
    auth_challenges,
    auth_sessions,
    game_sessions,
    health,
    leaderboards,
    paper_fragments,
    password_resets,
    puzzle_progress,
    puzzles,
    users,
)

api_router = APIRouter(prefix="/api/v1")

for module in (
    health,
    users,
    auth_challenges,
    auth_sessions,
    password_resets,
    game_sessions,
    puzzle_progress,
    paper_fragments,
    puzzles,
    leaderboards,
):
    api_router.include_router(module.router)
