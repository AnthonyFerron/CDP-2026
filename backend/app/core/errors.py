"""Erreurs métier, converties en réponses HTTP `{"detail": "..."}` par le gestionnaire de main.py."""

import math


class ApiError(Exception):
    status_code = 400

    def __init__(self, detail: str, *, headers: dict[str, str] | None = None):
        super().__init__(detail)
        self.detail = detail
        self.headers = headers


class BadRequestError(ApiError):
    status_code = 400


class UnauthorizedError(ApiError):
    status_code = 401

    def __init__(self, detail: str):
        super().__init__(detail, headers={"WWW-Authenticate": "Bearer"})


class NotFoundError(ApiError):
    status_code = 404


class ConflictError(ApiError):
    status_code = 409


class UnprocessableError(ApiError):
    status_code = 422


class TooManyRequestsError(ApiError):
    status_code = 429

    def __init__(self, detail: str, *, retry_after: float | None = None):
        headers = None
        if retry_after is not None:
            headers = {"Retry-After": str(max(1, math.ceil(retry_after)))}
        super().__init__(detail, headers=headers)


class ServiceUnavailableError(ApiError):
    status_code = 503
