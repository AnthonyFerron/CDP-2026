import pytest
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from app.db.session import engine

from conftest import bearer

GAMES = "/api/v1/game-sessions"


def fragments_url(game_id: int) -> str:
    return f"{GAMES}/{game_id}/paper-fragments"


def collect(api, headers, game_id: int, fragment_index):
    return api.client.post(fragments_url(game_id), json={"fragment_index": fragment_index}, headers=headers)


def open_village(api, headers) -> int:
    """Partie où les trois premiers livres sont posés : le Village est ouvert."""
    game_id = api.create_game(headers)["id_game_sessions"]
    for puzzle in api.puzzles()[:3]:
        api.solve_and_place(headers, game_id, puzzle["id_puzzles"], 60)
    return game_id


def stored_count(game_id: int) -> int:
    with engine.connect() as connection:
        return connection.execute(
            text("SELECT count(*) FROM paper_fragments WHERE id_game_sessions = :id"), {"id": game_id}
        ).scalar()


def test_collect_the_ten_fragments(api):
    headers = api.player()
    game_id = open_village(api, headers)

    responses = [collect(api, headers, game_id, index) for index in (4, 0, 9, 1, 8, 2, 7, 3, 6, 5)]

    assert [response.status_code for response in responses] == [201] * 10
    assert responses[0].json() == {"fragment_index": 4, "collected_at": responses[0].json()["collected_at"]}
    listed = api.client.get(fragments_url(game_id), headers=headers).json()
    assert [fragment["fragment_index"] for fragment in listed] == list(range(10))
    progress = api.client.get(f"{GAMES}/{game_id}/progress", headers=headers).json()
    assert progress["collected_fragments"] == list(range(10))
    assert progress["total_fragments"] == 10


def test_same_fragment_cannot_be_collected_twice(api):
    headers = api.player()
    game_id = open_village(api, headers)
    assert collect(api, headers, game_id, 3).status_code == 201

    response = collect(api, headers, game_id, 3)

    assert response.status_code == 409
    assert "déjà ramassé" in response.json()["detail"]
    assert stored_count(game_id) == 1


@pytest.mark.parametrize("fragment_index", [-1, 10, 11, "trois", None, 2.5])
def test_only_the_ten_defined_fragments_exist(api, fragment_index):
    headers = api.player()
    game_id = open_village(api, headers)

    assert collect(api, headers, game_id, fragment_index).status_code == 422
    assert stored_count(game_id) == 0


@pytest.mark.parametrize("payload", [{}, {"fragment_index": 1, "collected_at": "2026-01-01T00:00:00Z"}])
def test_fragment_payload_is_strict(api, payload):
    headers = api.player()
    game_id = open_village(api, headers)

    assert api.client.post(fragments_url(game_id), json=payload, headers=headers).status_code == 422


def test_fragments_need_the_village_to_be_open(api):
    headers = api.player()
    game_id = api.create_game(headers)["id_game_sessions"]
    for puzzle in api.puzzles()[:2]:
        api.solve_and_place(headers, game_id, puzzle["id_puzzles"], 60)

    response = collect(api, headers, game_id, 0)

    assert response.status_code == 409
    assert "Énigme verrouillée" in response.json()["detail"]


def test_collected_fragments_survive_a_resume_on_another_device(api):
    api.register("Devlyn", "devlyn@example.com")
    laptop = bearer(api.login("devlyn@example.com"))
    game_id = open_village(api, laptop)
    for index in (2, 5, 9):
        collect(api, laptop, game_id, index)
    api.client.post(f"{GAMES}/{game_id}/pauses", headers=laptop)  # le joueur quitte en pause
    api.clock.advance(3600)

    phone = bearer(api.login("devlyn@example.com"))
    listed = api.client.get(fragments_url(game_id), headers=phone).json()

    assert [fragment["fragment_index"] for fragment in listed] == [2, 5, 9]
    assert all(fragment["collected_at"] for fragment in listed)
    api.client.post(f"{GAMES}/{game_id}/resumptions", headers=phone)
    assert collect(api, phone, game_id, 5).status_code == 409  # toujours acquis
    assert collect(api, phone, game_id, 0).status_code == 201


def test_fragments_belong_to_their_game(api):
    headers = api.player()
    first_game = open_village(api, headers)
    collect(api, headers, first_game, 0)
    api.client.post(f"{GAMES}/{first_game}/abandonments", headers=headers)

    second_game = open_village(api, headers)

    assert api.client.get(fragments_url(second_game), headers=headers).json() == []
    assert collect(api, headers, second_game, 0).status_code == 201
    assert [f["fragment_index"] for f in api.client.get(fragments_url(first_game), headers=headers).json()] == [0]


def test_fragment_collection_follows_the_timer(api):
    headers = api.player()
    game_id = open_village(api, headers)

    api.client.post(f"{GAMES}/{game_id}/pauses", headers=headers)
    assert collect(api, headers, game_id, 0).status_code == 409
    api.client.post(f"{GAMES}/{game_id}/resumptions", headers=headers)

    api.clock.advance(3600)
    response = collect(api, headers, game_id, 0)
    assert response.status_code == 409
    assert "Temps écoulé" in response.json()["detail"]
    assert stored_count(game_id) == 0


def test_fragments_change_neither_time_nor_ranking(api):
    headers = api.player()
    game_id = open_village(api, headers)
    before = api.game(headers, game_id)["elapsed_seconds"]

    for index in range(10):
        collect(api, headers, game_id, index)

    assert api.game(headers, game_id)["elapsed_seconds"] == before
    api.solve_and_place(headers, game_id, api.puzzles()[3]["id_puzzles"], 60)
    won = api.complete(headers, game_id).json()
    assert won["status"] == "completed" and won["is_rankable"] is True
    assert api.client.get("/api/v1/leaderboards").json()["total"] == 1


def test_database_enforces_fragment_constraints(api):
    headers = api.player()
    game_id = open_village(api, headers)
    collect(api, headers, game_id, 0)
    insert = text(
        "INSERT INTO paper_fragments (id_game_sessions, fragment_index, collected_at) VALUES (:game, :index, now())"
    )

    with pytest.raises(IntegrityError, match="uq_paper_fragments_game_fragment"):
        with engine.begin() as connection:
            connection.execute(insert, {"game": game_id, "index": 0})
    with pytest.raises(IntegrityError, match="ck_paper_fragments_fragment_index"):
        with engine.begin() as connection:
            connection.execute(insert, {"game": game_id, "index": 10})
