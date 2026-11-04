# Contrat de l'API

Référence des routes et des règles appliquées par le backend. Pour les appels depuis le jeu, avec des exemples GDScript, voir [api-godot.md](api-godot.md). La documentation interactive (Swagger) est servie par l'API elle-même sur `/api/docs`.

## Conventions

- Toutes les routes commencent par `/api/v1`. Les ressources sont au pluriel, en kebab-case : `/users`, `/game-sessions`, `/puzzle-progress`.
- Corps de requête et de réponse en JSON. Un champ inconnu est refusé (422) : le client ne peut pas glisser `status` ou `elapsed_seconds` dans une sauvegarde.
- Routes protégées : en-tête `Authorization: Bearer <token>`.
- Erreurs : `{"detail": "message en français"}`. Les erreurs de validation (422) renvoient une liste, un élément par champ fautif.
- Dates en UTC, au format ISO 8601. Durées en secondes (`elapsed_seconds`) ou en millisecondes (`completion_time_ms`).
- Les identifiants gardent le nom des colonnes : `id_users`, `id_game_sessions`, `id_puzzles`, `id_puzzle_progress`.

## Routes

| Méthode | Route | Auth | Succès | Rôle |
| --- | --- | --- | --- | --- |
| GET | `/health` | non | 200 | État de l'API (inchangé) |
| GET | `/health/database` | non | 200 / 503 | État de PostgreSQL, utilisé par le healthcheck Docker (inchangé) |
| POST | `/users` | non | 201 | Créer un compte |
| GET | `/users/me` | oui | 200 | Profil du joueur connecté |
| POST | `/auth-challenges` | non | 201 | Vérifier le mot de passe et envoyer un code par e-mail |
| POST | `/auth-challenges/resends` | non | 201 | Renvoyer un code |
| POST | `/auth-sessions` | non | 201 | Valider le code et ouvrir une session (renvoie le token) |
| DELETE | `/auth-sessions/current` | oui | 204 | Se déconnecter |
| POST | `/game-sessions` | oui | 201 | Créer une partie (démarre le chronomètre) |
| GET | `/game-sessions` | oui | 200 | Lister ses parties (`status`, `limit`, `offset`) |
| GET | `/game-sessions/{id}` | oui | 200 | Récupérer une partie |
| PATCH | `/game-sessions/{id}` | oui | 200 | Sauvegarder niveau et position |
| POST | `/game-sessions/{id}/pauses` | oui | 200 | Mettre en pause |
| POST | `/game-sessions/{id}/resumptions` | oui | 200 | Reprendre |
| POST | `/game-sessions/{id}/penalties` | oui | 200 | Pénalité de 5 minutes |
| POST | `/game-sessions/{id}/completions` | oui | 200 | Valider la victoire |
| POST | `/game-sessions/{id}/abandonments` | oui | 200 | Abandonner |
| GET | `/game-sessions/{id}/progress` | oui | 200 | Chronomètre, livres et état de chaque énigme |
| POST | `/game-sessions/imports` | oui | 201 | Importer une partie jouée en invité |
| GET | `/puzzles` | non | 200 | Lister les énigmes |
| GET | `/puzzles/{id}` | non | 200 | Détail d'une énigme |
| GET | `/game-sessions/{id}/puzzle-progress` | oui | 200 | Progression des énigmes de la partie |
| POST | `/game-sessions/{id}/puzzle-progress` | oui | 201 / 200 | Commencer une énigme (200 si déjà commencée) |
| PATCH | `/game-sessions/{id}/puzzle-progress/{progress_id}` | oui | 200 | Enregistrer la résolution : `{"solved": true}` |
| POST | `/game-sessions/{id}/puzzle-progress/{progress_id}/hints` | oui | 200 | Utiliser un indice |
| GET | `/leaderboards` | non | 200 | Classement général |
| GET | `/puzzles/{id}/leaderboards` | non | 200 | Classement d'une énigme |

Écarts avec la liste de départ :

- **Pas de `/auth-challenges/verifications`** : `POST /auth-sessions` vérifie le code et ouvre la session dans la même requête. Une route de vérification séparée obligerait le client à déclarer qu'un code a été validé.
- **`/penalties` ajoutée**, pour suivre `GameState.penalize()` de Godot.
- **`POST /puzzle-progress` commence l'énigme** et `PATCH` enregistre sa résolution : la ligne de progression doit exister avant la résolution pour qu'on puisse y consommer des indices.

### Codes d'erreur

| Code | Cas |
| --- | --- |
| 401 | Token absent, inconnu, expiré ou révoqué ; mot de passe ou code 2FA incorrect, expiré ou déjà utilisé |
| 404 | Ressource inexistante, **ou appartenant à un autre joueur** : l'API ne révèle pas son existence |
| 409 | Transition impossible : partie terminée, en pause, temps écoulé, énigme verrouillée ou déjà résolue, plus d'indice, partie déjà en cours, e-mail déjà utilisé |
| 422 | Données invalides, champ inconnu ou interdit, incohérence dans un import |
| 429 | Trop de tentatives ou de codes demandés ; l'en-tête `Retry-After` donne l'attente en secondes |
| 503 | Base de données injoignable, ou e-mail impossible à envoyer |

## Règles du jeu

### États d'une partie

```text
in_progress ──► completed    victoire validée
            ├─► game_over    temps écoulé, décidé par le serveur seul
            └─► abandoned    abandon du joueur
```

Une partie terminée ne change plus : toute écriture répond 409. Un joueur n'a qu'une partie `in_progress` à la fois ; en créer une seconde répond 409 avec l'identifiant de celle en cours.

### Chronomètre

60 minutes par partie (`GAME_DURATION_SECONDS`, 3600 par défaut), comme `GameState.TOTAL_TIME` dans Godot.

- `timer_started_at` : instant du démarrage ou de la dernière reprise, `NULL` quand le chronomètre est arrêté.
- `elapsed_seconds` : temps consommé avant cet instant, pénalités comprises.
- Temps consommé à l'instant t : `elapsed_seconds + (t - timer_started_at)`, calculé avec l'heure du serveur. Le client n'envoie jamais de temps.

Le chronomètre démarre à la création de la partie. Il continue dans le hub, dans les zones, et quand le navigateur est fermé : seule une pause demandée par le joueur l'arrête. À la pause, le temps est arrondi à la seconde supérieure, si bien qu'enchaîner pauses et reprises ne fait jamais gagner de temps.

Avant toute lecture ou écriture d'une partie, le serveur vérifie le temps : s'il est écoulé, la partie passe en `game_over`, datée de l'instant exact de l'éruption, et l'écriture demandée répond 409.

Une pénalité ajoute 300 secondes (`PENALTY_SECONDS`) au temps consommé. Elle est permise même en pause, puisqu'elle ne fait que coûter du temps.

Pendant une pause, on peut sauvegarder la position, appliquer une pénalité ou abandonner. Commencer ou résoudre une énigme, utiliser un indice et valider la victoire exigent un chronomètre en marche.

### Énigmes et livres

Quatre énigmes, communes à tous les joueurs, insérées par la migration Alembic `7b2f4c9e1a35`. Leur `order_index` suit `GameState.ZONE_ORDER` :

| `order_index` | Zone Godot | Livre | Titre |
| --- | --- | --- | --- |
| 1 | `plaine` | `projenomicon` | La discussion oubliée |
| 2 | `desert` | `algonicon` | Les runes de l'algorithme |
| 3 | `marais` | `logiconomicon` | Le tombeau des lettres oubliées |
| 4 | `village` | `codonomicon` | Les cinq codes oubliés |

Les identifiants (`id_puzzles`) peuvent différer d'une base à l'autre : le jeu doit les lire dans `GET /puzzles`, jamais les écrire en dur.

- Un livre est obtenu quand son énigme est résolue : `puzzle_progress.solved_at IS NOT NULL`. Aucune table d'inventaire.
- Les énigmes se commencent et se résolvent dans l'ordre : la précédente doit être résolue.
- Une énigme ne se résout qu'une fois.
- Chaque énigme a 3 indices (`hint_count` en base, exposé sous le nom `hints_count`). Godot n'a pas encore de mécanique d'indices : la valeur se change par une nouvelle migration.
- `completion_time_ms` est mesuré par le serveur : temps de jeu (pauses exclues, pénalités incluses) depuis la résolution précédente, ou depuis le début de la partie pour la première énigme. Il comprend donc le trajet depuis le hub et le dépôt du livre précédent, qui sont les mêmes pour tous les joueurs.

### Victoire

`POST /completions` avec `{"placed_puzzle_ids": [...]}` réussit si, avant la fin du temps et hors pause :

1. toutes les énigmes sont résolues côté serveur ;
2. `placed_puzzle_ids` contient exactement les identifiants de toutes les énigmes.

Le schéma n'a pas de colonne pour les livres posés au château. La liste des livres posés est donc une déclaration du client, contrôlée seulement contre les énigmes résolues. Conséquence : en reprenant une partie sur un autre appareil, les livres résolus reviennent « en main » et doivent être reposés au château. Pour les conserver, il faudrait une colonne `puzzle_progress.placed_at`, écartée pour l'instant afin de ne pas modifier le schéma de production.

### Classements

- Une ligne par joueur, avec son meilleur résultat.
- Seules comptent les parties `completed` dont toutes les résolutions ont un temps mesuré par le serveur. Les parties `game_over`, `abandoned`, importées ou contenant une résolution invraisemblable sont exclues.
- Classement général : tri par `elapsed_seconds` croissant. Classement d'une énigme : tri par `completion_time_ms` croissant.
- Égalités : même rang (1, 2, 2, 4), puis le premier à avoir réalisé le temps passe devant. L'ordre est déterministe.
- Pagination `limit` (1 à 100, 20 par défaut) et `offset`. Les rangs restent globaux d'une page à l'autre.
- Champs exposés : rang, nom du joueur, temps, temps formaté, date. Ni e-mail ni identifiant.

## Mode invité

Un invité joue sans compte : sa progression reste dans la sauvegarde locale de Godot, et rien n'est créé en base. En créant un compte, il peut la rattacher à ce compte avec `POST /game-sessions/imports`, qui exige une session.

**Politique retenue : l'import est accepté, mais une partie importée n'entre jamais dans les classements.** Le serveur n'a vu aucune des actions de l'invité, et le schéma ne permet aucune preuve cryptographique d'une partie jouée hors ligne : il ne peut pas garantir qu'elle est authentique.

Contrôles appliqués à l'import, qui répondent 422 en cas d'échec :

- énigmes existantes, sans doublon, résolues dans l'ordre (les N premières) ;
- indices utilisés entre 0 et `hints_count` ;
- temps consommé entre 0 et la durée de la partie ;
- état cohérent avec le temps : `in_progress` avec du temps restant, `game_over` avec tout le temps consommé, `completed` avec toutes les énigmes résolues et un temps total plausible ;
- niveau et position valides, aucun champ inconnu (par exemple `completion_time_ms`).

Les résolutions importées sont enregistrées sans `completion_time_ms`, ce qui exclut la partie des classements, même si le joueur la termine ensuite en ligne. Une partie `in_progress` est importée en pause : le chronomètre repart avec `POST /resumptions`.

Un import `in_progress` sans aucune énigme résolue reste classable : il équivaut à une partie neuve, puisque tout ce qui suit est chronométré par le serveur et qu'un temps déclaré plus faible ne donne aucun avantage par rapport à une nouvelle partie.

## Sécurité

| Sujet | Mesure |
| --- | --- |
| Mots de passe | Argon2id (argon2-cffi), 8 à 128 caractères avec au moins une lettre et un chiffre ; le hash n'est jamais renvoyé |
| E-mails | Uniques, comparés sans tenir compte de la casse, enregistrés en minuscules |
| Codes 2FA | 6 chiffres tirés avec `secrets`, stockés en HMAC-SHA256 avec `SECRET_KEY`, valables 10 minutes, à usage unique, 5 essais ; un nouveau code invalide le précédent |
| Renvoi de code | 60 secondes entre deux envois, 5 codes par heure et par compte |
| Mots de passe erronés | 10 échecs en 15 minutes sur une adresse bloquent la connexion temporairement (429) |
| Sessions | Token de 256 bits stocké en SHA-256, valable 7 jours, révocable ; une session par appareil |
| Autorisations | Chaque partie et chaque progression sont filtrées par propriétaire ; celles d'un autre joueur répondent 404 |
| Concurrence | Verrous de ligne (`SELECT … FOR UPDATE`) sur la partie, la progression et le code 2FA, pour éviter les doubles résolutions ou les doubles validations |
| Intégrité | Statut, temps et dates calculés par le serveur ; positions bornées à ±10 000 ; identifiants bornés à la taille d'un `INTEGER` |
| CORS | Désactivé par défaut : le jeu et l'API partagent le domaine de Caddy. `CORS_ALLOWED_ORIGINS` liste explicitement les origines autorisées en développement, sans cookies |
| Secrets | Variables d'environnement uniquement ; aucun secret dans le dépôt ni dans les logs, sauf le code 2FA avec `EMAIL_BACKEND=console`, réservé au développement |

### Ce que le serveur ne peut pas garantir

- **Qu'une énigme a vraiment été résolue.** La logique des énigmes s'exécute dans Godot et leurs solutions sont publiques (README, code du jeu). `{"solved": true}` reste une déclaration du client. Le serveur garantit l'ordre, l'unicité, la mesure du temps et le respect du chronomètre. Une résolution plus rapide que `PUZZLE_MIN_SOLVE_SECONDS` (30 s) est acceptée pour ne pas bloquer le jeu, mais elle fait sortir la partie du classement. Un tricheur qui scripte des appels réalistes peut toutefois obtenir un temps classé.
- **Que les livres ont été posés**, faute de colonne : voir la section Victoire.
- **Que la position envoyée est réelle** : le serveur ne connaît pas la géométrie des niveaux.
- **La limitation des échecs de mot de passe est gardée en mémoire** : elle est remise à zéro au redémarrage de l'API, et suppose un seul conteneur. Elle permet aussi à un tiers de bloquer temporairement la connexion d'une adresse qu'il connaît.

Une validation plus solide demanderait d'envoyer la réponse de chaque énigme au serveur, avec des solutions qui ne figurent plus dans le dépôt public. C'est un chantier à arbitrer avec l'équipe Godot.

## Configuration

Toutes les variables sont décrites dans `backend/.env.example` (développement) et `infrastructure/.env.example` (production). En production :

| Variable | Rôle |
| --- | --- |
| `SECRET_KEY` | Clé HMAC des codes 2FA. Sans elle, une clé temporaire est tirée à chaque démarrage |
| `EMAIL_BACKEND` | `smtp` par défaut en production. Sans `SMTP_HOST`, la connexion répond 503 |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_SECURITY`, `EMAIL_FROM` | Fournisseur d'e-mails |
| `CORS_ALLOWED_ORIGINS` | Vide en production |

## Déploiement

Le déploiement automatique (`cdp-deploy`) reconstruit les images mais **n'exécute pas les migrations**. Avant le premier déploiement de cette version :

1. Ajouter `SECRET_KEY` et la configuration SMTP dans `/opt/cdp-2026/.env` sur le serveur.
2. Déployer, puis appliquer la migration des énigmes :

   ```sh
   docker compose -f infrastructure/docker-compose.prod.yml --env-file /opt/cdp-2026/.env exec api alembic upgrade head
   ```

   Elle ne fait qu'insérer les quatre énigmes (`ON CONFLICT DO NOTHING`), sans changer le schéma : sans elle, l'API fonctionne, mais la liste des énigmes est vide.

Les routes `/api/v1/health` et `/api/v1/health/database` gardent leur comportement : les healthchecks Docker ne changent pas.

## Tests

Les tests ont besoin d'une base PostgreSQL dédiée, dont le nom contient `test` : elle est **entièrement vidée** à chaque lancement. Avec la base de développement de `infrastructure/docker-compose.yml` :

```sh
docker compose -f infrastructure/docker-compose.yml exec db createdb -U escape_user escape_game_test
cd backend
pip install -r requirements.txt -r requirements-dev.txt
TEST_DATABASE_URL=postgresql+psycopg://escape_user:escape_dev_password@localhost:5433/escape_game_test python -m pytest
```

Sans `TEST_DATABASE_URL`, les tests d'API sont ignorés en local. En CI, le workflow démarre un service `postgres:17` jetable, et une variable manquante fait échouer les tests.
