import hashlib

import pytest
from sqlalchemy import text

from app.core.security import verify_password
from app.db.session import engine

from conftest import DEFAULT_PASSWORD, bearer

EMAIL = "devlyn@example.com"


def scalar(sql: str, **params):
    with engine.connect() as connection:
        return connection.execute(text(sql), params).scalar()


# --- Inscription -----------------------------------------------------------------------------------

def test_register_valid(client):
    response = client.post(
        "/api/v1/users", json={"username": "  Devlyn  ", "email": "Devlyn@Example.com", "password": DEFAULT_PASSWORD}
    )

    assert response.status_code == 201
    body = response.json()
    assert set(body) == {"id_users", "username", "email", "created_at"}
    assert body["username"] == "Devlyn"
    assert body["email"] == EMAIL


def test_register_duplicate_email_is_case_insensitive(api):
    api.register(email=EMAIL)

    response = api.client.post(
        "/api/v1/users", json={"username": "Autre", "email": "DEVLYN@example.com", "password": DEFAULT_PASSWORD}
    )

    assert response.status_code == 409
    assert scalar("SELECT count(*) FROM users") == 1


@pytest.mark.parametrize("email", ["pas-un-email", "a@", "@example.com", ""])
def test_register_invalid_email(client, email):
    response = client.post("/api/v1/users", json={"username": "Devlyn", "email": email, "password": DEFAULT_PASSWORD})

    assert response.status_code == 422


@pytest.mark.parametrize("password", ["court1", "sanschiffre", "12345678", "a1" * 65])
def test_register_invalid_password(client, password):
    response = client.post("/api/v1/users", json={"username": "Devlyn", "email": EMAIL, "password": password})

    assert response.status_code == 422


@pytest.mark.parametrize("username", ["ab", "<script>", "x" * 51, "   "])
def test_register_invalid_username(client, username):
    response = client.post("/api/v1/users", json={"username": username, "email": EMAIL, "password": DEFAULT_PASSWORD})

    assert response.status_code == 422


def test_register_rejects_unknown_fields(client):
    response = client.post(
        "/api/v1/users",
        json={"username": "Devlyn", "email": EMAIL, "password": DEFAULT_PASSWORD, "id_users": 1},
    )

    assert response.status_code == 422


def test_password_is_hashed_with_argon2(api):
    api.register(email=EMAIL)

    stored = scalar("SELECT password FROM users WHERE email = :email", email=EMAIL)
    assert stored != DEFAULT_PASSWORD
    assert stored.startswith("$argon2id$")
    assert verify_password(stored, DEFAULT_PASSWORD)
    assert not verify_password(stored, "Mauvais2026")


# --- Connexion et code 2FA -------------------------------------------------------------------------

def test_login_sends_a_hashed_six_digit_code(api):
    api.register(email=EMAIL)

    response = api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})

    assert response.status_code == 201
    body = response.json()
    assert body["email_masked"] == "d***@example.com"
    assert body["max_attempts"] == 5
    assert "code" not in body
    assert len(api.outbox.outbox) == 1
    code = api.last_code(EMAIL)
    stored = scalar("SELECT code FROM auth_challenges")
    assert stored != code and len(stored) == 64


@pytest.mark.parametrize("email, password", [(EMAIL, "Mauvais2026"), ("inconnu@example.com", DEFAULT_PASSWORD)])
def test_login_with_wrong_credentials(api, email, password):
    api.register(email=EMAIL)

    response = api.client.post("/api/v1/auth-challenges", json={"email": email, "password": password})

    assert response.status_code == 401
    assert response.json()["detail"] == "E-mail ou mot de passe incorrect."
    assert api.outbox.outbox == []


def test_login_is_blocked_after_too_many_failures(api):
    api.register(email=EMAIL)
    for _ in range(10):
        api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": "Mauvais2026"})

    response = api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})

    assert response.status_code == 429
    assert int(response.headers["Retry-After"]) > 0

    api.clock.advance(901)
    assert api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD}).status_code == 201


def test_valid_code_opens_a_session(api):
    api.register(email=EMAIL)
    api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})

    response = api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": api.last_code(EMAIL)})

    assert response.status_code == 201
    body = response.json()
    assert body["token_type"] == "bearer"
    assert body["user"]["email"] == EMAIL
    stored = scalar("SELECT token FROM auth_sessions")
    assert stored == hashlib.sha256(body["token"].encode()).hexdigest()
    me = api.client.get("/api/v1/users/me", headers=bearer(body["token"]))
    assert me.status_code == 200
    assert me.json()["email"] == EMAIL


def test_wrong_code_is_rejected(api):
    api.register(email=EMAIL)
    api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})
    wrong = "000000" if api.last_code(EMAIL) != "000000" else "111111"

    response = api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": wrong})

    assert response.status_code == 401
    assert "Essais restants : 4" in response.json()["detail"]
    assert scalar("SELECT attempts FROM auth_challenges") == 1


@pytest.mark.parametrize("code", ["12345", "1234567", "abcdef", ""])
def test_malformed_code_is_rejected(api, code):
    response = api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": code})

    assert response.status_code == 422


def test_expired_code_is_rejected(api):
    api.register(email=EMAIL)
    api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})
    api.clock.advance(601)

    response = api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": api.last_code(EMAIL)})

    assert response.status_code == 401
    assert "expiré" in response.json()["detail"]


def test_code_cannot_be_used_twice(api):
    api.register(email=EMAIL)
    api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})
    code = api.last_code(EMAIL)
    assert api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": code}).status_code == 201

    response = api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": code})

    assert response.status_code == 401
    assert scalar("SELECT count(*) FROM auth_sessions") == 1


def test_too_many_attempts_locks_the_code(api):
    api.register(email=EMAIL)
    api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})
    code = api.last_code(EMAIL)
    wrong = "000000" if code != "000000" else "111111"
    statuses = [
        api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": wrong}).status_code for _ in range(5)
    ]

    assert statuses == [401, 401, 401, 401, 429]
    response = api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": code})
    assert response.status_code == 429


def test_new_login_invalidates_the_previous_code(api, monkeypatch):
    codes = iter(["111111", "222222"])
    monkeypatch.setattr("app.services.auth.generate_otp_code", lambda: next(codes))
    api.register(email=EMAIL)
    api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})
    api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})

    assert api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": "111111"}).status_code == 401
    assert api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": "222222"}).status_code == 201


# --- Renvoi du code --------------------------------------------------------------------------------

def test_resend_code_after_cooldown(api, monkeypatch):
    codes = iter(["111111", "222222"])
    monkeypatch.setattr("app.services.auth.generate_otp_code", lambda: next(codes))
    api.register(email=EMAIL)
    first = api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD}).json()

    too_soon = api.client.post("/api/v1/auth-challenges/resends", json={"email": EMAIL})
    assert too_soon.status_code == 429
    assert 0 < int(too_soon.headers["Retry-After"]) <= 60

    api.clock.advance(60)
    response = api.client.post("/api/v1/auth-challenges/resends", json={"email": EMAIL})

    assert response.status_code == 201
    assert response.json()["id_auth_challenges"] != first["id_auth_challenges"]
    assert len(api.outbox.outbox) == 2
    assert api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": "111111"}).status_code == 401
    assert api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": "222222"}).status_code == 201


def test_resend_after_too_many_attempts_gives_a_fresh_code(api):
    api.register(email=EMAIL)
    api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})
    wrong = "000000" if api.last_code(EMAIL) != "000000" else "111111"
    for _ in range(5):
        api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": wrong})
    api.clock.advance(60)

    assert api.client.post("/api/v1/auth-challenges/resends", json={"email": EMAIL}).status_code == 201
    response = api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": api.last_code(EMAIL)})
    assert response.status_code == 201


def test_resend_without_pending_login(api):
    api.register(email=EMAIL)

    assert api.client.post("/api/v1/auth-challenges/resends", json={"email": EMAIL}).status_code == 404
    assert api.client.post("/api/v1/auth-challenges/resends", json={"email": "x@example.com"}).status_code == 404

    api.login(EMAIL)
    api.clock.advance(60)
    assert api.client.post("/api/v1/auth-challenges/resends", json={"email": EMAIL}).status_code == 404


def test_codes_are_limited_per_hour(api):
    api.register(email=EMAIL)
    for _ in range(5):
        assert api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD}).status_code == 201
        api.clock.advance(61)

    response = api.client.post("/api/v1/auth-challenges/resends", json={"email": EMAIL})
    assert response.status_code == 429
    assert api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD}).status_code == 429

    api.clock.advance(3600)
    assert api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD}).status_code == 201


# --- Sessions --------------------------------------------------------------------------------------

def test_protected_route_without_token(client):
    response = client.get("/api/v1/users/me")

    assert response.status_code == 401
    assert response.headers["WWW-Authenticate"] == "Bearer"


@pytest.mark.parametrize("header", ["Bearer inconnu", "Basic dXNlcjpwYXNz", "Bearer " + "x" * 300, "Bearer"])
def test_protected_route_with_invalid_token(client, header):
    response = client.get("/api/v1/users/me", headers={"Authorization": header})

    assert response.status_code == 401


def test_expired_token_is_rejected(api):
    api.register(email=EMAIL)
    headers = bearer(api.login(EMAIL))
    api.clock.advance(hours=168)

    assert api.client.get("/api/v1/users/me", headers=headers).status_code == 401


def test_logout_revokes_only_the_current_session(api):
    api.register(email=EMAIL)
    laptop = bearer(api.login(EMAIL))
    api.clock.advance(61)
    phone = bearer(api.login(EMAIL))

    response = api.client.delete("/api/v1/auth-sessions/current", headers=laptop)

    assert response.status_code == 204
    assert api.client.get("/api/v1/users/me", headers=laptop).status_code == 401
    assert api.client.delete("/api/v1/auth-sessions/current", headers=laptop).status_code == 401
    assert api.client.get("/api/v1/users/me", headers=phone).status_code == 200
    assert scalar("SELECT count(*) FROM auth_sessions WHERE revoked_at IS NOT NULL") == 1


def test_secrets_never_appear_in_responses(api):
    api.register(email=EMAIL)
    challenge = api.client.post("/api/v1/auth-challenges", json={"email": EMAIL, "password": DEFAULT_PASSWORD})
    session = api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": api.last_code(EMAIL)})
    me = api.client.get("/api/v1/users/me", headers=bearer(session.json()["token"]))

    stored_hash = scalar("SELECT password FROM users")
    stored_token = scalar("SELECT token FROM auth_sessions")
    for response in (challenge, session, me):
        assert DEFAULT_PASSWORD not in response.text
        assert stored_hash not in response.text
        assert stored_token not in response.text
        assert "password" not in response.text
