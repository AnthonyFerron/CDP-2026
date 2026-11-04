# Brancher Godot sur l'API

Ce guide montre comment le jeu appelle l'API, étape par étape, en partant des fonctions existantes de `GameState` (`frontend/scripts/game_state.gd`). Les règles complètes sont dans [api-contract.md](api-contract.md), et chaque route est décrite dans Swagger, sur `/api/docs` (par exemple <https://codequest.anthonyferron.com/api/docs> une fois l'API déployée).

## Principes

- Le serveur est la référence pour le temps : Godot affiche `remaining_seconds` reçu de l'API et décompte localement entre deux réponses, mais n'envoie jamais de durée.
- Le serveur ne connaît que ce que Godot lui dit : il faut l'appeler à chaque étape clé (début de mission, énigme commencée, énigme résolue, pénalité, victoire).
- La sauvegarde locale (`user://sauvegarde.cfg`) reste utile : elle sert au mode invité et garde les livres posés, que le serveur ne stocke pas.

## Client HTTP

Un autoload `Api` qui envoie le token et décode le JSON. À déclarer dans `project.godot` à côté de `GameState`.

```gdscript
extends Node
## Appels à l'API CDP-2026. Chaque appel renvoie {"code": int, "data": Variant} ; code 0 : réseau injoignable.

const TOKEN_PATH := "user://session.cfg"
## Utilisée hors navigateur (lancement depuis l'éditeur).
const DEFAULT_BASE_URL := "https://codequest.anthonyferron.com/api/v1"

var token := ""


func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(TOKEN_PATH) == OK:
		token = file.get_value("session", "token", "")


func base_url() -> String:
	if OS.has_feature("web"):
		# Le jeu et l'API sont servis par le même domaine : pas de CORS en production.
		return str(JavaScriptBridge.eval("window.location.origin")) + "/api/v1"
	return DEFAULT_BASE_URL


func request(method: HTTPClient.Method, path: String, body: Variant = null) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	var payload := "" if body == null else JSON.stringify(body)
	if http.request(base_url() + path, headers, method, payload) != OK:
		http.queue_free()
		return {"code": 0, "data": null}
	var response: Array = await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS:
		return {"code": 0, "data": null}
	var text: String = response[3].get_string_from_utf8()
	return {"code": response[1], "data": JSON.parse_string(text) if not text.is_empty() else null}


func save_token(new_token: String) -> void:
	token = new_token
	var file := ConfigFile.new()
	file.set_value("session", "token", token)
	file.save(TOKEN_PATH)


func clear_token() -> void:
	token = ""
	DirAccess.remove_absolute(TOKEN_PATH)
```

Gérer les réponses ainsi :

| Code | Réaction |
| --- | --- |
| 200, 201, 204 | Succès |
| 401 sur une route protégée | Token expiré ou révoqué : `Api.clear_token()`, puis écran de connexion |
| 404 | Partie ou progression introuvable : relire `GET /game-sessions?status=in_progress` |
| 409 | L'état a changé (partie en pause, terminée, temps écoulé) : afficher `data.detail` et relire la partie |
| 422 | Données refusées : `data.detail` est une liste quand la validation du format échoue, une phrase sinon |
| 429 | Attendre avant de réessayer ; le message l'indique |
| 0 ou 503 | Serveur injoignable : garder la sauvegarde locale et réessayer plus tard |

## Compte et connexion

### Créer un compte

```gdscript
var r := await Api.request(HTTPClient.METHOD_POST, "/users",
	{"username": "Devlyn", "email": "devlyn@example.com", "password": "Volcan2026"})
# 201 : compte créé, enchaîner sur la connexion. 409 : e-mail déjà utilisé. 422 : champ invalide.
```

Règles : nom de 3 à 50 caractères (lettres, chiffres, espaces, `_ - . '`), mot de passe de 8 à 128 caractères avec au moins une lettre et un chiffre.

### Se connecter (deux étapes)

1. Mot de passe : le serveur envoie un code à six chiffres par e-mail.

   ```gdscript
   var r := await Api.request(HTTPClient.METHOD_POST, "/auth-challenges",
   	{"email": email, "password": password})
   # 201 : afficher l'écran du code, avec r.data.email_masked (« d***@example.com »).
   # 401 : identifiants incorrects. 429 : trop d'essais, réessayer plus tard.
   ```

2. Code : la session s'ouvre et le token arrive.

   ```gdscript
   var s := await Api.request(HTTPClient.METHOD_POST, "/auth-sessions", {"email": email, "code": code})
   if s.code == 201:
   	Api.save_token(s.data.token)
   # 401 : code faux (le message donne les essais restants), expiré ou déjà utilisé.
   # 429 : 5 essais ratés, il faut un nouveau code.
   ```

Le code est valable 10 minutes. Le bouton « Renvoyer le code » appelle `POST /auth-challenges/resends` avec `{"email": email}`, au plus une fois par minute (`r.data.resend_available_at` donne l'heure à partir de laquelle c'est possible).

### Token

- Le token est renvoyé une seule fois ; le garder dans `user://session.cfg`. Dans le navigateur, `user://` est stocké dans l'IndexedDB du site.
- L'envoyer uniquement dans l'en-tête `Authorization`, jamais dans une URL, et ne jamais l'afficher avec `print()`.
- Il est valable 7 jours. Chaque appareil a le sien.
- Déconnexion : `DELETE /auth-sessions/current` (réponse 204), puis `Api.clear_token()`.

## Partie

Garder `id_game_sessions` dans `GameState` et dans la sauvegarde locale, pour savoir à quelle partie serveur elle correspond.

### Identifiants des énigmes

Au lancement, lire les énigmes et faire le lien avec les zones par `order_index`, qui suit `ZONE_ORDER` :

```gdscript
var puzzle_ids := {}  # zone -> id_puzzles

func load_puzzles() -> void:
	var r := await Api.request(HTTPClient.METHOD_GET, "/puzzles")
	for puzzle: Dictionary in r.data:
		puzzle_ids[GameState.ZONE_ORDER[int(puzzle.order_index) - 1]] = int(puzzle.id_puzzles)
```

Ne jamais écrire les `id_puzzles` en dur : ils peuvent changer d'une base à l'autre.

### Quand appeler l'API

| Moment dans Godot | Appel |
| --- | --- |
| `begin_mission()` : le chronomètre démarre | `POST /game-sessions` avec `{"current_level": "hub"}`, garder `id_game_sessions` |
| `enter_zone(zone)` | `PATCH /game-sessions/{id}` avec `{"current_level": zone}`, puis `POST /game-sessions/{id}/puzzle-progress` avec `{"id_puzzles": puzzle_ids[zone]}` : garder `id_puzzle_progress` |
| `return_to_hub(zone)` | `PATCH /game-sessions/{id}` avec `{"current_level": "hub"}` |
| Sauvegarde périodique (`SAVE_INTERVAL`) | `PATCH /game-sessions/{id}` avec la position, pas plus d'une fois toutes les 15 à 30 secondes |
| `penalize()` | `POST /game-sessions/{id}/penalties` ; si `status` vaut `game_over`, lancer l'éruption |
| `collect_book(book)` | `PATCH /game-sessions/{id}/puzzle-progress/{id_puzzle_progress}` avec `{"solved": true}` |
| `place_book(book)` du quatrième livre | `POST /game-sessions/{id}/completions` |
| Menu pause | `POST /game-sessions/{id}/pauses`, puis `POST /game-sessions/{id}/resumptions` |
| `_erupt()` | `GET /game-sessions/{id}` pour confirmer `game_over` |
| « Recommencer » | Si la partie est encore `in_progress` : `POST /game-sessions/{id}/abandonments`, puis nouvelle partie au prochain `begin_mission()` |

Un joueur n'a qu'une partie en cours : `POST /game-sessions` répond 409 tant que la précédente n'est ni gagnée, ni perdue, ni abandonnée.

### Sauvegarder la position

```gdscript
await Api.request(HTTPClient.METHOD_PATCH, "/game-sessions/%d" % game_id, {
	"current_level": "desert",
	"position_x": player.global_position.x,
	"position_y": player.global_position.y,
	"position_z": player.global_position.z,
	"rotation_y": player.rotation.y,  # en radians
})
```

Seuls ces cinq champs sont acceptés. `current_level` vaut `hub`, `plaine`, `desert`, `marais` ou `village` ; un nouveau niveau doit d'abord être ajouté côté API (`Level` dans `backend/app/schemas/game_sessions.py`).

### Chronomètre

Chaque réponse sur une partie contient :

```json
{
  "status": "in_progress",
  "elapsed_seconds": 1250.5,
  "remaining_seconds": 2349.5,
  "duration_seconds": 3600,
  "is_paused": false
}
```

Recaler `GameState.time_left = remaining_seconds` à chaque réponse, et continuer à décompter localement entre deux appels. Le temps continue de courir quand le navigateur est fermé : seule une pause demandée par le joueur l'arrête. Pendant une pause, résoudre une énigme, utiliser un indice ou valider la victoire répond 409.

### Reprendre une partie (même ou autre appareil)

Après la connexion :

```gdscript
var r := await Api.request(HTTPClient.METHOD_GET, "/game-sessions?status=in_progress&limit=1")
if r.data.items.is_empty():
	return  # aucune partie en cours : nouvelle partie au prochain begin_mission()
var game: Dictionary = r.data.items[0]
var progress := await Api.request(HTTPClient.METHOD_GET, "/game-sessions/%d/progress" % game.id_game_sessions)
```

Puis remplir `GameState` :

- `intro_done = true`, `time_left = game.remaining_seconds`, `last_zone` selon `game.current_level` ;
- `books` : le livre de chaque énigme où `is_solved` est vrai dans `progress.data.puzzles` ;
- `placed_books` : à reprendre de la sauvegarde locale si elle porte le même `id_game_sessions`. Sinon (autre appareil), laisser vide : le serveur ne garde pas les livres posés, et le joueur devra reposer au château les livres qu'il a déjà trouvés ;
- si `game.is_paused` est vrai, appeler `/resumptions` quand le joueur reprend la main.

## Énigmes et livres

`GET /game-sessions/{id}/progress` résume tout :

```json
{
  "books_obtained": 2,
  "total_books": 4,
  "can_complete": false,
  "puzzles": [
    {"id_puzzles": 1, "order_index": 1, "is_unlocked": true, "is_started": true, "is_solved": true,
     "id_puzzle_progress": 7, "completion_time_ms": 312400, "hints_used": 1, "hints_remaining": 2},
    {"id_puzzles": 2, "order_index": 2, "is_unlocked": true, "is_started": false, "is_solved": false,
     "id_puzzle_progress": null, "completion_time_ms": null, "hints_used": 0, "hints_remaining": 3}
  ]
}
```

- Un livre est obtenu quand son énigme est résolue (`is_solved`).
- Commencer une énigme (`POST /puzzle-progress`) peut être rappelé sans risque : la deuxième fois, l'API renvoie la même progression avec le code 200.
- Les énigmes se commencent dans l'ordre : sinon 409 « Énigme verrouillée ».
- Indice : `POST /game-sessions/{id}/puzzle-progress/{id_puzzle_progress}/hints`, 3 par énigme ; au-delà, 409. Le texte des indices reste dans Godot.
- Le serveur mesure lui-même `completion_time_ms`.

## Victoire

Quand le quatrième livre est posé (`placed_books.size() == BOOK_COUNT`) :

```gdscript
var placed := []
for book: StringName in GameState.placed_books:
	for zone: StringName in GameState.ZONE_BOOKS:
		if GameState.ZONE_BOOKS[zone] == book:
			placed.append(puzzle_ids[zone])
var r := await Api.request(HTTPClient.METHOD_POST, "/game-sessions/%d/completions" % game_id,
	{"placed_puzzle_ids": placed})
# 200 : status vaut "completed", elapsed_seconds est le temps final.
# 409 : une énigme n'est pas résolue côté serveur, un livre manque, la partie est en pause, ou le temps est écoulé.
```

## Classements

Publics, sans token :

```gdscript
var general := await Api.request(HTTPClient.METHOD_GET, "/leaderboards?limit=10")
for entry: Dictionary in general.data.items:
	print("%d. %s  %s" % [entry.rank, entry.username, entry.time_formatted])  # « 1. Devlyn  42:07 »

var desert := await Api.request(HTTPClient.METHOD_GET, "/puzzles/%d/leaderboards?limit=10" % puzzle_ids[&"desert"])
# entry.time_formatted : « 03:12.480 »
```

Pages suivantes avec `offset` (`offset=10`, `offset=20`…) ; `total` donne le nombre de joueurs classés. Deux temps égaux partagent le même rang.

## Mode invité

Sans compte, le jeu fonctionne comme aujourd'hui, avec la seule sauvegarde locale. Quand l'invité crée un compte et se connecte, envoyer sa progression :

```gdscript
func guest_import_payload() -> Dictionary:
	var status := "in_progress"
	if GameState.has_erupted:
		status = "game_over"
	elif GameState.placed_books.size() == GameState.BOOK_COUNT:
		status = "completed"
	var solved := []
	for zone: StringName in GameState.ZONE_ORDER:
		if GameState.has_book(GameState.ZONE_BOOKS[zone]):
			solved.append({"id_puzzles": puzzle_ids[zone], "hints_used": 0})
	return {
		"status": status,
		"elapsed_seconds": GameState.TOTAL_TIME - GameState.time_left,
		"current_level": "hub",
		"solved_puzzles": solved,
	}

var r := await Api.request(HTTPClient.METHOD_POST, "/game-sessions/imports", guest_import_payload())
```

- 201 : la partie appartient au compte. Une partie `in_progress` arrive en pause : appeler `/resumptions` quand le joueur reprend.
- 409 : le compte a déjà une partie en cours.
- 422 : sauvegarde incohérente (temps négatif ou supérieur à 60 minutes, énigmes dans le désordre…).
- N'importer que si `intro_done` est vrai : avant la mission, il n'y a rien à transférer.
- Une partie importée n'entre jamais dans les classements (`is_rankable: false`) : le serveur n'a pas vu comment elle a été jouée. Le dire au joueur.

## Navigateur

- **HTTPS** : en production, Caddy sert le jeu et l'API sur le même domaine en HTTPS. Aucun appel en `http://`.
- **CORS** : inutile en production, puisque le domaine est le même. Pour un export Web lancé ailleurs (par exemple le serveur local de l'éditeur sur `http://localhost:8060`) vers une API de développement, ajouter l'origine dans `CORS_ALLOWED_ORIGINS` côté API. Lancé depuis l'éditeur en natif, le jeu n'est pas soumis au CORS.
- **Token** : il vit dans l'IndexedDB du site. Le jeu ne charge aucun script externe, ce qui limite le risque qu'il soit lu par un autre code de la page.
