extends Node
## Synchronisation de la partie d'un joueur connecté avec l'API : création et reprise, énigmes, livres posés,
## fragments de papier, pénalités, pauses, sauvegarde de la position, victoire et import d'une partie invitée.
##
## GameState reste le modèle que lisent les scènes ; ce fichier relaie ses changements au serveur et y
## applique les réponses. Pour un invité (ou le compte simulé du debug), il ne fait rien.
##
## Garanties :
## - une seule requête de partie à la fois, dans l'ordre des actions (commencer une énigme, la résoudre, poser
##   son livre, gagner) : pas de requêtes concurrentes contradictoires ;
## - une coupure réseau est retentée avec un délai croissant, sans perdre l'ordre ; le joueur est prévenu ;
## - les sauvegardes de position en attente sont fusionnées : seule la plus récente part ;
## - le temps affiché est celui du serveur, calculé à partir de sa dernière réponse : il ne s'arrête que lorsque
##   la pause est enregistrée par le serveur, et repart avec sa reprise ;
## - un conflit (409) est tranché en relisant l'état du serveur, pas en interprétant son message.

## Message court à afficher pendant le jeu (connexion perdue, rétablie, refus du serveur).
signal notice(text: String)
## L'état du serveur vient d'être chargé dans GameState, ou n'a pas pu l'être (menu).
signal synced

## Secondes entre deux sauvegardes de la position, qui servent aussi à recaler le chronomètre.
const SAVE_INTERVAL := 30.0
## Dans un niveau, le jeu figé plus longtemps que cela (pause, indices, transition) met le chronomètre du serveur
## en pause ; dans un menu, la pause part aussitôt.
const PAUSE_DELAY := 1.0
## Délais entre deux essais d'une requête restée sans réponse.
const BACKOFF: Array[float] = [1.0, 2.0, 4.0, 8.0, 15.0]
## Une erreur 500 n'est retentée que quelques fois : au-delà, c'est un défaut du serveur.
const SERVER_ERROR_ATTEMPTS := 2
const LEVELS: Array[StringName] = [&"hub", &"plaine", &"desert", &"marais", &"village"]

## Partie du serveur suivie, 0 sans partie.
var game_id := 0
## État de la partie sur le serveur : in_progress, completed, game_over, abandoned ; vide s'il est inconnu.
var status := ""
var server_paused := false
## Zone → id_puzzles, lu dans GET /puzzles (les identifiants changent d'une base à l'autre).
var puzzle_ids := {}
## Zone → id_puzzle_progress de la partie suivie.
var progress_ids := {}
## Dernier problème rencontré, pour le menu.
var last_error := ""

var _queue: Array[Action] = []
var _running := false
## Change quand la partie suivie change : les réponses d'une partie oubliée sont ignorées.
var _generation := 0
var _since_save := 0.0
var _frozen := false
var _frozen_for := 0.0
var _pause_requested := false
var _checking_time := false
var _offline := false
## Dernier temps restant donné par le serveur, et l'instant de sa réception (Time.get_ticks_msec()).
var _official_remaining := -1.0
var _official_at := 0
## Déconnexion en cours : le chronomètre du serveur reste en pause, même si le joueur est encore dans un niveau.
var _logging_out := false


class Action:
	extends RefCounted
	signal finished(result: Dictionary)
	var kind := ""
	var run: Callable
	var generation := 0
	var attempts := 0
	## Essais au-delà desquels une coupure réseau est rendue à l'appelant (-1 : sans limite).
	var max_attempts := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Account.session_changed.connect(_on_session_changed)
	Account.session_expired.connect(_on_session_expired)


## Un vrai compte est connecté : la partie est enregistrée sur le serveur.
func is_active() -> bool:
	return Account.is_online()


## Une partie connectée est en cours (ou en cours de création) sur le serveur.
func is_tracking() -> bool:
	return is_active() and GameState.intro_done and status in ["", "in_progress"]


# --- Relais des actions de GameState ----------------------------------------------------------------------

## La mission commence dans le bunker : la partie est créée, son chronomètre démarre sur le serveur.
func on_mission_started() -> void:
	if not is_active():
		return
	status = ""
	_pause_requested = false
	_enqueue("create", _run_create)


func on_level_changed(level: StringName) -> void:
	if not is_tracking():
		return
	if level in GameState.ZONE_ORDER:
		_enqueue("start", _run_start.bind(level))
	save_position()


## Livre trouvé : l'énigme de la zone est résolue.
func on_book_collected(book: StringName) -> void:
	var zone := _zone_of(book)
	if is_tracking() and zone != &"":
		_enqueue("solve", _run_solve.bind(zone))


## Livre posé sans attendre la confirmation (menu de debug) : le dépôt part quand même au serveur.
func on_book_placed(book: StringName) -> void:
	var zone := _zone_of(book)
	if is_tracking() and zone != &"":
		_enqueue("place", _run_place.bind(zone))


## Pose un livre et attend la réponse du serveur. GameState ne l'affiche posé qu'en cas de succès.
func place_book(book: StringName) -> Dictionary:
	var zone := _zone_of(book)
	if zone == &"":
		return {"ok": false, "error": "Livre inconnu."}
	var action := _enqueue("place", _run_place.bind(zone))
	return await action.finished


func on_fragment_collected(index: int) -> void:
	if is_tracking():
		_enqueue("fragment", _run_fragment.bind(index))


func on_penalty() -> void:
	if not is_tracking():
		return
	# Le temps affiché baisse tout de suite ; la réponse du serveur le confirmera.
	var current := official_remaining()
	if current >= 0.0:
		_official_remaining = maxf(0.0, current - GameState.PENALTY)
		_official_at = Time.get_ticks_msec()
	_enqueue("penalty", _run_simple.bind("penalties"))


## Temps restant officiel à cet instant, d'après la dernière réponse du serveur : il décompte tant que le
## chronomètre du serveur tourne, et reste figé quand le serveur a enregistré la pause. -1 s'il est inconnu.
func official_remaining() -> float:
	if not is_tracking() or game_id == 0 or status != "in_progress" or _official_remaining < 0.0:
		return -1.0
	if server_paused:
		return _official_remaining
	return maxf(0.0, _official_remaining - (Time.get_ticks_msec() - _official_at) / 1000.0)


## Avant la déconnexion : la pause du chronomètre est envoyée et attendue tant que le jeton est valide, pour
## que le temps ne coure pas sur le serveur pendant que le joueur n'est plus en jeu.
func pause_before_logout() -> void:
	if not is_tracking() or game_id == 0 or status != "in_progress":
		return
	_logging_out = true
	if not _pause_requested:
		_pause_requested = true
		_enqueue("pause", _run_simple.bind("pauses"))
	var deadline := Time.get_ticks_msec() + 5000
	while not is_idle() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


## Victoire : le serveur vérifie les quatre dépôts et le temps restant.
func complete() -> Dictionary:
	var action := _enqueue("complete", _run_complete)
	return await action.finished


## Sauvegarde du niveau et de la position ; une sauvegarde déjà en attente est remplacée.
func save_position() -> void:
	_since_save = 0.0
	if is_tracking():
		_enqueue("save", _run_save, true)


## Le chronomètre local est à zéro : seul le serveur déclare l'éruption. Sans réponse, elle a lieu ici.
func confirm_time_up() -> void:
	if _checking_time:
		return
	if _offline:
		GameState.erupt()
		return
	_checking_time = true
	var action := _enqueue("refresh", _run_refresh)
	action.max_attempts = 2
	var result: Dictionary = await action.finished
	_checking_time = false
	if not result.ok or status == "game_over":
		GameState.erupt()


## Nouvelle partie : la partie en cours sur le serveur (s'il y en a une) est abandonnée, puis oubliée.
func abandon_current() -> Dictionary:
	if not is_active():
		return {"ok": true}
	var action := _enqueue("abandon", _run_abandon)
	action.max_attempts = 3
	var result: Dictionary = await action.finished
	if result.ok:
		forget_game()
	return result


## La sauvegarde locale repart de zéro (nouvelle partie, changement de joueur) : la partie suivie est oubliée.
func forget_game() -> void:
	_generation += 1
	# Les actions en attente ne partiront pas : leurs appelants sont libérés. Celle en cours d'envoi le sera
	# à sa réponse, qui sera ignorée.
	var pending: Array[Action] = []
	while _queue.size() > (1 if _running else 0):
		pending.append(_queue.pop_back())
	for action in pending:
		action.finished.emit({"ok": false, "error": "", "stale": true})
	game_id = 0
	status = ""
	server_paused = false
	_pause_requested = false
	_official_remaining = -1.0
	_logging_out = false
	progress_ids.clear()


# --- Menu : reprise et import -----------------------------------------------------------------------------

## Charge dans GameState la partie en cours sur le serveur, pour reprendre sur n'importe quel appareil.
func sync_with_server() -> Dictionary:
	if not is_active():
		return {"ok": true}
	var action := _enqueue("sync", _run_sync)
	action.max_attempts = 2
	var result: Dictionary = await action.finished
	last_error = "" if result.ok else str(result.get("error", ""))
	synced.emit()
	return result


## Partie invitée de cet appareil, rattachable au compte : en cours (mission commencée) ou gagnée.
func guest_import_candidate() -> Dictionary:
	var save := GameState.read_save(GameState.SAVE_PATH)
	if save.is_empty() or not save.intro_done or save.has_erupted:
		return {}
	return save


## Rattache au compte la partie invitée de cet appareil (POST /game-sessions/imports). Elle ne comptera
## jamais pour le classement. En cas de succès, elle devient la partie du compte et la sauvegarde invitée
## repart de zéro.
func import_guest_game() -> Dictionary:
	var save := guest_import_candidate()
	if save.is_empty():
		return {"ok": false, "error": "Aucune partie invitée à rattacher."}
	var action := _enqueue("import", _run_import.bind(save))
	action.max_attempts = 2
	var result: Dictionary = await action.finished
	if result.ok:
		GameState.clear_save(GameState.SAVE_PATH)
	return result


# --- File d'actions ---------------------------------------------------------------------------------------

func _enqueue(kind: String, run: Callable, coalesce := false) -> Action:
	if coalesce:
		# L'action de tête est en cours d'envoi : seules les suivantes, en attente, sont fusionnées.
		for index in range(1, _queue.size()):
			if _queue[index].kind == kind:
				_queue[index].run = run
				return _queue[index]
	var action := Action.new()
	action.kind = kind
	action.run = run
	action.generation = _generation
	_queue.append(action)
	if not _running:
		_process_queue()
	return action


func _process_queue() -> void:
	_running = true
	while not _queue.is_empty():
		var action: Action = _queue[0]
		var result: Dictionary = await action.run.call()
		if action.generation != _generation:
			_queue.erase(action)
			action.finished.emit({"ok": false, "error": "", "stale": true})
			continue
		if not result.ok and _should_retry(action, result):
			action.attempts += 1
			_set_offline(true)
			await get_tree().create_timer(_delay(action, result)).timeout
			continue
		_queue.erase(action)
		if result.ok or not Api.is_transient(result):
			_set_offline(false)
		if not result.ok and not result.get("stale", false):
			push_warning("[Partie] %s refusé : %s" % [action.kind, result.get("error", "")])
		action.finished.emit(result)
	_running = false


func _should_retry(action: Action, result: Dictionary) -> bool:
	if action.max_attempts >= 0 and action.attempts + 1 >= action.max_attempts:
		return false
	if Api.is_transient(result):
		return true
	return result.get("status", 0) >= 500 and action.attempts < SERVER_ERROR_ATTEMPTS


func _delay(action: Action, result: Dictionary) -> float:
	if result.has("retry_after"):
		return float(result.retry_after)
	return BACKOFF[mini(action.attempts - 1, BACKOFF.size() - 1)]


func _set_offline(offline: bool) -> void:
	if offline == _offline:
		return
	_offline = offline
	notice.emit("Connexion au serveur perdue : nouvel essai en cours…" if offline else "Connexion au serveur rétablie.")


# --- Requêtes ---------------------------------------------------------------------------------------------

func _no_game() -> Dictionary:
	return {"ok": false, "status": 0, "kind": "nogame", "error": "Cette partie n'est pas enregistrée sur le serveur."}


func _game_path(suffix := "") -> String:
	return "/game-sessions/%d%s" % [game_id, suffix]


func _run_create() -> Dictionary:
	var result := await Api.post_json("/game-sessions", _player_state())
	if result.ok:
		_adopt(result.data)
		return result
	if result.status == 409:
		# Une partie est déjà en cours : création répétée après une réponse perdue, ou autre appareil.
		var active := await _fetch_active()
		if active.ok and active.data is Dictionary:
			_adopt(active.data)
			return {"ok": true}
	return result


func _run_start(zone: StringName) -> Dictionary:
	if game_id == 0:
		return _no_game()
	var puzzles := await _ensure_puzzles()
	if not puzzles.ok:
		return puzzles
	var result := await Api.post_json(_game_path("/puzzle-progress"), {"id_puzzles": puzzle_ids.get(zone, 0)})
	if result.ok:
		progress_ids[zone] = int(result.data.id_puzzle_progress)
	elif result.status == 409:
		await _run_refresh()
	return result


func _run_solve(zone: StringName) -> Dictionary:
	if not progress_ids.has(zone):
		var started := await _run_start(zone)
		if not started.ok:
			return started
	var result := await Api.request(HTTPClient.METHOD_PATCH, _game_path("/puzzle-progress/%d" % progress_ids[zone]), {"solved": true})
	if result.ok or not (result.status == 409 or result.status == 404):
		return result
	return await _settle(result, func(state: Dictionary) -> bool: return _puzzle_state(state, zone).get("is_solved", false))


func _run_place(zone: StringName) -> Dictionary:
	if not progress_ids.has(zone):
		var started := await _run_start(zone)
		if not started.ok:
			return started
	var result := await Api.post_json(_game_path("/puzzle-progress/%d/placements" % progress_ids[zone]))
	if result.ok or not (result.status == 409 or result.status == 404):
		return result
	return await _settle(result, func(state: Dictionary) -> bool: return _puzzle_state(state, zone).get("is_placed", false))


func _run_fragment(index: int) -> Dictionary:
	if game_id == 0:
		return _no_game()
	var result := await Api.post_json(_game_path("/paper-fragments"), {"fragment_index": index})
	if result.ok or result.status != 409:
		return result
	return await _settle(result, func(state: Dictionary) -> bool:
		return state.get("collected_fragments", []).any(func(collected: Variant) -> bool: return int(collected) == index))


## Après un conflit : l'état du serveur dit si l'action est en fait déjà faite (succès) ou refusée.
func _settle(conflict: Dictionary, done: Callable) -> Dictionary:
	var state := await _progress()
	if not state.ok:
		return state if Api.is_transient(state) else conflict
	_apply_game(state.data)
	if done.call(state.data):
		return {"ok": true, "status": 200, "data": state.data}
	return conflict


func _run_simple(action: String) -> Dictionary:
	if game_id == 0:
		return _no_game()
	var result := await Api.post_json(_game_path("/" + action))
	if result.ok:
		_apply_game(result.data)
	elif result.status == 409:
		await _run_refresh()
	return result


func _run_save() -> Dictionary:
	if game_id == 0:
		return _no_game()
	var result := await Api.request(HTTPClient.METHOD_PATCH, _game_path(), _player_state())
	if result.ok:
		_apply_game(result.data)
	elif result.status == 409:
		await _run_refresh()
	return result


func _run_refresh() -> Dictionary:
	if game_id == 0:
		return _no_game()
	var result := await Api.get_json(_game_path())
	if result.ok:
		_apply_game(result.data)
	return result


func _run_complete() -> Dictionary:
	if game_id == 0:
		return _no_game()
	var result := await Api.post_json(_game_path("/completions"))
	if result.ok:
		_apply_game(result.data)
	elif result.status == 409:
		await _run_refresh()
	return result


func _run_abandon() -> Dictionary:
	var active := await _fetch_active()
	if not active.ok:
		return active
	if not active.data is Dictionary:
		return {"ok": true}
	game_id = int(active.data.id_game_sessions)
	var result := await Api.post_json(_game_path("/abandonments"))
	# Déjà terminée entre-temps (temps écoulé) : il n'y a plus rien à abandonner.
	return {"ok": true} if result.status == 409 else result


func _run_sync() -> Dictionary:
	var puzzles := await _ensure_puzzles()
	if not puzzles.ok:
		return puzzles
	var active := await _fetch_active()
	if not active.ok:
		return active
	if active.data is Dictionary:
		_adopt(active.data)
		var state := await _progress()
		if not state.ok:
			return state
		GameState.apply_server_state(active.data, state.data, _zones_by_id())
		return {"ok": true}
	# Aucune partie en cours sur le serveur : la sauvegarde locale de ce compte n'est gardée que pour une
	# partie gagnée (exploration après la victoire).
	if GameState.server_game_id != 0:
		var previous := await Api.get_json("/game-sessions/%d" % GameState.server_game_id)
		if previous.ok and previous.data.status == "completed":
			game_id = GameState.server_game_id
			status = "completed"
			return {"ok": true}
		if not previous.ok and Api.is_transient(previous):
			return previous
		GameState.reset(false)
	elif GameState.can_continue():
		# Partie commencée alors que le serveur était injoignable : il ne l'a jamais vue. Elle est importée
		# (temps et progression conservés), et ne comptera donc pas pour le classement.
		return await _run_import(GameState.read_save(GameState.save_path()))
	return {"ok": true}


func _run_import(save: Dictionary) -> Dictionary:
	var puzzles := await _ensure_puzzles()
	if not puzzles.ok:
		return puzzles
	var result := await Api.post_json("/game-sessions/imports", _import_payload(save))
	if not result.ok:
		return result
	_adopt(result.data)
	var state := await _progress()
	if state.ok:
		GameState.apply_server_state(result.data, state.data, _zones_by_id())
	return {"ok": true}


## Aucune requête de partie en cours ni en attente.
func is_idle() -> bool:
	return _queue.is_empty() and not _running


## Identifiants des énigmes (classements par énigme) : `puzzle_ids` est rempli en cas de succès.
func load_puzzles() -> Dictionary:
	return await _ensure_puzzles()


func _fetch_active() -> Dictionary:
	var result := await Api.get_json("/game-sessions?status=in_progress&limit=1")
	if not result.ok:
		return result
	var items: Array = result.data.get("items", [])
	return {"ok": true, "data": items[0] if not items.is_empty() else null}


func _progress() -> Dictionary:
	if game_id == 0:
		return _no_game()
	return await Api.get_json(_game_path("/progress"))


func _ensure_puzzles() -> Dictionary:
	if puzzle_ids.size() == GameState.ZONE_ORDER.size():
		return {"ok": true}
	var result := await Api.get_json("/puzzles", false)
	if not result.ok:
		return result
	puzzle_ids.clear()
	for puzzle: Dictionary in result.data:
		var index := int(puzzle.order_index) - 1
		if index >= 0 and index < GameState.ZONE_ORDER.size():
			puzzle_ids[GameState.ZONE_ORDER[index]] = int(puzzle.id_puzzles)
	if puzzle_ids.size() != GameState.ZONE_ORDER.size():
		return {"ok": false, "status": 0, "kind": "config", "error": "Les énigmes ne sont pas configurées sur le serveur."}
	return {"ok": true}


# --- Application des réponses -----------------------------------------------------------------------------

func _adopt(game: Dictionary) -> void:
	game_id = int(game.id_game_sessions)
	GameState.server_game_id = game_id
	_pause_requested = bool(game.get("is_paused", false))
	_apply_game(game)
	GameState.save_game()


## Réponse décrivant la partie (GameSessionRead ou GameProgressRead) : état et temps officiel.
func _apply_game(game: Dictionary) -> void:
	if int(game.get("id_game_sessions", game_id)) != game_id:
		return
	status = str(game.get("status", status))
	server_paused = bool(game.get("is_paused", server_paused))
	if status == "in_progress" and game.has("remaining_seconds"):
		_official_remaining = float(game.remaining_seconds)
		_official_at = Time.get_ticks_msec()
		GameState.set_server_time(_official_remaining)
	elif status == "game_over":
		GameState.erupt()


func _puzzle_state(progress: Dictionary, zone: StringName) -> Dictionary:
	for state: Dictionary in progress.get("puzzles", []):
		if int(state.get("id_puzzles", 0)) == int(puzzle_ids.get(zone, -1)):
			if state.get("id_puzzle_progress") != null:
				progress_ids[zone] = int(state.id_puzzle_progress)
			return state
	return {}


func _zones_by_id() -> Dictionary:
	var zones := {}
	for zone: StringName in puzzle_ids:
		zones[puzzle_ids[zone]] = zone
	return zones


func _zone_of(book: StringName) -> StringName:
	for zone: StringName in GameState.ZONE_BOOKS:
		if GameState.ZONE_BOOKS[zone] == book:
			return zone
	return &""


## Niveau et position, dans les bornes de l'API (niveaux connus, coordonnées de ±10 000).
func _player_state() -> Dictionary:
	var level := GameState.current_level if GameState.current_level in LEVELS else &"hub"
	var position := GameState.player_position.clamp(Vector3.ONE * -10000.0, Vector3.ONE * 10000.0)
	return {
		"current_level": String(level),
		"position_x": position.x,
		"position_y": position.y,
		"position_z": position.z,
		"rotation_y": clampf(GameState.player_rotation, -1000.0, 1000.0),
	}


## Sauvegarde invitée → corps de POST /game-sessions/imports. Seules les énigmes résolues dans l'ordre sont
## gardées (le serveur refuse les autres), et les fragments seulement si le Village est ouvert.
func _import_payload(save: Dictionary) -> Dictionary:
	var solved: Array = []
	for zone in GameState.ZONE_ORDER:
		var book: StringName = GameState.ZONE_BOOKS[zone]
		if not book in save.books:
			break
		solved.append({"id_puzzles": puzzle_ids[zone], "is_placed": book in save.placed_books})
	var completed: bool = solved.size() == GameState.BOOK_COUNT and solved.all(func(item: Dictionary) -> bool: return item.is_placed)
	var fragments: Array = save.fragments if solved.size() >= GameState.ZONE_ORDER.find(&"village") else []
	var level: StringName = save.current_level if save.current_level in LEVELS else &"hub"
	var position: Vector3 = save.player_position
	return {
		"status": "completed" if completed else "in_progress",
		"elapsed_seconds": clampf(GameState.TOTAL_TIME - float(save.time_left), 0.0, GameState.TOTAL_TIME - (0.0 if completed else 1.0)),
		"current_level": String(level),
		"position_x": clampf(position.x, -10000.0, 10000.0),
		"position_y": clampf(position.y, -10000.0, 10000.0),
		"position_z": clampf(position.z, -10000.0, 10000.0),
		"rotation_y": clampf(float(save.player_rotation), -1000.0, 1000.0),
		"solved_puzzles": solved,
		"collected_fragments": fragments,
	}


# --- Chronomètre et pause ---------------------------------------------------------------------------------

## Le chronomètre du serveur s'arrête dès l'arrivée dans un menu, ou quand le jeu reste figé dans un niveau plus
## de PAUSE_DELAY (pause, indices, transition), et repart dès que le joueur reprend la main. Le temps affiché
## suit le serveur (official_remaining) : il ne s'arrête qu'une fois la pause enregistrée.
func _process(delta: float) -> void:
	if not is_tracking() or game_id == 0 or status != "in_progress" or _logging_out:
		return
	var in_level := GameState.is_in_level()
	var frozen := get_tree().paused or not in_level
	if frozen != _frozen:
		_frozen = frozen
		_frozen_for = 0.0
	_frozen_for += delta
	if frozen != _pause_requested and (not frozen or not in_level or _frozen_for >= PAUSE_DELAY):
		_pause_requested = frozen
		_enqueue("pause", _run_simple.bind("pauses" if frozen else "resumptions"))
	if not frozen:
		_since_save += delta
		if _since_save >= SAVE_INTERVAL:
			save_position()


func _on_session_changed() -> void:
	if not is_active():
		forget_game()


## Jeton refusé en pleine partie : retour à l'écran de connexion.
func _on_session_expired() -> void:
	forget_game()
	MainMenu.pending_notice = "Votre session a expiré : reconnectez-vous."
	if get_tree().current_scene and not get_tree().current_scene is MainMenu:
		get_tree().paused = false
		Transition.change_scene(MainMenu.SCENE)
