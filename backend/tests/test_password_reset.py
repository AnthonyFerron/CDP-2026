"""Mot de passe oublié : lien envoyé par e-mail (JWT signé), puis nouveau mot de passe.

Aucun e-mail réel : la fixture `outbox` (MemoryEmailSender) garde les e-mails en mémoire.
"""

import json
import re
import smtplib

import jwt
import pytest
from jwt.utils import base64url_encode
from sqlalchemy import text

from app.core import reset_tokens
from app.core.config import get_secret_key
from app.core.reset_tokens import AUDIENCE, ISSUER, password_fingerprint
from app.core.security import verify_password
from app.db.session import engine
from app.main import app
from app.services.email import get_email_sender

from conftest import DEFAULT_PASSWORD, START, bearer

EMAIL = "devlyn@example.com"
# SECRET_KEY des tests (25 octets) employée telle quelle pour forger des jetons : PyJWT prévient qu'elle est
# courte. La vraie clé de signature, dérivée, fait toujours 32 octets.
SHORT_KEY_WARNING = pytest.mark.filterwarnings("ignore::jwt.warnings.InsecureKeyLengthWarning")
NEW_PASSWORD = "Lave2026"
RESET_LINK = re.compile(r"https://codequest\.anthonyferron\.com/reinitialisation\?token=([A-Za-z0-9_.\-]+)")


def scalar(sql: str, **params):
    with engine.connect() as connection:
        return connection.execute(text(sql), params).scalar()


def stored_hash(email: str = EMAIL) -> str:
    return scalar("SELECT password FROM users WHERE email = :email", email=email)


def request_reset(client, email: str = EMAIL):
    return client.post("/api/v1/password-resets", json={"email": email})


def confirm(client, token: str, password: str = NEW_PASSWORD):
    return client.post("/api/v1/password-resets/confirmations", json={"token": token, "password": password})


def mails_to(outbox, email: str = EMAIL) -> list:
    return [mail for mail in outbox.outbox if mail.to == email]


def last_token(outbox, email: str = EMAIL) -> str:
    return RESET_LINK.search(mails_to(outbox, email)[-1].body).group(1)


def login_status(client, password: str, email: str = EMAIL) -> int:
    return client.post("/api/v1/auth-challenges", json={"email": email, "password": password}).status_code


def valid_claims(id_users: int, password_hash: str) -> dict:
    issued_at = int(START.timestamp())
    return {
        "sub": str(id_users),
        "iss": ISSUER,
        "aud": AUDIENCE,
        "iat": issued_at,
        "exp": issued_at + 1800,
        "pwd": password_fingerprint(password_hash),
    }


# --- Demande ---------------------------------------------------------------------------------------------

@SHORT_KEY_WARNING
def test_request_sends_a_signed_link_by_email(api):
    user = api.register(email=EMAIL)

    response = request_reset(api.client, "Devlyn@Example.com")

    assert response.status_code == 202
    assert response.json()["expires_in_minutes"] == 30
    mails = mails_to(api.outbox)
    assert len(mails) == 1
    mail = mails[0]
    assert "mot de passe" in mail.subject
    assert "30 minutes" in mail.body
    assert stored_hash() not in mail.body and DEFAULT_PASSWORD not in mail.body

    token = last_token(api.outbox)
    header = jwt.get_unverified_header(token)
    claims = jwt.decode(token, options={"verify_signature": False})
    assert header["alg"] == "HS256"
    assert claims["sub"] == str(user["id_users"])
    assert (claims["iss"], claims["aud"]) == (ISSUER, AUDIENCE)
    assert claims["iat"] == int(START.timestamp())
    assert claims["exp"] - claims["iat"] == 1800
    assert claims["pwd"] == password_fingerprint(stored_hash())
    assert EMAIL not in token and "email" not in claims
    # Signé avec une clé dérivée, propre à cet usage : SECRET_KEY seule ne le vérifie pas.
    with pytest.raises(jwt.InvalidSignatureError):
        jwt.decode(token, get_secret_key(), algorithms=["HS256"], audience=AUDIENCE)


def test_unknown_account_gets_the_same_response(api):
    api.register(email=EMAIL)

    known = request_reset(api.client, EMAIL)
    unknown = request_reset(api.client, "inconnu@example.com")

    assert known.status_code == unknown.status_code == 202
    assert known.json() == unknown.json()
    assert set(known.headers) - {"content-length"} == set(unknown.headers) - {"content-length"}
    assert [mail.to for mail in api.outbox.outbox] == [EMAIL]


def test_request_rejects_invalid_bodies(client):
    assert request_reset(client, "pas-un-email").status_code == 422
    response = client.post("/api/v1/password-resets", json={"email": EMAIL, "id_users": 1})
    assert response.status_code == 422


def test_requests_are_rate_limited_per_address_whether_the_account_exists_or_not(api, clock):
    api.register(email=EMAIL)

    for email in (EMAIL, "inconnu@example.com"):
        assert request_reset(api.client, email).status_code == 202
        too_soon = request_reset(api.client, email)
        assert too_soon.status_code == 429
        assert int(too_soon.headers["Retry-After"]) == 60
    assert len(mails_to(api.outbox)) == 1

    for _ in range(4):
        clock.advance(61)
        assert request_reset(api.client, EMAIL).status_code == 202
    clock.advance(61)
    hourly = request_reset(api.client, EMAIL)
    assert hourly.status_code == 429
    assert "Trop de liens" in hourly.json()["detail"]
    assert len(mails_to(api.outbox)) == 5

    clock.advance(hours=1)
    assert request_reset(api.client, EMAIL).status_code == 202


class BrokenSender:
    def send(self, to, subject, body):
        raise smtplib.SMTPServerDisconnected("connexion perdue")


def test_email_failure_is_not_revealed(api):
    api.register(email=EMAIL)
    unknown = request_reset(api.client, "inconnu@example.com")
    app.dependency_overrides[get_email_sender] = lambda: BrokenSender()

    known = request_reset(api.client, EMAIL)

    assert known.status_code == 202
    assert known.json() == unknown.json()


# --- Confirmation ----------------------------------------------------------------------------------------

def test_valid_token_changes_the_password_and_closes_sessions(api):
    api.register(email=EMAIL)
    session = api.login(EMAIL)
    # Connexion commencée avec l'ancien mot de passe : son code ne doit plus servir.
    assert login_status(api.client, DEFAULT_PASSWORD) == 201
    pending_code = api.last_code(EMAIL)
    request_reset(api.client)

    response = confirm(api.client, last_token(api.outbox))

    assert response.status_code == 200
    assert "modifié" in response.json()["message"]
    stored = stored_hash()
    assert stored.startswith("$argon2id$") and verify_password(stored, NEW_PASSWORD)
    assert api.client.get("/api/v1/users/me", headers=bearer(session)).status_code == 401
    assert scalar("SELECT count(*) FROM auth_sessions WHERE revoked_at IS NULL") == 0
    stale = api.client.post("/api/v1/auth-sessions", json={"email": EMAIL, "code": pending_code})
    assert stale.status_code == 401
    assert login_status(api.client, DEFAULT_PASSWORD) == 401
    new_session = api.login(EMAIL, NEW_PASSWORD)
    assert api.client.get("/api/v1/users/me", headers=bearer(new_session)).status_code == 200


def test_token_is_valid_for_30_minutes(api, clock):
    api.register(email=EMAIL)
    request_reset(api.client)
    clock.advance(seconds=1799)

    assert confirm(api.client, last_token(api.outbox)).status_code == 200


def test_expired_token_is_refused(api, clock):
    api.register(email=EMAIL)
    request_reset(api.client)
    before = stored_hash()
    clock.advance(seconds=1800)

    response = confirm(api.client, last_token(api.outbox))

    assert response.status_code == 400
    assert "expiré" in response.json()["detail"]
    assert stored_hash() == before
    assert login_status(api.client, DEFAULT_PASSWORD) == 201


@SHORT_KEY_WARNING
@pytest.mark.parametrize(
    "forgery",
    ["autre clé", "SECRET_KEY sans dérivation", "algorithme none", "autre usage", "contenu modifié", "pas un JWT"],
)
def test_forged_tokens_are_refused(api, forgery):
    user = api.register(email=EMAIL)
    claims = valid_claims(user["id_users"], stored_hash())
    if forgery == "autre clé":
        token = jwt.encode(claims, b"une-autre-cle-tout-aussi-longue-que-la-vraie!", algorithm="HS256")
    elif forgery == "SECRET_KEY sans dérivation":
        token = jwt.encode(claims, get_secret_key(), algorithm="HS256")
    elif forgery == "algorithme none":
        token = jwt.encode(claims, None, algorithm="none")
    elif forgery == "autre usage":
        # Bonne clé, mais un jeton destiné à un autre usage est refusé par son audience.
        token = jwt.encode({**claims, "aud": "codequest:autre"}, reset_tokens._signing_key(), algorithm="HS256")
    elif forgery == "contenu modifié":
        request_reset(api.client)
        header, _, signature = last_token(api.outbox).split(".")
        payload = base64url_encode(json.dumps({**claims, "sub": "2"}).encode()).decode()
        token = f"{header}.{payload}.{signature}"
    else:
        token = "pas-un-jwt"
    before = stored_hash()

    response = confirm(api.client, token)

    assert response.status_code == 400
    assert "pas valide" in response.json()["detail"]
    assert stored_hash() == before


def test_token_cannot_be_reused_after_the_password_changed(api, clock):
    api.register(email=EMAIL)
    request_reset(api.client)
    first = last_token(api.outbox)
    clock.advance(61)
    request_reset(api.client)
    second = last_token(api.outbox)
    assert first != second

    assert confirm(api.client, second).status_code == 200
    changed = stored_hash()

    for token in (second, first):
        response = confirm(api.client, token, "Encore2026")
        assert response.status_code == 400
        assert "déjà servi" in response.json()["detail"]
    assert stored_hash() == changed
    assert login_status(api.client, NEW_PASSWORD) == 201


@pytest.mark.parametrize("password", ["court1", "sanschiffre", "12345678", "a1" * 65])
def test_weak_password_is_refused_like_at_registration(api, password):
    api.register(email=EMAIL)
    request_reset(api.client)
    token = last_token(api.outbox)
    before = stored_hash()

    response = confirm(api.client, token, password)

    assert response.status_code == 422
    assert stored_hash() == before
    # Un refus ne consomme pas le lien.
    assert confirm(api.client, token).status_code == 200


def test_confirmation_rejects_unknown_fields(api):
    api.register(email=EMAIL)
    request_reset(api.client)

    response = api.client.post(
        "/api/v1/password-resets/confirmations",
        json={"token": last_token(api.outbox), "password": NEW_PASSWORD, "id_users": 1},
    )

    assert response.status_code == 422
