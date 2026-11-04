"""Réponses d'erreur documentées dans Swagger. Les erreurs 422 de validation sont ajoutées par FastAPI."""

from typing import Any

from app.schemas.common import ErrorResponse

_DEFAULTS = {
    400: "Requête invalide.",
    401: "Token absent, invalide, expiré ou révoqué.",
    404: "Ressource introuvable, ou appartenant à un autre joueur.",
    409: "Conflit avec l'état actuel de la ressource.",
    429: "Trop de requêtes : attendre le nombre de secondes indiqué par l'en-tête Retry-After.",
    503: "Service indisponible.",
}


def errors(spec: dict[int, str | None]) -> dict[int | str, dict[str, Any]]:
    """`errors({401: None, 409: "Partie terminée."})` : None reprend la description par défaut."""
    return {
        code: {"model": ErrorResponse, "description": description or _DEFAULTS[code]}
        for code, description in spec.items()
    }


AUTH_ERRORS = errors({401: None})
GAME_ERRORS = errors({401: None, 404: "Partie introuvable, ou partie d'un autre joueur."})

TAGS = [
    {"name": "Santé", "description": "Disponibilité de l'API et de la base, utilisée par les healthchecks Docker."},
    {"name": "Utilisateurs", "description": "Création de compte et profil."},
    {
        "name": "Authentification",
        "description": "Connexion en deux étapes : mot de passe (POST /auth-challenges), puis code reçu par "
        "e-mail (POST /auth-sessions), qui renvoie le token à envoyer dans `Authorization: Bearer <token>`.",
    },
    {
        "name": "Parties",
        "description": "Parties du joueur connecté. Le chronomètre est calculé par le serveur ; le client ne "
        "peut modifier que son niveau et sa position.",
    },
    {
        "name": "Énigmes",
        "description": "Définition des énigmes et progression d'une partie. Une énigme résolue donne son livre.",
    },
    {
        "name": "Classements",
        "description": "Classements publics : meilleur temps de chaque joueur, parties gagnées et "
        "chronométrées par le serveur uniquement.",
    },
]
