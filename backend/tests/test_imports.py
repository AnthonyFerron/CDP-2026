import pytest
from sqlalchemy import text

from app.db.session import engine

IMPORTS = "/api/v1/game-sessions/imports"
GAMES = "/api/v1/game-sessions"


def guest_save(api, solved: int = 2, placed: int | None = None, **overrides) -> dict:
    puzzles = api.puzzles()
    placed = solved if placed is None else placed
    payload = {
        "status": "in_progress",
        "elapsed_seconds": 1250.5,
        "current_level": "hub",
        "position_x": 0.0,
        "position_y": 1.0,
        "position_z": 4.5,
        "rotation_y": 0.0,
        "solved_puzzles": [
            {"id_puzzles": p["id_puzzles"], "is_placed": index < placed} for index, p in enumerate(puzzles[:solved])
        ],
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
    assert progress["books_placed"] == 2
    assert [state["completion_time_ms"] for state in progress["puzzles"][:2]] == [None, None]


def test_import_keeps_placed_books_and_fragments(api):
    headers = api.player()
    payload = guest_save(api, solved=3, placed=2, collected_fragments=[7, 0, 3])

    game = api.client.post(IMPORTS, json=payload, headers=headers).json()

    progress = api.client.get(f"{GAMES}/{game['id_game_sessions']}/progress", headers=headers).json()
    assert [state["is_solved"] for state in progress["puzzles"]] == [True, True, True, False]
    assert [state["is_placed"] for state in progress["puzzles"]] == [True, True, False, False]
    assert progress["collected_fragments"] == [0, 3, 7]
    fragments = api.client.get(f"{GAMES}/{game['id_game_sessions']}/paper-fragments", headers=headers).json()
    assert [fragment["fragment_index"] for fragment in fragments] == [0, 3, 7]


def test_imported_game_can_be_resumed_and_finished_but_never_ranked(api):
    headers = api.player()
    game = api.client.post(IMPORTS, json=guest_save(api), headers=headers).json()
    game_id = game["id_game_sessions"]

    assert api.client.post(f"{GAMES}/{game_id}/resumptions", headers=headers).status_code == 200
    api.clock.advance(100)
    assert api.game(headers, game_id)["elapsed_seconds"] == 1351
    for puzzle in api.puzzles()[2:]:
        placed = api.solve_and_place(headers, game_id, puzzle["id_puzzles"], 120)
        assert placed["completion_time_ms"] is None
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
        {"collected_fragments": [10]},
        {"collected_fragments": [-1]},
        {"collected_fragments": [1, 1]},
        {"collected_fragments": [0]},  # le Village n'est pas ouvert avec seulement deux énigmes résolues
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
        [{"id_puzzles": ids[0], "hints_used": 0}],  # les indices ne sont plus suivis par l'API
        [{"id_puzzles": ids[0], "is_placed": "oui"}],
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


def test_completed_import_needs_every_book_placed(api):
    headers = api.player()

    response = api.client.post(
        IMPORTS, json=guest_save(api, solved=4, placed=3, status="completed", elapsed_seconds=2000), headers=headers
    )

    assert response.status_code == 422


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
