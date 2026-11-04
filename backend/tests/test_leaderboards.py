LEADERBOARD = "/api/v1/leaderboards"
GAMES = "/api/v1/game-sessions"


def leaderboard(api, **params) -> dict:
    response = api.client.get(LEADERBOARD, params=params)
    assert response.status_code == 200, response.text
    return response.json()


def puzzle_leaderboard(api, puzzle_id: int, **params) -> dict:
    response = api.client.get(f"/api/v1/puzzles/{puzzle_id}/leaderboards", params=params)
    assert response.status_code == 200, response.text
    return response.json()


def test_general_leaderboard_is_sorted_by_total_time(api):
    api.win(api.player("Lent"), splits=(300, 300, 300, 300))
    api.win(api.player("Rapide"), splits=(60, 60, 60, 60))
    api.win(api.player("Moyen"), splits=(120, 120, 120, 120))

    board = leaderboard(api)

    assert [(e["rank"], e["username"], e["elapsed_seconds"]) for e in board["items"]] == [
        (1, "Rapide", 270),
        (2, "Moyen", 510),
        (3, "Lent", 1230),
    ]
    assert board["items"][0]["time_formatted"] == "04:30"
    assert board["total"] == 3


def test_general_leaderboard_keeps_each_players_best_game(api):
    headers = api.player("Devlyn")
    api.win(headers, splits=(200, 200, 200, 200))
    api.win(headers, splits=(100, 100, 100, 100))
    api.win(headers, splits=(150, 150, 150, 150))

    board = leaderboard(api)

    assert board["total"] == 1
    assert board["items"][0]["elapsed_seconds"] == 430


def test_lost_and_abandoned_games_are_excluded(api):
    api.win(api.player("Gagnant"))

    loser = api.player("Perdant")
    lost = api.create_game(loser)["id_game_sessions"]
    for puzzle in api.puzzles():
        api.start_and_solve(loser, lost, puzzle["id_puzzles"], 40)
    api.clock.advance(3600)
    assert api.game(loser, lost)["status"] == "game_over"

    quitter = api.player("Lacheur")
    quit_game = api.create_game(quitter)["id_game_sessions"]
    for puzzle in api.puzzles():
        api.start_and_solve(quitter, quit_game, puzzle["id_puzzles"], 40)
    api.client.post(f"{GAMES}/{quit_game}/abandonments", headers=quitter)

    in_progress = api.player("EnCours")
    current = api.create_game(in_progress)["id_game_sessions"]
    api.start_and_solve(in_progress, current, api.puzzles()[0]["id_puzzles"], 31)

    board = leaderboard(api)
    first_puzzle = puzzle_leaderboard(api, api.puzzles()[0]["id_puzzles"])

    assert [entry["username"] for entry in board["items"]] == ["Gagnant"]
    assert [entry["username"] for entry in first_puzzle["items"]] == ["Gagnant"]


def test_ties_share_the_same_rank(api):
    api.win(api.player("Premier"), splits=(60, 60, 60, 60))
    api.win(api.player("Second"), splits=(60, 60, 60, 60))
    api.win(api.player("Dernier"), splits=(90, 90, 90, 90))

    items = leaderboard(api)["items"]

    # Même temps : même rang, et le premier à l'avoir réalisé passe devant
    assert [(e["rank"], e["username"]) for e in items] == [(1, "Premier"), (1, "Second"), (3, "Dernier")]


def test_pagination_keeps_global_ranks(api):
    for index in range(5):
        api.win(api.player(f"Joueur{index}"), splits=(60 + index, 60, 60, 60))

    page = leaderboard(api, limit=2, offset=2)

    assert page["total"] == 5 and page["limit"] == 2 and page["offset"] == 2
    assert [(e["rank"], e["username"]) for e in page["items"]] == [(3, "Joueur2"), (4, "Joueur3")]
    assert leaderboard(api, limit=2, offset=10)["items"] == []
    assert api.client.get(LEADERBOARD, params={"limit": 0}).status_code == 422
    assert api.client.get(LEADERBOARD, params={"limit": 101}).status_code == 422
    assert api.client.get(LEADERBOARD, params={"offset": -1}).status_code == 422


def test_leaderboards_expose_no_private_data(api):
    api.win(api.player("Devlyn", "devlyn.secret@example.com"))

    general = api.client.get(LEADERBOARD)
    by_puzzle = api.client.get(f"/api/v1/puzzles/{api.puzzles()[0]['id_puzzles']}/leaderboards")

    assert set(general.json()["items"][0]) == {"rank", "username", "elapsed_seconds", "time_formatted", "finished_at"}
    assert set(by_puzzle.json()["items"][0]) == {
        "rank", "username", "completion_time_ms", "time_formatted", "hints_used", "solved_at"
    }
    for response in (general, by_puzzle):
        for secret in ("devlyn.secret", "email", "password", "token", "id_users", "id_game_sessions"):
            assert secret not in response.text


def test_puzzle_leaderboard_is_sorted_by_resolution_time(api):
    api.win(api.player("Alice"), splits=(90, 60, 60, 60))
    api.win(api.player("Bob"), splits=(45.5, 60, 60, 60))
    api.win(api.player("Chloe"), splits=(70, 60, 60, 60))
    first = api.puzzles()[0]

    board = puzzle_leaderboard(api, first["id_puzzles"])

    assert board["puzzle"]["id_puzzles"] == first["id_puzzles"]
    assert [(e["rank"], e["username"], e["completion_time_ms"]) for e in board["items"]] == [
        (1, "Bob", 45_500),
        (2, "Chloe", 70_000),
        (3, "Alice", 90_000),
    ]
    assert board["items"][0]["time_formatted"] == "00:45.500"


def test_puzzle_leaderboard_unknown_puzzle(client):
    assert client.get("/api/v1/puzzles/9999/leaderboards").status_code == 404


def test_unranked_games_are_excluded(api):
    api.win(api.player("Honnete"), splits=(60, 60, 60, 60))
    api.win(api.player("Trop rapide"), splits=(60, 2, 60, 60))

    board = leaderboard(api)
    first = puzzle_leaderboard(api, api.puzzles()[0]["id_puzzles"])

    assert [entry["username"] for entry in board["items"]] == ["Honnete"]
    # La première énigme de « Trop rapide » a été mesurée normalement : elle reste classée
    assert sorted(entry["username"] for entry in first["items"]) == ["Honnete", "Trop rapide"]


def test_empty_leaderboards(client):
    assert client.get(LEADERBOARD).json() == {"items": [], "total": 0, "limit": 20, "offset": 0}
