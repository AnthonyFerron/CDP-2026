import pytest
from sqlalchemy import text

from app.db.session import engine

GAMES = "/api/v1/game-sessions"


def progress_url(game_id: int, progress_id: int | None = None) -> str:
    url = f"{GAMES}/{game_id}/puzzle-progress"
    return url if progress_id is None else f"{url}/{progress_id}"


# --- Définition des énigmes ------------------------------------------------------------------------

def test_list_the_four_puzzles_without_authentication(client):
    response = client.get("/api/v1/puzzles")

    assert response.status_code == 200
    puzzles = response.json()
    assert [puzzle["order_index"] for puzzle in puzzles] == [1, 2, 3, 4]
    assert [puzzle["title"] for puzzle in puzzles] == [
        "La discussion oubliée",
        "Les runes de l'algorithme",
        "Le tombeau des lettres oubliées",
        "Les cinq codes oubliés",
    ]
    assert set(puzzles[0]) == {"id_puzzles", "title", "order_index"}


def test_get_one_puzzle(api):
    first = api.puzzles()[0]

    assert api.client.get(f"/api/v1/puzzles/{first['id_puzzles']}").json() == first
    assert api.client.get("/api/v1/puzzles/9999").status_code == 404
    assert api.client.get("/api/v1/puzzles/0").status_code == 422


def test_puzzles_cannot_be_modified_through_the_api(api):
    first = api.puzzles()[0]["id_puzzles"]

    assert api.client.post("/api/v1/puzzles", json={"title": "x", "order_index": 9}).status_code == 405
    assert api.client.patch(f"/api/v1/puzzles/{first}", json={"title": "Autre"}).status_code == 405
    assert api.client.delete(f"/api/v1/puzzles/{first}").status_code == 405


# --- Progression -----------------------------------------------------------------------------------

def test_start_a_puzzle_is_idempotent(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    first = api.puzzles()[0]["id_puzzles"]

    created = api.start(headers, game_id, first)
    again = api.start(headers, game_id, first)

    assert created.status_code == 201
    assert again.status_code == 200
    assert again.json()["id_puzzle_progress"] == created.json()["id_puzzle_progress"]
    assert created.json() == {
        "id_puzzle_progress": created.json()["id_puzzle_progress"],
        "id_game_sessions": game_id,
        "id_puzzles": first,
        "is_solved": False,
        "solved_at": None,
        "completion_time_ms": None,
        "is_placed": False,
        "placed_at": None,
    }


def test_puzzles_unlock_in_order(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    first, second = (puzzle["id_puzzles"] for puzzle in api.puzzles()[:2])

    response = api.start(headers, game_id, second)

    assert response.status_code == 409
    assert "La discussion oubliée" in response.json()["detail"]
    api.start_and_solve(headers, game_id, first, 60)
    assert api.start(headers, game_id, second).status_code == 201


def test_start_unknown_puzzle(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]

    assert api.start(headers, game_id, 9999).status_code == 422


def test_valid_resolution_records_the_server_time(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    first = api.puzzles()[0]["id_puzzles"]

    solved = api.start_and_solve(headers, game_id, first, 95.5)

    assert solved["is_solved"] is True
    assert solved["solved_at"] is not None
    assert solved["completion_time_ms"] == 95_500


def test_resolution_cannot_be_recorded_twice(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    solved = api.start_and_solve(headers, game_id, api.puzzles()[0]["id_puzzles"], 60)

    response = api.solve(headers, game_id, solved["id_puzzle_progress"])

    assert response.status_code == 409
    with engine.connect() as connection:
        assert connection.execute(text("SELECT count(*) FROM puzzle_progress")).scalar() == 1


@pytest.mark.parametrize("payload", [{"solved": False}, {}, {"solved": True, "completion_time_ms": 1}, {"solved_at": None}])
def test_resolution_payload_is_strict(api, payload):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    progress_id = api.start(headers, game_id, api.puzzles()[0]["id_puzzles"]).json()["id_puzzle_progress"]

    response = api.client.patch(progress_url(game_id, progress_id), json=payload, headers=headers)

    assert response.status_code == 422


def test_split_times_exclude_pauses_and_include_penalties(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    first, second = (puzzle["id_puzzles"] for puzzle in api.puzzles()[:2])
    api.start_and_solve(headers, game_id, first, 120)

    progress_id = api.start(headers, game_id, second).json()["id_puzzle_progress"]
    api.clock.advance(40)
    api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers)
    api.clock.advance(900)  # pause : non comptée
    api.client.post(f"{GAMES}/{game_id}/resumptions", headers=headers)
    api.client.post(f"{GAMES}/{game_id}/penalties", headers=headers)  # +300 s
    api.clock.advance(20.25)
    solved = api.solve(headers, game_id, progress_id).json()

    assert solved["completion_time_ms"] == 40_000 + 300_000 + 20_250


def test_resolution_is_refused_while_paused(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    progress_id = api.start(headers, game_id, api.puzzles()[0]["id_puzzles"]).json()["id_puzzle_progress"]
    api.clock.advance(60)
    api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers)

    response = api.solve(headers, game_id, progress_id)

    assert response.status_code == 409
    assert "pause" in response.json()["detail"]


def test_implausibly_fast_resolution_is_kept_but_unranked(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    first, second = (puzzle["id_puzzles"] for puzzle in api.puzzles()[:2])

    fast = api.start_and_solve(headers, game_id, first, 5)
    later = api.start_and_solve(headers, game_id, second, 120)

    assert fast["is_solved"] is True and fast["completion_time_ms"] is None
    assert later["completion_time_ms"] is None  # plus de référence fiable pour mesurer la suite
    assert api.game(headers, game_id)["is_rankable"] is False


def test_progress_id_must_belong_to_the_game(api):
    headers = api.player()
    first_game = api.create_game(headers)["id_game_sessions"]
    progress_id = api.start(headers, first_game, api.puzzles()[0]["id_puzzles"]).json()["id_puzzle_progress"]
    api.client.post(f"{GAMES}/{first_game}/abandonments", headers=headers)
    second_game = api.create_game(headers)["id_game_sessions"]

    assert api.solve(headers, second_game, progress_id).status_code == 404
    assert api.solve(headers, second_game, 9999).status_code == 404


# --- Vue d'ensemble et livres ----------------------------------------------------------------------

def test_game_progress_lists_books_and_puzzle_states(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    puzzles = api.puzzles()
    api.solve_and_place(headers, game_id, puzzles[0]["id_puzzles"], 60)
    api.start_and_solve(headers, game_id, puzzles[1]["id_puzzles"], 60)
    api.start(headers, game_id, puzzles[2]["id_puzzles"])

    progress = api.client.get(f"{GAMES}/{game_id}/progress", headers=headers).json()

    assert progress["books_obtained"] == 2
    assert progress["books_placed"] == 1
    assert progress["total_books"] == 4
    assert progress["can_complete"] is False
    assert progress["remaining_seconds"] == 3480
    assert progress["collected_fragments"] == []
    assert progress["total_fragments"] == 10
    states = progress["puzzles"]
    assert [state["is_solved"] for state in states] == [True, True, False, False]
    assert [state["is_placed"] for state in states] == [True, False, False, False]
    assert [state["is_started"] for state in states] == [True, True, True, False]
    assert [state["is_unlocked"] for state in states] == [True, True, True, False]
    assert states[3]["id_puzzle_progress"] is None
    assert not any(key.startswith("hint") for key in states[0])


def test_books_match_solved_puzzles(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    puzzles = api.puzzles()
    for puzzle in puzzles:
        api.start_and_solve(headers, game_id, puzzle["id_puzzles"], 45)

    rows = api.client.get(progress_url(game_id), headers=headers).json()
    progress = api.client.get(f"{GAMES}/{game_id}/progress", headers=headers).json()

    assert sorted(row["id_puzzles"] for row in rows if row["is_solved"]) == sorted(p["id_puzzles"] for p in puzzles)
    assert progress["books_obtained"] == 4
    assert progress["books_placed"] == 0
    assert progress["can_complete"] is False  # livres obtenus, mais pas encore posés
    assert sum(row["completion_time_ms"] for row in rows) == 4 * 45_000


def test_hint_route_no_longer_exists(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    progress_id = api.start(headers, game_id, api.puzzles()[0]["id_puzzles"]).json()["id_puzzle_progress"]

    assert api.client.post(f"{progress_url(game_id, progress_id)}/hints", headers=headers).status_code == 404
