"""Primitives de sécurité : mots de passe, codes 2FA et tokens de session.

- Mots de passe : Argon2id (argon2-cffi), algorithme recommandé par l'OWASP.
- Codes 2FA : six chiffres tirés avec `secrets`, stockés en HMAC-SHA256 avec la clé serveur. Un code
  n'a que un million de valeurs possibles : sans la clé, une fuite de la base ne permet pas de les
  retrouver par force brute.
- Tokens de session : 256 bits aléatoires, stockés en SHA-256. Leur entropie rend un sel inutile, et
  le hachage déterministe permet de retrouver la session par index.
"""

import hashlib
import hmac
import secrets

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError

from app.core.config import get_secret_key

_password_hasher = PasswordHasher()
_dummy_hash: str | None = None


def hash_password(password: str) -> str:
    return _password_hasher.hash(password)


def verify_password(password_hash: str, password: str) -> bool:
    try:
        return _password_hasher.verify(password_hash, password)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def password_needs_rehash(password_hash: str) -> bool:
    return _password_hasher.check_needs_rehash(password_hash)


def burn_password_check(password: str) -> None:
    """Fait le même travail qu'une vérification, pour qu'un e-mail inconnu ne réponde pas plus vite."""
    global _dummy_hash
    if _dummy_hash is None:
        _dummy_hash = _password_hasher.hash(secrets.token_urlsafe(16))
    verify_password(_dummy_hash, password)


def generate_otp_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def hash_otp_code(id_users: int, code: str) -> str:
    message = f"otp:{id_users}:{code}".encode()
    return hmac.new(get_secret_key(), message, hashlib.sha256).hexdigest()


def verify_otp_code(stored_hash: str, id_users: int, code: str) -> bool:
    return hmac.compare_digest(stored_hash, hash_otp_code(id_users, code))


def generate_session_token() -> str:
    return secrets.token_urlsafe(32)


def hash_session_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()
