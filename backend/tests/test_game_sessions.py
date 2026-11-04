import math

import pytest
from sqlalchemy import text

from app.db.session import engine

from conftest import START, bearer

GAMES = "/api/v1/game-sessions"


def row(game_id: int) -> dict:
    with engine.connect() as connection:
        return dict(
            connection.execute(text("SELECT * FROM game_sessions WHERE id_game_sessions = :id"), {"id": game_id})
            .mappings()
            .one()
        )


# --- Création et lecture ---------------------------------------------------------------------------

def test_create_game_starts_the_timer(api):
    headers = api.player()

    game = api.create_game(headers, current_level="hub", position_x=1.5, position_y=0.0, position_z=-2.0)

    assert game["status"] == "in_progress"
    assert game["elapsed_seconds"] == 0
    assert game["remaining_seconds"] == 3600
    assert game["duration_seconds"] == 3600
    assert game["is_paused"] is False
    assert game["is_rankable"] is True
    assert game["position_x"] == 1.5
    stored = row(game["id_game_sessions"])
    assert stored["timer_started_at"] == START
    assert stored["elapsed_seconds"] == 0


def test_create_game_requires_authentication(client):
    assert client.post(GAMES, json={}).status_code == 401


def test_only_one_game_in_progress_per_player(api):
    headers = api.player()
    game = api.create_game(headers)

    response = api.client.post(GAMES, json={}, headers=headers)

    assert response.status_code == 409
    assert str(game["id_game_sessions"]) in response.json()["detail"]
    api.client.post(f"{GAMES}/{game['id_game_sessions']}/abandonments", headers=headers)
    assert api.client.post(GAMES, json={}, headers=headers).status_code == 201


def test_get_game_computes_the_time_on_the_server(api):
    headers = api.player()
    game = api.create_game(headers)
    api.clock.advance(125.25)

    fetched = api.game(headers, game["id_game_sessions"])

    assert fetched["elapsed_seconds"] == 125.25
    assert fetched["remaining_seconds"] == 3600 - 125.25


def test_list_games_with_filter_and_pagination(api):
    headers = api.player()
    for _ in range(3):
        game = api.create_game(headers)
        api.client.post(f"{GAMES}/{game['id_game_sessions']}/abandonments", headers=headers)
        api.clock.advance(10)
    current = api.create_game(headers)

    everything = api.client.get(GAMES, headers=headers).json()
    in_progress = api.client.get(GAMES, params={"status": "in_progress"}, headers=headers).json()
    page = api.client.get(GAMES, params={"limit": 2, "offset": 2}, headers=headers).json()

    assert everything["total"] == 4
    assert everything["items"][0]["id_game_sessions"] == current["id_game_sessions"]
    assert [g["id_game_sessions"] for g in in_progress["items"]] == [current["id_game_sessions"]]
    assert page["total"] == 4 and len(page["items"]) == 2 and page["offset"] == 2
    assert api.client.get(GAMES, params={"status": "gagnee"}, headers=headers).status_code == 422
    assert api.client.get(GAMES, params={"limit": 101}, headers=headers).status_code == 422


# --- Sauvegarde ------------------------------------------------------------------------------------

def test_save_updates_level_and_position(api):
    headers = api.player()
    game = api.create_game(headers)
    api.clock.advance(30)

    response = api.client.patch(
        f"{GAMES}/{game['id_game_sessions']}",
        json={"current_level": "desert", "position_x": 12.5, "position_z": -3.0, "rotation_y": 3 * math.pi},
        headers=headers,
    )

    assert response.status_code == 200
    saved = response.json()
    assert saved["current_level"] == "desert"
    assert saved["position_x"] == 12.5 and saved["position_y"] == 0 and saved["position_z"] == -3.0
    assert abs(abs(saved["rotation_y"]) - math.pi) < 1e-9
    assert row(game["id_game_sessions"])["last_saved_at"] == api.clock.now


@pytest.mark.parametrize(
    "payload",
    [
        {"status": "completed"},
        {"elapsed_seconds": 0},
        {"finished_at": "2026-11-04T12:00:00Z"},
        {"timer_started_at": None},
        {"current_level": "lune"},
        {"position_x": 1e9},
        {"position_y": None},
        {"rotation_y": "vite"},
        {},
    ],
)
def test_save_rejects_sensitive_or_invalid_fields(api, payload):
    headers = api.player()
    game = api.create_game(headers)

    response = api.client.patch(f"{GAMES}/{game['id_game_sessions']}", json=payload, headers=headers)

    assert response.status_code == 422
    assert row(game["id_game_sessions"])["status"] == "in_progress"


def test_resume_on_another_device(api):
    api.register("Devlyn", "devlyn@example.com")
    laptop = bearer(api.login("devlyn@example.com"))
    game = api.create_game(laptop)
    api.client.patch(
        f"{GAMES}/{game['id_game_sessions']}",
        json={"current_level": "marais", "position_x": 4.0, "position_y": 1.0, "position_z": 8.0},
        headers=laptop,
    )
    api.clock.advance(600)  # le navigateur est fermé : le temps continue de courir

    phone = bearer(api.login("devlyn@example.com"))
    current = api.client.get(GAMES, params={"status": "in_progress"}, headers=phone).json()["items"]

    assert len(current) == 1
    assert current[0]["id_game_sessions"] == game["id_game_sessions"]
    assert current[0]["current_level"] == "marais"
    assert current[0]["position_z"] == 8.0
    assert current[0]["elapsed_seconds"] == 600


# --- Chronomètre -----------------------------------------------------------------------------------

def test_pause_stops_the_timer_and_resume_restarts_it(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    api.clock.advance(100)

    paused = api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers)
    assert paused.status_code == 200
    assert paused.json()["is_paused"] is True
    assert paused.json()["elapsed_seconds"] == 100

    api.clock.advance(5000)  # bien plus que la durée de la partie
    assert api.game(headers, game_id)["status"] == "in_progress"
    assert api.game(headers, game_id)["elapsed_seconds"] == 100

    resumed = api.client.post(f"{GAMES}/{game_id}/resumptions", headers=headers)
    assert resumed.status_code == 200
    assert resumed.json()["is_paused"] is False
    api.clock.advance(20)
    assert api.game(headers, game_id)["elapsed_seconds"] == 120


def test_pause_and_resume_reject_invalid_transitions(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]

    assert api.client.post(f"{GAMES}/{game_id}/resumptions", headers=headers).status_code == 409
    assert api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers).status_code == 200
    assert api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers).status_code == 409


def test_pausing_never_saves_time(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]

    for _ in range(10):
        api.clock.advance(0.2)
        api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers)
        api.client.post(f"{GAMES}/{game_id}/resumptions", headers=headers)

    # 2 secondes réelles, mais chaque pause arrondit à la seconde supérieure
    assert api.game(headers, game_id)["elapsed_seconds"] == 10


def test_game_is_lost_when_the_timer_reaches_zero(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]

    api.clock.advance(3599)
    assert api.game(headers, game_id)["status"] == "in_progress"

    api.clock.advance(1)
    lost = api.game(headers, game_id)
    assert lost["status"] == "game_over"
    assert lost["elapsed_seconds"] == 3600
    assert lost["remaining_seconds"] == 0
    stored = row(game_id)
    assert stored["status"] == "game_over"
    assert stored["timer_started_at"] is None


def test_timeout_is_dated_at_the_eruption_even_if_noticed_later(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    api.clock.advance(200)
    api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers)
    api.clock.advance(1000)
    api.client.post(f"{GAMES}/{game_id}/resumptions", headers=headers)
    api.clock.advance(5000)

    response = api.client.patch(f"{GAMES}/{game_id}", json={"position_x": 1.0}, headers=headers)

    assert response.status_code == 409
    assert "Temps écoulé" in response.json()["detail"]
    stored = row(game_id)
    assert stored["status"] == "game_over"
    # 200 s de jeu, 1000 s de pause, puis les 3400 s restantes : l'éruption, pas l'instant de la requête
    assert (stored["finished_at"] - START).total_seconds() == 200 + 1000 + 3400


def test_penalty_removes_five_minutes(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    api.clock.advance(10)

    response = api.client.post(f"{GAMES}/{game_id}/penalties", headers=headers)

    assert response.status_code == 200
    assert response.json()["elapsed_seconds"] == 310
    assert response.json()["remaining_seconds"] == 3290


def test_penalty_can_end_the_game(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    api.clock.advance(3400)

    response = api.client.post(f"{GAMES}/{game_id}/penalties", headers=headers)

    assert response.status_code == 200
    assert response.json()["status"] == "game_over"
    assert row(game_id)["finished_at"] == api.clock.now


# --- Fin de partie ---------------------------------------------------------------------------------

def test_abandon(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    api.clock.advance(42.3)

    response = api.client.post(f"{GAMES}/{game_id}/abandonments", headers=headers)

    assert response.status_code == 200
    assert response.json()["status"] == "abandoned"
    assert response.json()["is_rankable"] is False
    assert row(game_id)["elapsed_seconds"] == 43
    assert row(game_id)["finished_at"] == api.clock.now


def test_valid_victory_freezes_the_time(api):
    headers = api.player()

    won = api.win(headers, splits=(100, 200, 300, 400), final_walk=50)

    assert won["status"] == "completed"
    assert won["elapsed_seconds"] == 1050
    assert won["remaining_seconds"] == 0
    assert won["is_rankable"] is True
    api.clock.advance(10_000)
    assert api.game(headers, won["id_game_sessions"])["elapsed_seconds"] == 1050


def test_victory_requires_every_puzzle_to_be_solved(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    puzzles = api.puzzles()
    for puzzle in puzzles[:3]:
        api.start_and_solve(headers, game_id, puzzle["id_puzzles"], 60)

    response = api.complete(headers, game_id)

    assert response.status_code == 409
    assert "3/4" in response.json()["detail"]
    assert row(game_id)["status"] == "in_progress"


def test_victory_requires_every_book_to_be_placed(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    ids = [puzzle["id_puzzles"] for puzzle in api.puzzles()]
    for puzzle_id in ids:
        api.start_and_solve(headers, game_id, puzzle_id, 60)

    assert api.complete(headers, game_id, placed=ids[:3]).status_code == 409
    assert api.complete(headers, game_id, placed=ids + [999]).status_code == 422
    assert api.complete(headers, game_id, placed=ids[:3] + [ids[0]]).status_code == 422
    assert api.complete(headers, game_id, placed=[]).status_code == 422
    assert row(game_id)["status"] == "in_progress"


def test_victory_is_refused_after_the_time_limit(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    for puzzle in api.puzzles():
        api.start_and_solve(headers, game_id, puzzle["id_puzzles"], 60)
    api.clock.advance(3600)

    response = api.complete(headers, game_id)

    assert response.status_code == 409
    assert row(game_id)["status"] == "game_over"


def test_victory_is_refused_while_paused(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    for puzzle in api.puzzles():
        api.start_and_solve(headers, game_id, puzzle["id_puzzles"], 60)
    api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers)

    assert api.complete(headers, game_id).status_code == 409


@pytest.mark.parametrize("ending", ["abandonments", "completions"])
def test_finished_game_cannot_be_modified(api, ending):
    headers = api.player()
    if ending == "completions":
        game_id = api.win(headers)["id_game_sessions"]
    else:
        game_id = api.create_game(headers)["id_game_sessions"]
        api.client.post(f"{GAMES}/{game_id}/abandonments", headers=headers)
    before = row(game_id)

    attempts = [
        api.client.patch(f"{GAMES}/{game_id}", json={"position_x": 3.0}, headers=headers),
        api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers),
        api.client.post(f"{GAMES}/{game_id}/resumptions", headers=headers),
        api.client.post(f"{GAMES}/{game_id}/penalties", headers=headers),
        api.client.post(f"{GAMES}/{game_id}/abandonments", headers=headers),
        api.complete(headers, game_id),
        api.start(headers, game_id, api.puzzles()[0]["id_puzzles"]),
    ]

    assert [response.status_code for response in attempts] == [409] * len(attempts)
    assert row(game_id) == before


# --- Accès ------------------------------------------------------------------------------------------

def test_cannot_access_another_players_game(api):
    alice = api.player("Alice")
    mallory = api.player("Mallory")
    game_id = api.create_game(alice)["id_game_sessions"]
    progress_id = api.start(alice, game_id, api.puzzles()[0]["id_puzzles"]).json()["id_puzzle_progress"]

    attempts = [
        api.client.get(f"{GAMES}/{game_id}", headers=mallory),
        api.client.patch(f"{GAMES}/{game_id}", json={"position_x": 1.0}, headers=mallory),
        api.client.post(f"{GAMES}/{game_id}/pauses", headers=mallory),
        api.client.post(f"{GAMES}/{game_id}/abandonments", headers=mallory),
        api.complete(mallory, game_id),
        api.client.get(f"{GAMES}/{game_id}/progress", headers=mallory),
        api.client.get(f"{GAMES}/{game_id}/puzzle-progress", headers=mallory),
        api.solve(mallory, game_id, progress_id),
        api.client.post(f"{GAMES}/{game_id}/puzzle-progress/{progress_id}/hints", headers=mallory),
    ]

    assert [response.status_code for response in attempts] == [404] * len(attempts)
    assert api.client.get(GAMES, headers=mallory).json()["total"] == 0
    assert row(game_id)["status"] == "in_progress"


@pytest.mark.parametrize("game_id", ["0", "-1", "abc", "99999999999"])
def test_invalid_game_ids(api, game_id):
    headers = api.player()

    assert api.client.get(f"{GAMES}/{game_id}", headers=headers).status_code == 422


def test_unknown_game_id(api):
    assert api.client.get(f"{GAMES}/12345", headers=api.player()).status_code == 404
