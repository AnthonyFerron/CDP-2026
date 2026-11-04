import pytest
from sqlalchemy import text

from app.db.session import engine

IMPORTS = "/api/v1/game-sessions/imports"
GAMES = "/api/v1/game-sessions"


def guest_save(api, solved: int = 2, **overrides) -> dict:
    puzzles = api.puzzles()
    payload = {
        "status": "in_progress",
        "elapsed_seconds": 1250.5,
        "current_level": "hub",
        "position_x": 0.0,
        "position_y": 1.0,
        "position_z": 4.5,
        "rotation_y": 0.0,
        "solved_puzzles": [{"id_puzzles": p["id_puzzles"], "hints_used": 1} for p in puzzles[:solved]],
    }
    payload.update(overrides)
    return payload


def test_valid_import_creates_a_paused_unranked_game(api):
    headers = api.player()

    response = api.client.post(IMPORTS, json=guest_save(api), headers=headers)

    assert response.status_code == 201
    game = response.json()
    assert game["status"] == "in_progress"
    assert game["is_paused"] is True
    assert game["is_rankable"] is False
    assert game["elapsed_seconds"] == 1251  # arrondi à la seconde supérieure
    progress = api.client.get(f"{GAMES}/{game['id_game_sessions']}/progress", headers=headers).json()
    assert progress["books_obtained"] == 2
    assert [state["completion_time_ms"] for state in progress["puzzles"][:2]] == [None, None]
    assert progress["puzzles"][0]["hints_used"] == 1


def test_imported_game_can_be_resumed_and_finished_but_never_ranked(api):
    headers = api.player()
    game = api.client.post(IMPORTS, json=guest_save(api), headers=headers).json()
    game_id = game["id_game_sessions"]

    assert api.client.post(f"{GAMES}/{game_id}/resumptions", headers=headers).status_code == 200
    api.clock.advance(100)
    assert api.game(headers, game_id)["elapsed_seconds"] == 1351
    for puzzle in api.puzzles()[2:]:
        solved = api.start_and_solve(headers, game_id, puzzle["id_puzzles"], 120)
        assert solved["completion_time_ms"] is None
    assert api.complete(headers, game_id).status_code == 200

    assert api.client.get("/api/v1/leaderboards").json()["total"] == 0
    for puzzle in api.puzzles():
        assert api.client.get(f"/api/v1/puzzles/{puzzle['id_puzzles']}/leaderboards").json()["total"] == 0


def test_forged_winning_score_is_kept_out_of_the_leaderboards(api):
    api.win(api.player("Honnete"), splits=(300, 300, 300, 300))
    cheater = api.player("Tricheur")

    response = api.client.post(
        IMPORTS, json=guest_save(api, solved=4, status="completed", elapsed_seconds=125), headers=cheater
    )

    assert response.status_code == 201
    assert response.json()["status"] == "completed"
    assert response.json()["is_rankable"] is False
    board = api.client.get("/api/v1/leaderboards").json()
    assert [entry["username"] for entry in board["items"]] == ["Honnete"]


def test_import_of_a_lost_game(api):
    headers = api.player()

    response = api.client.post(
        IMPORTS, json=guest_save(api, status="game_over", elapsed_seconds=3600), headers=headers
    )

    assert response.status_code == 201
    assert response.json()["status"] == "game_over"
    assert response.json()["finished_at"] is not None


@pytest.mark.parametrize(
    "overrides",
    [
        {"elapsed_seconds": -1},
        {"elapsed_seconds": 3600.5},
        {"status": "in_progress", "elapsed_seconds": 3600},
        {"status": "game_over", "elapsed_seconds": 3000},
        {"status": "completed", "elapsed_seconds": 1000},
        {"status": "abandoned"},
        {"current_level": "lune"},
        {"position_x": float("1e12")},
        {"completion_time_ms": 1},
        {"id_users": 2},
    ],
)
def test_invalid_import_is_refused(api, overrides):
    headers = api.player()

    response = api.client.post(IMPORTS, json=guest_save(api, **overrides), headers=headers)

    assert response.status_code == 422
    with engine.connect() as connection:
        assert connection.execute(text("SELECT count(*) FROM game_sessions")).scalar() == 0


def test_import_rejects_incoherent_puzzles(api):
    headers = api.player()
    ids = [puzzle["id_puzzles"] for puzzle in api.puzzles()]

    cases = [
        [{"id_puzzles": ids[1]}],  # deuxième énigme sans la première
        [{"id_puzzles": ids[0]}, {"id_puzzles": ids[0]}],  # doublon
        [{"id_puzzles": 9999}],  # énigme inconnue
        [{"id_puzzles": ids[0], "hints_used": 4}],  # plus d'indices que disponibles
        [{"id_puzzles": ids[0], "hints_used": -1}],
        [{"id_puzzles": ids[0], "solved_at": "2026-01-01T00:00:00Z"}],
    ]
    for solved in cases:
        response = api.client.post(IMPORTS, json=guest_save(api, solved_puzzles=solved), headers=headers)
        assert response.status_code == 422, solved


def test_completed_import_needs_a_plausible_time(api):
    headers = api.player()

    too_fast = api.client.post(
        IMPORTS, json=guest_save(api, solved=4, status="completed", elapsed_seconds=10), headers=headers
    )

    assert too_fast.status_code == 422


def test_import_requires_authentication(api):
    response = api.client.post(IMPORTS, json=guest_save(api))

    assert response.status_code == 401


def test_import_is_refused_while_another_game_is_in_progress(api):
    headers = api.player()
    api.create_game(headers)

    assert api.client.post(IMPORTS, json=guest_save(api), headers=headers).status_code == 409
    finished = guest_save(api, solved=4, status="completed", elapsed_seconds=2000)
    assert api.client.post(IMPORTS, json=finished, headers=headers).status_code == 201


def test_import_belongs_to_the_new_account(api):
    api.player("Ancien")
    newcomer = api.player("Invite", "invite@example.com")

    game = api.client.post(IMPORTS, json=guest_save(api), headers=newcomer).json()

    mine = api.client.get(GAMES, headers=newcomer).json()
    assert [g["id_game_sessions"] for g in mine["items"]] == [game["id_game_sessions"]]
    me = api.client.get("/api/v1/users/me", headers=newcomer).json()
    with engine.connect() as connection:
        owner = connection.execute(
            text("SELECT id_users FROM game_sessions WHERE id_game_sessions = :id"), {"id": game["id_game_sessions"]}
        ).scalar()
    assert owner == me["id_users"]
