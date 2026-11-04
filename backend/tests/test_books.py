import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.db.session import engine

from conftest import bearer

GAMES = "/api/v1/game-sessions"


def placed_at(progress_id: int):
    with engine.connect() as connection:
        return connection.execute(
            text("SELECT placed_at FROM puzzle_progress WHERE id_puzzle_progress = :id"), {"id": progress_id}
        ).scalar()


def test_place_a_book_after_solving_its_puzzle(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    solved = api.start_and_solve(headers, game_id, api.puzzles()[0]["id_puzzles"], 60)
    api.clock.advance(25)  # retour au château

    response = api.place(headers, game_id, solved["id_puzzle_progress"])

    assert response.status_code == 200
    body = response.json()
    assert body["is_solved"] is True
    assert body["is_placed"] is True
    assert placed_at(solved["id_puzzle_progress"]) == api.clock.now
    assert body["completion_time_ms"] == solved["completion_time_ms"]  # le dépôt ne change pas le temps mesuré


def test_cannot_place_a_book_not_obtained(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    progress_id = api.start(headers, game_id, api.puzzles()[0]["id_puzzles"]).json()["id_puzzle_progress"]

    response = api.place(headers, game_id, progress_id)

    assert response.status_code == 409
    assert "Livre non obtenu" in response.json()["detail"]
    assert placed_at(progress_id) is None


def test_cannot_place_the_same_book_twice(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    placed = api.solve_and_place(headers, game_id, api.puzzles()[0]["id_puzzles"], 60)
    first_date = placed_at(placed["id_puzzle_progress"])
    api.clock.advance(10)

    response = api.place(headers, game_id, placed["id_puzzle_progress"])

    assert response.status_code == 409
    assert "déjà posé" in response.json()["detail"]
    assert placed_at(placed["id_puzzle_progress"]) == first_date


def test_placement_is_refused_while_paused(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    solved = api.start_and_solve(headers, game_id, api.puzzles()[0]["id_puzzles"], 60)
    api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers)

    assert api.place(headers, game_id, solved["id_puzzle_progress"]).status_code == 409
    assert placed_at(solved["id_puzzle_progress"]) is None


def test_placement_is_refused_once_the_time_is_up(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    solved = api.start_and_solve(headers, game_id, api.puzzles()[0]["id_puzzles"], 60)
    api.clock.advance(3600)

    response = api.place(headers, game_id, solved["id_puzzle_progress"])

    assert response.status_code == 409
    assert "Temps écoulé" in response.json()["detail"]
    assert api.game(headers, game_id)["status"] == "game_over"
    assert placed_at(solved["id_puzzle_progress"]) is None


def test_unknown_progress_cannot_be_placed(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]

    assert api.place(headers, game_id, 9999).status_code == 404


def test_placed_books_persist_across_devices(api):
    api.register("Devlyn", "devlyn@example.com")
    laptop = bearer(api.login("devlyn@example.com"))
    game_id = api.create_game(laptop)["id_game_sessions"]
    puzzles = api.puzzles()
    api.solve_and_place(laptop, game_id, puzzles[0]["id_puzzles"], 60)
    api.solve_and_place(laptop, game_id, puzzles[1]["id_puzzles"], 60)
    api.start_and_solve(laptop, game_id, puzzles[2]["id_puzzles"], 60)  # obtenu, encore en main
    api.client.delete("/api/v1/auth-sessions/current", headers=laptop)  # le joueur quitte
    api.clock.advance(61)

    phone = bearer(api.login("devlyn@example.com"))
    progress = api.client.get(f"{GAMES}/{game_id}/progress", headers=phone).json()
    rows = api.client.get(f"{GAMES}/{game_id}/puzzle-progress", headers=phone).json()

    assert progress["books_obtained"] == 3
    assert progress["books_placed"] == 2
    assert [state["is_solved"] for state in progress["puzzles"]] == [True, True, True, False]
    assert [state["is_placed"] for state in progress["puzzles"]] == [True, True, False, False]
    assert all(state["placed_at"] for state in progress["puzzles"][:2])
    assert [row["is_placed"] for row in rows] == [True, True, False]

    # Le livre encore en main se pose depuis le nouvel appareil
    assert api.place(phone, game_id, rows[2]["id_puzzle_progress"]).status_code == 200


def test_victory_after_placing_the_four_books(api):
    headers = api.player()

    won = api.win(headers, splits=(100, 100, 100, 100), final_walk=20)

    assert won["status"] == "completed"
    assert won["elapsed_seconds"] == 420
    assert won["is_rankable"] is True
    progress = api.client.get(f"{GAMES}/{won['id_game_sessions']}/progress", headers=headers).json()
    assert progress["books_placed"] == 4
    board = api.client.get("/api/v1/leaderboards").json()
    assert [(entry["username"], entry["elapsed_seconds"]) for entry in board["items"]] == [("Devlyn", 420)]


def test_database_refuses_a_book_placed_before_being_solved(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    progress_id = api.start(headers, game_id, api.puzzles()[0]["id_puzzles"]).json()["id_puzzle_progress"]

    with pytest.raises(IntegrityError, match="ck_puzzle_progress_placed_after_solved"):
        with engine.begin() as connection:
            connection.execute(
                text("UPDATE puzzle_progress SET placed_at = now() WHERE id_puzzle_progress = :id"),
                {"id": progress_id},
            )
