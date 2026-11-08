extends Node
## État de la partie, chargé au démarrage : livres retrouvés et posés au château, fragments de papier du
## Village, dernière zone visitée, position du joueur et chronomètre du volcan.
## Il est sauvegardé à chaque changement, ce qui fait une sauvegarde entre chaque énigme.
##
## Pour un joueur connecté, GameSync relaie chaque changement à l'API, et le serveur fait foi : le temps
## affiché est recalé sur le sien, un livre n'est posé et la victoire n'est acquise qu'après sa confirmation
## (request_place_book, request_victory), et l'éruption n'a lieu que lorsqu'il la déclare.

signal book_collected(book_id: StringName)
## Un livre vient d'être posé sur son piédestal, au château du hub.
signal book_placed(book_id: StringName)
## Une validation fausse vient de coûter du temps.
signal time_penalized(seconds: float)
## Le chronomètre est tombé à zéro : le volcan entre en éruption et la partie est perdue.
signal erupted
## Un fragment de papier de la mairie vient d'être ramassé.
signal fragment_collected(index: int)
## La partie vient d'être remplacée par celle du serveur (reprise, autre appareil, import).
signal state_restored

## Sauvegarde de l'invité ; un compte a la sienne, nommée d'après son profil (use_profile).
const SAVE_PATH := "user://sauvegarde.cfg"
## Sauvegardes et session d'un test (godot --script res://tests/…, ou une scène de res://tests/ comme run_tests.tscn) :
## un dossier par processus. Le dossier user:// est commun à toutes les copies du projet : sans cela, deux tests lancés
## en même temps sur la même machine (plusieurs agents) écrivaient la même sauvegarde ou la même session (Account),
## et l'un relisait celle de l'autre.
const TEST_SAVE_DIR := "user://tests/"
const HUB_SCENE := "res://scenes/levels/hub/hub.tscn"
## Scène de chaque zone ; une zone sans scène n'est pas encore construite.
const ZONE_SCENES := {
	&"plaine": "res://scenes/levels/plaine/plaine.tscn",
	&"desert": "res://scenes/levels/desert/desert.tscn",
	&"marais": "res://scenes/levels/marais/marais.tscn",
	&"village": "res://scenes/levels/village/village.tscn",
}
## Zones dans l'ordre du jeu : chacune s'ouvre une fois le livre de la précédente trouvé.
const ZONE_ORDER: Array[StringName] = [&"plaine", &"desert", &"marais", &"village"]
## Livre que garde chaque zone.
const ZONE_BOOKS := {
	&"plaine": &"projenomicon",
	&"desert": &"algonicon",
	&"marais": &"logiconomicon",
	&"village": &"codonomicon",
}
const BOOK_NAMES := {
	&"projenomicon": "le Projenomicon",
	&"algonicon": "l'Algonicon",
	&"logiconomicon": "le Logiconomicon",
	&"codonomicon": "le Codonomicon",
}
## Couleur de la couverture de chaque livre, sur les piédestaux et dans la main du joueur.
const BOOK_COLORS := {
	&"projenomicon": Color(0.5, 0.08, 0.05),
	&"algonicon": Color(0.55, 0.35, 0.08),
	&"logiconomicon": Color(0.1, 0.35, 0.25),
	&"codonomicon": Color(0.3, 0.15, 0.5),
}
const BOOK_COUNT := 4
## Fragments de papier cachés dans la mairie du Village, numérotés de 0 à 9 (PaperFragment.fragment).
const PAPER_FRAGMENT_COUNT := 10
## Lignes de la transition à l'entrée de chaque lieu, d'après le scénario : chapitre, nom du lieu, énigme.
## Les chapitres du jeu partent de I : le réveil du volcan, au bunker, ouvre la partie.
const ZONE_TITLES := {
	&"plaine": ["Chapitre II", "Les plaines d'Hexcole", "Énigme 1 — Les fragments du passé"],
	&"desert": ["Chapitre III", "Le désert de Pythania", "Énigme 2 — Les algorithmes oubliés"],
	&"marais": ["Chapitre IV", "Les marais de Kernel Swamp", "Énigme 3 — Le tombeau du chiffrement"],
	&"village": ["Chapitre V", "Le village détruit", "Énigme 4 — Les cinq langages oubliés"],
}
## Temps laissé au joueur avant l'éruption du Mont Sam Altan (une heure, choix de l'équipe : le scénario
## en annonce quarante), et coût d'une validation fausse, en secondes.
const TOTAL_TIME := 60.0 * 60.0
const PENALTY := 5.0 * 60.0
## Intervalle entre deux sauvegardes du chronomètre.
const SAVE_INTERVAL := 15.0

## Livres trouvés dans les zones, qu'ils soient encore portés ou déjà posés.
var books: Array[StringName] = []
## Livres posés sur leur piédestal, au château.
var placed_books: Array[StringName] = []
## Zone d'où revient le joueur, pour le faire réapparaître devant son portail dans le hub.
var last_zone: StringName = &""
var time_left := TOTAL_TIME
## Vrai une fois la mission reçue du roi et de Merlon, dans le bunker : le chronomètre part de là.
var intro_done := false
var has_erupted := false
## Fin à jouer au prochain chargement du hub : &"eruption", &"victory", ou rien. Elle n'est pas sauvegardée.
var ending: StringName = &""
## Fragments de papier ramassés dans la mairie, conservés d'une visite et d'une session à l'autre.
var fragments: Array[int] = []
## Niveau et position du joueur à la dernière sauvegarde, envoyés à l'API. La reprise d'une partie ramène
## toujours au hub, devant le portail de la dernière zone : les zones ne gardent pas l'état de leurs énigmes.
var current_level: StringName = &"hub"
var player_position := Vector3.ZERO
var player_rotation := 0.0
## Partie du serveur à laquelle correspond cette sauvegarde (compte connecté), 0 sinon.
var server_game_id := 0

var _since_save := 0.0
## Dossier des sauvegardes et de la session : user://, ou celui du processus pour un test (TEST_SAVE_DIR).
var _save_dir := "user://"
var _save_path := SAVE_PATH


func _ready() -> void:
	_isolate_test_saves()
	load_game()


func _exit_tree() -> void:
	if _save_dir != "user://":
		_remove_dir(_save_dir)


## Un test garde ses sauvegardes et sa session dans son propre dossier ; ceux d'anciens tests arrêtés en route sont
## effacés.
func _isolate_test_saves() -> void:
	if not _is_test_run():
		return
	for name in DirAccess.get_directories_at(TEST_SAVE_DIR):
		# Un dossier à notre numéro vient d'un ancien processus : il est effacé aussi.
		if name.is_valid_int() and (name.to_int() == OS.get_process_id() or not _process_exists(name.to_int())):
			_remove_dir(TEST_SAVE_DIR + name + "/")
	_save_dir = TEST_SAVE_DIR + "%d/" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(_save_dir)
	_save_path = profile_save_path("")


## Un test : un script lancé avec --script (la boucle principale est son SceneTree : tests/scenes, tools/), ou une
## scène de res://tests/ lancée directement (run_tests.tscn), dont la boucle n'a pas de script. Le dossier tests/
## n'est pas exporté : le jeu du joueur n'est jamais concerné.
func _is_test_run() -> bool:
	if get_tree().get_script() != null:
		return true
	for argument in OS.get_cmdline_args():
		if argument.trim_prefix("res://").begins_with("tests/"):
			return true
	return false


## Le processus existe-t-il encore ? Sous Linux, on regarde /proc : OS.is_process_running ne connaît que les
## processus fils, et affichait une erreur (_check_pid_is_running) pour chaque test lancé par un autre processus.
func _process_exists(pid: int) -> bool:
	if OS.get_name() == "Linux":
		return DirAccess.dir_exists_absolute("/proc/%d" % pid)
	return OS.is_process_running(pid)


func _remove_dir(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path + file)
	DirAccess.remove_absolute(path)


func _process(delta: float) -> void:
	var official := GameSync.official_remaining()
	if official >= 0.0:
		# Partie connectée : le temps affiché est celui du serveur, figé seulement quand sa pause est enregistrée.
		if intro_done and not has_erupted and placed_books.size() < BOOK_COUNT:
			time_left = official
			_since_save += delta
			if time_left <= 0.0:
				_on_time_out()
			elif _since_save >= SAVE_INTERVAL:
				save_game()
		return
	if not is_timer_running():
		return
	time_left = maxf(time_left - delta, 0.0)
	_since_save += delta
	if time_left <= 0.0:
		_on_time_out()
	elif _since_save >= SAVE_INTERVAL:
		save_game()


## Chronomètre local (invité, ou partie connectée avant la première réponse du serveur) : il tourne dans un
## niveau, sauf en pause, après l'éruption ou une fois les livres posés. Il est arrêté dans les menus.
func is_timer_running() -> bool:
	return intro_done and not has_erupted and not get_tree().paused and placed_books.size() < BOOK_COUNT \
		and is_in_level()


## Un niveau jouable (hub ou zone) est affiché.
func is_in_level() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.has_node("Player")


func penalize() -> void:
	if has_erupted:
		return
	time_left = maxf(time_left - PENALTY, 0.0)
	time_penalized.emit(PENALTY)
	GameSync.on_penalty()
	if time_left <= 0.0:
		_on_time_out()
	else:
		save_game()


## Temps écoulé : pour une partie connectée, c'est le serveur qui déclare l'éruption.
func _on_time_out() -> void:
	if GameSync.is_tracking():
		GameSync.confirm_time_up()
	else:
		_erupt()


## Éruption déclarée par le serveur (ou confirmée sans réponse de sa part). Une partie remise à zéro (mission pas
## commencée) ne peut plus être perdue : une réponse tardive ne la réécrit pas.
func erupt() -> void:
	if not has_erupted and intro_done:
		_erupt()


## Temps officiel du serveur, pour une partie connectée.
func set_server_time(remaining: float) -> void:
	if not has_erupted:
		time_left = clampf(remaining, 0.0, TOTAL_TIME)


func has_book(book_id: StringName) -> bool:
	return book_id in books


func collect_book(book_id: StringName) -> void:
	if has_book(book_id):
		return
	books.append(book_id)
	save_game()
	book_collected.emit(book_id)
	GameSync.on_book_collected(book_id)


## Livres trouvés que le joueur porte encore, en attendant de les poser au château.
func carried_books() -> Array[StringName]:
	return books.filter(func(book: StringName) -> bool: return not has_placed(book))


func has_placed(book_id: StringName) -> bool:
	return book_id in placed_books


## Pose le livre sans attendre le serveur, à qui le dépôt est tout de même envoyé (menu de debug).
func place_book(book_id: StringName) -> void:
	if not has_book(book_id) or has_placed(book_id):
		return
	_apply_place(book_id)
	GameSync.on_book_placed(book_id)


## Pose le livre au château. Pour une partie connectée, il n'est posé qu'une fois le dépôt accepté par le
## serveur : `{"ok": false, "error": …}` sinon, et rien ne change ici.
func request_place_book(book_id: StringName) -> Dictionary:
	if not has_book(book_id) or has_placed(book_id):
		return {"ok": false, "error": ""}
	if GameSync.is_tracking():
		var result: Dictionary = await GameSync.place_book(book_id)
		if not result.ok:
			return result
		if has_placed(book_id):
			return {"ok": true}
	_apply_place(book_id)
	return {"ok": true}


func _apply_place(book_id: StringName) -> void:
	placed_books.append(book_id)
	save_game()
	book_placed.emit(book_id)


## Les quatre livres sont posés : la victoire est validée par le serveur pour une partie connectée.
func request_victory() -> Dictionary:
	if placed_books.size() < BOOK_COUNT:
		return {"ok": false, "error": "Les quatre livres doivent être posés au château."}
	if not GameSync.is_tracking():
		return {"ok": true}
	return await GameSync.complete()


## Victoire en attente de validation : livres posés, mais le serveur n'a pas encore enregistré la victoire.
func is_victory_pending() -> bool:
	return placed_books.size() >= BOOK_COUNT and GameSync.is_tracking()


func has_fragment(index: int) -> bool:
	return index in fragments


func collect_fragment(index: int) -> void:
	if index < 0 or index >= PAPER_FRAGMENT_COUNT or has_fragment(index):
		return
	fragments.append(index)
	fragments.sort()
	save_game()
	fragment_collected.emit(index)
	GameSync.on_fragment_collected(index)


func is_zone_built(zone: StringName) -> bool:
	return not String(ZONE_SCENES.get(zone, "")).is_empty()


## Une zone s'ouvre quand elle est construite et que le livre de la zone précédente est posé au château.
func is_zone_unlocked(zone: StringName) -> bool:
	var index := ZONE_ORDER.find(zone)
	if not is_zone_built(zone) or index < 0:
		return false
	return index == 0 or has_placed(ZONE_BOOKS[ZONE_ORDER[index - 1]])


## La mission commence : le roi et Merlon l'ont confiée, le chronomètre du volcan se met en marche.
func begin_mission() -> void:
	if intro_done:
		return
	intro_done = true
	save_game()
	GameSync.on_mission_started()


## Zone à terminer avant celle-ci, ou rien pour la première.
func previous_zone(zone: StringName) -> StringName:
	var index := ZONE_ORDER.find(zone)
	return ZONE_ORDER[index - 1] if index > 0 else &""


func enter_zone(zone: StringName) -> void:
	if not is_zone_built(zone):
		return
	last_zone = zone
	current_level = zone
	save_game()
	GameSync.on_level_changed(zone)
	Transition.change_scene(ZONE_SCENES[zone], ZONE_TITLES[zone])


func return_to_hub(zone: StringName) -> void:
	last_zone = zone
	current_level = &"hub"
	save_game()
	GameSync.on_level_changed(&"hub")
	Transition.change_scene(HUB_SCENE, hub_title())


## Lignes de la transition vers le hub, selon l'avancée de la quête.
func hub_title() -> Array:
	if not intro_done:
		return ["Chapitre I", "Le réveil du Mont Sam Altan", "An 5814"]
	if placed_books.size() >= BOOK_COUNT:
		return ["Épilogue", "La renaissance d'un royaume", "Codia"]
	if books.size() >= BOOK_COUNT:
		return ["Chapitre VI", "Le dernier espoir de Codia", "Les ruines du château"]
	var count := books.size()
	return ["Codia", "Les ruines du château", "%d livre%s sur quatre" % [count, "s" if count > 1 else ""]]


## Repart d'une partie neuve : aucun livre, chronomètre plein. La partie suivie sur le serveur est oubliée.
func reset(forget_server_game := true) -> void:
	_clear()
	# La position du joueur dans la scène en cours (le hub, après l'éruption) n'est pas celle d'une partie neuve.
	_write_save()
	if forget_server_game:
		GameSync.forget_game()


func _clear() -> void:
	books.clear()
	placed_books.clear()
	fragments.clear()
	last_zone = &""
	current_level = &"hub"
	player_position = Vector3.ZERO
	player_rotation = 0.0
	server_game_id = 0
	intro_done = false
	time_left = TOTAL_TIME
	has_erupted = false


## Change de joueur : l'invité (profil vide) ou un compte. Sa sauvegarde est chargée, s'il en a une.
func use_profile(profile: String) -> void:
	var path := profile_save_path(profile)
	if path == _save_path:
		return
	_save_path = path
	GameSync.forget_game()
	load_game()


func save_path() -> String:
	return _save_path


## Dossier des fichiers du joueur sur cet appareil (sauvegardes, session du compte) : user:// dans le jeu, le dossier
## du processus pour un test. Il finit toujours par « / ».
func data_dir() -> String:
	return _save_dir


## Sauvegarde d'un profil : l'invité (profil vide) ou un compte.
func profile_save_path(profile: String) -> String:
	return _save_dir + ("sauvegarde.cfg" if profile.is_empty() else "sauvegarde_%s.cfg" % profile)


## Sauvegarde de l'invité sur cet appareil, rattachable à un compte.
func guest_save_path() -> String:
	return profile_save_path("")


## Remplace la partie par celle du serveur : `game` est une GameSessionRead, `progress` une GameProgressRead,
## `zones` associe chaque id_puzzles à sa zone. Les livres posés et les fragments sont restaurés, la reprise
## ramène au hub devant le portail de la dernière zone visitée.
func apply_server_state(game: Dictionary, progress: Dictionary, zones: Dictionary) -> void:
	books.clear()
	placed_books.clear()
	for state: Dictionary in progress.get("puzzles", []):
		var zone: StringName = zones.get(int(state.get("id_puzzles", 0)), &"")
		if zone == &"":
			continue
		if state.get("is_solved", false):
			books.append(ZONE_BOOKS[zone])
		if state.get("is_placed", false):
			placed_books.append(ZONE_BOOKS[zone])
	fragments.clear()
	for index in progress.get("collected_fragments", []):
		fragments.append(int(index))
	fragments.sort()
	intro_done = true
	has_erupted = str(game.get("status", "")) == "game_over"
	time_left = clampf(float(game.get("remaining_seconds", progress.get("remaining_seconds", TOTAL_TIME))), 0.0, TOTAL_TIME)
	current_level = StringName(str(game.get("current_level", "hub")))
	last_zone = current_level if current_level in ZONE_ORDER else last_zone
	player_position = Vector3(float(game.get("position_x", 0.0)), float(game.get("position_y", 0.0)), float(game.get("position_z", 0.0)))
	player_rotation = float(game.get("rotation_y", 0.0))
	server_game_id = int(game.get("id_game_sessions", 0))
	save_game()
	state_restored.emit()


## Une partie commencée, et pas encore perdue, peut être reprise depuis le menu.
func can_continue() -> bool:
	return intro_done and not has_erupted


## Temps mis depuis le début de la mission, en secondes, pénalités comprises.
func elapsed_time() -> float:
	return TOTAL_TIME - time_left


func save_game() -> void:
	_capture_player()
	_write_save()


func _write_save() -> void:
	_since_save = 0.0
	var file := ConfigFile.new()
	file.set_value("partie", "livres", books.map(func(book: StringName) -> String: return String(book)))
	file.set_value("partie", "livres_poses", placed_books.map(func(book: StringName) -> String: return String(book)))
	file.set_value("partie", "derniere_zone", String(last_zone))
	file.set_value("partie", "temps_restant", time_left)
	file.set_value("partie", "eruption", has_erupted)
	file.set_value("partie", "introduction", intro_done)
	file.set_value("partie", "fragments", fragments)
	file.set_value("partie", "niveau", String(current_level))
	file.set_value("partie", "position", player_position)
	file.set_value("partie", "orientation", player_rotation)
	file.set_value("partie", "partie_serveur", server_game_id)
	file.save(_save_path)


func load_game() -> void:
	_clear()
	var save := read_save(_save_path)
	if save.is_empty():
		return
	books.assign(save.books)
	placed_books.assign(save.placed_books)
	fragments.assign(save.fragments)
	last_zone = save.last_zone
	time_left = save.time_left
	has_erupted = save.has_erupted
	intro_done = save.intro_done
	current_level = save.current_level
	player_position = save.player_position
	player_rotation = save.player_rotation
	server_game_id = save.server_game_id


## Contenu d'une sauvegarde, sans la charger (import de la partie invitée) ; vide si elle n'existe pas.
## Les sauvegardes antérieures aux fragments et à la position se lisent avec des valeurs par défaut.
static func read_save(path: String) -> Dictionary:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return {}
	var save := {"books": [], "placed_books": [], "fragments": []}
	for book: String in file.get_value("partie", "livres", []):
		save.books.append(StringName(book))
	for book: String in file.get_value("partie", "livres_poses", []):
		save.placed_books.append(StringName(book))
	for index in file.get_value("partie", "fragments", []):
		if int(index) >= 0 and int(index) < PAPER_FRAGMENT_COUNT and not int(index) in save.fragments:
			save.fragments.append(int(index))
	save.last_zone = StringName(file.get_value("partie", "derniere_zone", ""))
	save.time_left = clampf(float(file.get_value("partie", "temps_restant", TOTAL_TIME)), 0.0, TOTAL_TIME)
	save.has_erupted = bool(file.get_value("partie", "eruption", false))
	save.intro_done = bool(file.get_value("partie", "introduction", false))
	save.current_level = StringName(file.get_value("partie", "niveau", "hub"))
	var position: Variant = file.get_value("partie", "position", Vector3.ZERO)
	save.player_position = position if position is Vector3 else Vector3.ZERO
	save.player_rotation = float(file.get_value("partie", "orientation", 0.0))
	save.server_game_id = int(file.get_value("partie", "partie_serveur", 0))
	return save


## Efface une sauvegarde (la partie invitée, une fois rattachée à un compte).
func clear_save(path: String) -> void:
	if path == _save_path:
		reset()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Position et orientation du joueur, s'il est dans un niveau.
func _capture_player() -> void:
	var scene := get_tree().current_scene if is_inside_tree() else null
	if not scene or not scene.has_node("Player"):
		return
	var player := scene.get_node("Player") as Node3D
	if not player:
		return
	player_position = player.global_position
	var pivot := player.get_node_or_null("CameraPivot") as Node3D
	player_rotation = pivot.rotation.y if pivot else player.rotation.y


func _erupt() -> void:
	has_erupted = true
	save_game()
	erupted.emit()
