extends Node
## Tests du jeu, lancés sans affichage depuis le dossier frontend :
##
##   godot --headless --path . res://tests/run_tests.tscn
##
## Les tests statiques (scripts, scènes, autoloads) et unitaires (sauvegarde, chronomètre, fragments, livres,
## import, messages) tournent toujours, sans réseau. Les tests fonctionnels ne tournent qu'avec une API de
## test et la boîte d'e-mails d'un faux serveur SMTP, où chaque destinataire a un fichier <adresse>.log qui
## reçoit un code par ligne :
##
##   godot --headless --path . res://tests/run_tests.tscn -- --api=http://localhost:8000/api/v1 --mail-dir=/tmp/mail
##
## Ils créent des comptes et des parties : jamais contre la production (refusé ci-dessous).
## Code de sortie : 0 si tout réussit, 1 sinon.

const PRODUCTION_HOST := "codequest.anthonyferron.com"
const PASSWORD := "Volcan2026"
## Énigmes résolues lentement pour la partie classée : au-delà du minimum de 30 s du serveur.
const RANKED_SPLIT := 31.0
const OLD_REFERENCES: Array[String] = ["/hints", "auth-challenges/verifications", "hints_count", "hints_used", "submit_run", "placed_puzzle_ids"]

var _passed := 0
var _failed := 0
var _mail_dir := ""
var _api_argument := ""
var _level: Node3D


func _ready() -> void:
	get_tree().paused = false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--mail-dir="):
			_mail_dir = argument.trim_prefix("--mail-dir=")
		elif argument.begins_with("--api="):
			_api_argument = argument.trim_prefix("--api=").trim_suffix("/")
	# Garde-fou : un test bloqué ne doit pas tourner indéfiniment.
	get_tree().create_timer(900.0, true).timeout.connect(func() -> void:
		printerr("Délai dépassé : tests interrompus.")
		get_tree().quit(2))
	_run.call_deferred()


func _run() -> void:
	_section("Statique : scripts, scènes, autoloads")
	_static_tests()
	_section("Unitaire : sauvegarde, chronomètre, fragments, livres, import, messages")
	await _unit_tests()
	if _api_argument.is_empty():
		print("\nTests fonctionnels ignorés : aucune API de test (--api=…).")
	elif PRODUCTION_HOST in _api_argument:
		_check(false, "refus de lancer les tests fonctionnels contre la production")
	elif _mail_dir.is_empty():
		_check(false, "--mail-dir est requis pour lire les codes de connexion")
	else:
		await _functional_tests()
	print("\nRÉSULTAT : %d réussi(s), %d échec(s)" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _section(title: String) -> void:
	print("\n== %s" % title)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  ok     %s" % label)
	else:
		_failed += 1
		print("  ÉCHEC  %s" % label)


# --- Statique ---------------------------------------------------------------------------------------------

func _static_tests() -> void:
	var scripts := _files("res://", ".gd")
	var broken: Array[String] = []
	for path in scripts:
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			broken.append(path)
	_check(broken.is_empty(), "%d scripts GDScript compilent %s" % [scripts.size(), broken])

	var scenes := _files("res://scenes", ".tscn")
	var unloadable: Array[String] = []
	for path in scenes:
		var packed := load(path) as PackedScene
		if packed == null or not packed.can_instantiate():
			unloadable.append(path)
	_check(unloadable.is_empty(), "%d scènes se chargent %s" % [scenes.size(), unloadable])

	var missing: Array[String] = []
	for name in ["Api", "GameState", "Display", "Account", "PauseMenu", "Hints", "Transition", "GameSync", "DebugMenu"]:
		if get_node_or_null("/root/" + name) == null:
			missing.append(name)
	_check(missing.is_empty(), "autoloads présents %s" % [missing])
	_check(get_node("/root/Api").get_index() < get_node("/root/Account").get_index()
		and get_node("/root/Account").get_index() < get_node("/root/GameSync").get_index(),
		"ordre des autoloads : Api, puis Account, puis GameSync")

	for signal_name in ["fragment_collected", "state_restored", "book_placed", "erupted"]:
		_check(GameState.has_signal(signal_name), "signal GameState.%s" % signal_name)
	_check(GameSync.has_signal("notice") and GameSync.has_signal("synced"), "signaux GameSync.notice et synced")
	_check(Account.has_signal("session_expired") and Api.has_signal("unauthorized"), "signaux Account.session_expired et Api.unauthorized")

	var stale: Array[String] = []
	for path in scripts:
		if path.begins_with("res://tests/"):
			continue
		var text := FileAccess.get_file_as_string(path)
		for reference in OLD_REFERENCES:
			if reference in text:
				stale.append("%s (%s)" % [path, reference])
	_check(stale.is_empty(), "aucune route ni champ abandonné (indices, vérification séparée, temps envoyé par le client) %s" % [stale])


func _files(directory: String, extension: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return found
	for name in dir.get_directories():
		if not name.begins_with("."):
			found.append_array(_files(directory.path_join(name), extension))
	for name in dir.get_files():
		if name.ends_with(extension):
			found.append(directory.path_join(name))
	return found


# --- Unitaire ---------------------------------------------------------------------------------------------

func _unit_tests() -> void:
	_check(not Account.is_logged_in(), "démarrage en invité")
	_check(Api.base_url == (_api_argument if not _api_argument.is_empty() else Api.DEFAULT_BASE_URL),
		"adresse de l'API : argument --api, sinon production (%s)" % Api.base_url)

	# Sauvegarde : nouveaux champs conservés d'une session à l'autre.
	GameState.use_profile("test_unitaire")
	GameState.reset(false)
	GameState.intro_done = true
	GameState.books.assign([&"projenomicon", &"algonicon"])
	GameState.placed_books.assign([&"projenomicon"])
	GameState.fragments.assign([2, 5])
	GameState.current_level = &"desert"
	GameState.player_position = Vector3(1.5, 2.0, -3.25)
	GameState.player_rotation = 1.25
	GameState.server_game_id = 42
	GameState.time_left = 1234.5
	GameState.save_game()
	GameState.books.clear()
	GameState.fragments.clear()
	GameState.load_game()
	_check(_same(GameState.books, [&"projenomicon", &"algonicon"]) and _same(GameState.placed_books, [&"projenomicon"]),
		"sauvegarde : livres trouvés et posés")
	_check(_same(GameState.fragments, [2, 5]), "sauvegarde : fragments de papier")
	_check(GameState.current_level == &"desert" and GameState.player_position.is_equal_approx(Vector3(1.5, 2.0, -3.25))
		and is_equal_approx(GameState.player_rotation, 1.25), "sauvegarde : niveau, position et orientation")
	_check(GameState.server_game_id == 42 and is_equal_approx(GameState.time_left, 1234.5), "sauvegarde : partie du serveur et temps")

	# Sauvegarde écrite avant ces champs : lue avec des valeurs par défaut.
	var old := ConfigFile.new()
	old.set_value("partie", "livres", ["projenomicon"])
	old.set_value("partie", "livres_poses", [])
	old.set_value("partie", "derniere_zone", "plaine")
	old.set_value("partie", "temps_restant", 3000.0)
	old.set_value("partie", "eruption", false)
	old.set_value("partie", "introduction", true)
	old.save("user://sauvegarde_ancienne.cfg")
	var read := GameState.read_save("user://sauvegarde_ancienne.cfg")
	_check(_same(read.books, [&"projenomicon"]) and read.fragments.is_empty() and read.current_level == &"hub"
		and read.player_position == Vector3.ZERO and read.server_game_id == 0 and read.intro_done,
		"ancienne sauvegarde lisible, nouveaux champs par défaut")
	_check(GameState.read_save("user://absente.cfg").is_empty(), "sauvegarde absente : vide")

	# Fragments : bornes et doublons.
	GameState.reset(false)
	var emitted := [0]
	var count_fragment := func(_index: int) -> void: emitted[0] += 1
	GameState.fragment_collected.connect(count_fragment)
	for index in [3, 3, -1, 10, 9]:
		GameState.collect_fragment(index)
	GameState.fragment_collected.disconnect(count_fragment)
	_check(_same(GameState.fragments, [3, 9]) and emitted[0] == 2, "fragments : numéros 0 à 9, une seule fois chacun")

	# Chronomètre : il ne tourne que dans un niveau, hors pause.
	GameState.reset(false)
	GameState.intro_done = true
	_check(not GameState.is_timer_running(), "chronomètre arrêté hors d'un niveau (menus)")
	_enter_level()
	_check(GameState.is_timer_running(), "chronomètre en marche dans un niveau")
	var before := GameState.time_left
	await get_tree().create_timer(0.4).timeout
	_check(GameState.time_left < before, "le temps s'écoule dans un niveau")
	get_tree().paused = true
	_check(not GameState.is_timer_running(), "chronomètre arrêté en pause")
	get_tree().paused = false
	_enter_menu()
	before = GameState.time_left
	await get_tree().create_timer(0.3).timeout
	_check(is_equal_approx(GameState.time_left, before), "le temps ne s'écoule pas dans un menu")

	# Invité : dépôt et victoire locaux, sans serveur.
	GameState.reset(false)
	GameState.intro_done = true
	GameState.books.assign([&"projenomicon"])
	var placed: Dictionary = await GameState.request_place_book(&"projenomicon")
	_check(placed.ok and GameState.has_placed(&"projenomicon"), "invité : livre posé localement")
	var twice: Dictionary = await GameState.request_place_book(&"projenomicon")
	_check(not twice.ok and GameState.placed_books.size() == 1, "un livre ne se pose qu'une fois")
	var missing_book: Dictionary = await GameState.request_place_book(&"algonicon")
	_check(not missing_book.ok and not GameState.has_placed(&"algonicon"), "un livre non trouvé ne se pose pas")
	var early: Dictionary = await GameState.request_victory()
	_check(not early.ok, "pas de victoire avant les quatre livres posés")
	for book: StringName in GameState.BOOK_NAMES:
		if not GameState.has_book(book):
			GameState.books.append(book)
		GameState.place_book(book)
	var won: Dictionary = await GameState.request_victory()
	_check(won.ok and not GameState.is_victory_pending(), "invité : victoire locale avec les quatre livres posés")

	# Pénalité : cinq minutes, éruption à zéro.
	GameState.reset(false)
	GameState.intro_done = true
	GameState.time_left = 400.0
	var erupted := [false]
	var on_erupt := func() -> void: erupted[0] = true
	GameState.erupted.connect(on_erupt)
	GameState.penalize()
	_check(is_equal_approx(GameState.time_left, 100.0) and not erupted[0], "pénalité de 5 minutes")
	GameState.penalize()
	_check(GameState.time_left == 0.0 and erupted[0] and GameState.has_erupted, "éruption quand une pénalité épuise le temps (invité)")
	GameState.erupted.disconnect(on_erupt)

	# Validation locale des formulaires, avant toute requête.
	for case in [["ab", "joueur@example.com", PASSWORD, "pseudo"], ["<script>", "joueur@example.com", PASSWORD, "lettres"],
			["Joueur", "pas-une-adresse", PASSWORD, "adresse"], ["Joueur", "joueur@example.com", "motdepasse", "chiffre"],
			["Joueur", "joueur@example.com", "court1", "caractères"]]:
		var result: Dictionary = await Account.register(case[0], case[1], case[2])
		_check(not result.ok and case[3] in result.error, "inscription refusée avant envoi : %s" % result.error)
	var reset_request: Dictionary = await Account.request_password_reset("joueur@example.com")
	_check(not reset_request.ok and "pas encore disponible" in reset_request.error, "mot de passe oublié : signalé comme indisponible, sans route inventée")

	# Messages d'erreur de l'API.
	_check(Api._message(409, "La partie est en pause.") == "La partie est en pause.", "message du serveur repris tel quel")
	_check("l'adresse e-mail" in Api._message(422, [{"loc": ["body", "email"], "msg": "value is not a valid email"}]), "erreur de validation traduite")
	_check("Erreur du serveur" in Api._message(500, null) and "indisponible" in Api._message(503, null), "erreurs 500 et 503")
	_check("Accès refusé" in Api._message(403, null) and "session" in Api._message(401, null), "erreurs 401 et 403")
	_check(Api.is_transient({"status": 0}) and Api.is_transient({"status": 429}) and not Api.is_transient({"status": 409}),
		"coupure et 429 retentées, conflit non")

	# Import d'une partie invitée : seules les énigmes résolues dans l'ordre partent, fragments si le Village est ouvert.
	var saved_ids := GameSync.puzzle_ids.duplicate()
	GameSync.puzzle_ids = {&"plaine": 11, &"desert": 12, &"marais": 13, &"village": 14}
	var partial := GameSync._import_payload({"books": [&"projenomicon", &"logiconomicon"], "placed_books": [&"projenomicon"],
		"fragments": [1, 2], "time_left": 3000.0, "current_level": &"lune", "player_position": Vector3(1, 2, 3), "player_rotation": 0.5})
	_check(_same(partial.solved_puzzles, [{"id_puzzles": 11, "is_placed": true}]) and partial.status == "in_progress"
		and is_equal_approx(partial.elapsed_seconds, 600.0) and partial.current_level == "hub" and partial.collected_fragments.is_empty(),
		"import : énigmes dans l'ordre, niveau inconnu remplacé par le hub, fragments du Village fermé écartés")
	var books: Array = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]
	var full := GameSync._import_payload({"books": books, "placed_books": books, "fragments": [0, 9], "time_left": 0.0,
		"current_level": &"village", "player_position": Vector3.ZERO, "player_rotation": 0.0})
	_check(full.status == "completed" and full.solved_puzzles.size() == 4 and _same(full.collected_fragments, [0, 9])
		and is_equal_approx(full.elapsed_seconds, GameState.TOTAL_TIME), "import : partie gagnée, fragments gardés")
	GameSync.puzzle_ids = saved_ids

	# Village : les fragments déjà ramassés sont restaurés, et ne réapparaissent pas.
	GameState.reset(false)
	GameState.intro_done = true
	GameState.fragments.assign([1, 4])
	var village: Node = load(GameState.ZONE_SCENES[&"village"]).instantiate()
	get_tree().root.add_child(village)
	await get_tree().process_frame
	var collected: Array[int] = []
	var paper_four: PaperFragment
	for paper: PaperFragment in village.get_node("Interior/Fragments").get_children():
		if paper.collected:
			collected.append(paper.fragment)
		if paper.fragment == 4:
			paper_four = paper
	collected.sort()
	_check(_same(collected, [1, 4]) and village._found.size() == 2, "Village : fragments 1 et 4 restaurés dans le carnet")
	paper_four.reveal()
	_check(not paper_four.visible and not paper_four.enabled, "un fragment restauré ne réapparaît pas à l'ouverture de son meuble")
	village.queue_free()
	await get_tree().process_frame

	# Hub : les livres posés sont sur leur piédestal, les portails suivent les dépôts.
	GameState.reset(false)
	GameState.intro_done = true
	GameState.books.assign([&"projenomicon", &"algonicon", &"logiconomicon"])
	GameState.placed_books.assign([&"projenomicon", &"algonicon"])
	var hub: Node = load(GameState.HUB_SCENE).instantiate()
	get_tree().root.add_child(hub)
	await get_tree().process_frame
	_check(hub._pedestal_book(&"plaine").visible and hub._pedestal_book(&"desert").visible and not hub._pedestal_book(&"marais").visible,
		"hub : livres posés affichés sur leur piédestal")
	_check(hub._portal(&"marais").is_open and not hub._portal(&"village").is_open, "hub : portails ouverts selon les livres posés")
	hub.queue_free()
	await get_tree().process_frame
	GameState.reset(false)


func _enter_level() -> void:
	if _level == null:
		_level = Node3D.new()
		_level.name = "FauxNiveau"
		var player := Node3D.new()
		player.name = "Player"
		var pivot := Node3D.new()
		pivot.name = "CameraPivot"
		player.add_child(pivot)
		_level.add_child(player)
		get_tree().root.add_child(_level)
	get_tree().current_scene = _level


func _enter_menu() -> void:
	get_tree().current_scene = self


# --- Fonctionnel : contre une API de test -----------------------------------------------------------------

func _functional_tests() -> void:
	_section("Fonctionnel : API de test %s" % Api.base_url)
	var health: Dictionary = await Api.get_json("/health/database", false)
	_check(health.ok, "API de test joignable")
	if not health.ok:
		return
	var email := "godot-%d@example.com" % Time.get_unix_time_from_system()
	var pseudo := "Godot %d" % (int(Time.get_unix_time_from_system()) % 100000)

	# Inscription et double authentification.
	var registered: Dictionary = await Account.register(pseudo, email, PASSWORD)
	_check(registered.ok and registered.get("needs_code", false), "inscription : compte créé, code envoyé")
	_check("***" in Account.pending_address(), "adresse masquée affichée (%s)" % Account.pending_address())
	var code := await _read_code(email, 0)
	_check(code.length() == 6, "code reçu par e-mail (faux serveur SMTP)")
	var wrong := "000000" if code != "000000" else "111111"
	var refused: Dictionary = await Account.verify_code(wrong)
	_check(not refused.ok and "Essais restants" in refused.error, "code faux refusé : %s" % refused.error)
	var too_soon: Dictionary = await Account.resend_code()
	_check(not too_soon.ok and not too_soon.error.is_empty(), "renvoi immédiat refusé (60 s) : %s" % too_soon.error)
	var verified: Dictionary = await Account.verify_code(code)
	_check(verified.ok and Account.is_online() and Account.user_id > 0 and Account.pseudo == pseudo, "session ouverte")
	var session := FileAccess.get_file_as_string(Account.SESSION_PATH)
	_check(Account.token in session and not PASSWORD in session, "jeton gardé sur l'appareil, mot de passe jamais")
	var duplicate: Dictionary = await Account.register("Autre joueur", email, PASSWORD)
	_check(not duplicate.ok and "existe déjà" in duplicate.error, "adresse déjà utilisée : %s" % duplicate.error)

	# Connexion : mauvais mot de passe, puis bon.
	Account.logout()
	var bad: Dictionary = await Account.login(email, "Mauvais2026")
	_check(not bad.ok and bad.error == "E-mail ou mot de passe incorrect.", "mauvais mot de passe refusé")
	await _login(email)
	_check(Account.is_online(), "connexion avec code")

	# Partie connectée : création, énigmes, livres, fragments, pénalité, pause.
	GameState.use_profile(Account.profile_id())
	GameState.reset()
	_enter_level()
	GameState.begin_mission()
	await _idle()
	_check(GameSync.game_id > 0 and GameSync.status == "in_progress", "partie créée au début de la mission")
	_check(absf(GameState.time_left - GameState.TOTAL_TIME) < 5.0, "chronomètre recalé sur celui du serveur")
	for zone in [&"plaine", &"desert", &"marais"]:
		await _solve_and_place(zone)
	var state := await _server_progress()
	_check(state.get("books_obtained", 0) == 3 and state.get("books_placed", 0) == 3, "trois énigmes résolues et trois livres posés sur le serveur")
	var placed_again: Dictionary = await GameSync.place_book(&"projenomicon")
	_check(placed_again.ok, "dépôt répété : constaté comme déjà fait, sans erreur")

	for index in [0, 3, 3, 9, 1, 2, 4, 5, 6, 7, 8]:
		GameState.collect_fragment(index)
	GameSync.on_fragment_collected(3)
	await _idle()
	state = await _server_progress()
	_check(_same(state.get("collected_fragments", []), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]), "dix fragments enregistrés, chacun une fois")

	GameState.penalize()
	await _idle()
	var game := await _server_game()
	_check(float(game.get("elapsed_seconds", 0.0)) >= GameState.PENALTY, "pénalité de 5 minutes appliquée par le serveur")
	_check(absf(GameState.time_left - float(game.get("remaining_seconds", 0.0))) < 3.0, "temps affiché = temps du serveur")

	_enter_menu()
	await get_tree().create_timer(GameSync.PAUSE_DELAY + 0.6).timeout
	await _idle()
	game = await _server_game()
	_check(game.get("is_paused", false), "jeu figé plus d'une seconde : chronomètre du serveur en pause")
	_enter_level()
	await get_tree().process_frame
	await get_tree().process_frame
	await _idle()
	game = await _server_game()
	_check(not game.get("is_paused", true), "retour dans le niveau : chronomètre du serveur relancé")

	# Reprise sur un autre appareil : nouvelle session, sauvegarde locale vide, état relu sur le serveur.
	_enter_menu()
	Account.logout()
	GameState.use_profile("")
	await _login(email)
	GameState.use_profile(Account.profile_id())
	GameState.reset(false)
	var synced: Dictionary = await GameSync.sync_with_server()
	_check(synced.ok and GameState.can_continue() and GameState.server_game_id == GameSync.game_id, "partie en cours retrouvée sur le serveur")
	_check(GameState.books.size() == 3 and GameState.placed_books.size() == 3, "livres trouvés et posés restaurés")
	_check(GameState.fragments.size() == GameState.PAPER_FRAGMENT_COUNT, "fragments restaurés")

	# Victoire validée par le serveur.
	_enter_level()
	await get_tree().process_frame
	await _idle()
	await _solve_and_place(&"village")
	var victory: Dictionary = await GameState.request_victory()
	_check(victory.ok and GameSync.status == "completed" and not GameSync.is_tracking(), "victoire validée par le serveur")
	game = await _server_game()
	_check(game.get("status", "") == "completed" and not game.get("is_rankable", true), "résolutions en moins de 30 s : partie gagnée mais non classée")

	# Défaite : le serveur déclare l'éruption, le jeu la montre.
	GameState.reset()
	GameState.begin_mission()
	await _idle()
	var lost := [false]
	var on_erupt := func() -> void: lost[0] = true
	GameState.erupted.connect(on_erupt)
	for _penalty in 12:
		GameState.penalize()
	await _idle()
	await _until(func() -> bool: return lost[0], 10.0)
	GameState.erupted.disconnect(on_erupt)
	game = await _server_game()
	_check(lost[0] and GameState.has_erupted and game.get("status", "") == "game_over", "défaite déclarée par le serveur après 60 minutes de pénalités")

	# Nouvelle partie : l'ancienne, en cours, est abandonnée.
	GameState.reset()
	GameState.begin_mission()
	await _idle()
	var previous := GameSync.game_id
	var abandoned: Dictionary = await GameSync.abandon_current()
	var active: Dictionary = await Api.get_json("/game-sessions?status=in_progress")
	_check(abandoned.ok and previous > 0 and active.ok and active.data.total == 0, "nouvelle partie : l'ancienne est abandonnée sur le serveur")

	# Partie classée : énigmes de plus de 30 s, puis classements.
	GameState.reset()
	GameState.begin_mission()
	await _idle()
	for zone in GameState.ZONE_ORDER:
		GameState.current_level = zone
		GameSync.on_level_changed(zone)
		await _idle()
		await get_tree().create_timer(RANKED_SPLIT).timeout
		await _solve_and_place(zone, false)
	victory = await GameState.request_victory()
	game = await _server_game()
	_check(victory.ok and game.get("is_rankable", false), "partie classée gagnée")
	var board: Dictionary = await Account.fetch_leaderboard()
	var mine: Array = board.get("entries", []).filter(func(entry: Dictionary) -> bool: return entry.pseudo == pseudo)
	_check(board.ok and mine.size() == 1 and mine[0].rank >= 1 and mine[0].time.contains(":"), "classement général : rang, pseudo et temps")
	await GameSync.load_puzzles()
	var puzzle_board: Dictionary = await Account.fetch_leaderboard(GameSync.puzzle_ids[&"plaine"])
	var puzzle_mine: Array = puzzle_board.get("entries", []).filter(func(entry: Dictionary) -> bool: return entry.pseudo == pseudo)
	_check(puzzle_board.ok and puzzle_mine.size() == 1 and puzzle_mine[0].seconds >= RANKED_SPLIT, "classement de l'énigme de la Plaine")
	var raw: Dictionary = await Api.get_json("/leaderboards", false)
	var text := JSON.stringify(raw.get("data", {}))
	_check(raw.ok and not "email" in text and not email in text and not "id_users" in text, "classement de l'API sans données personnelles")

	# Écran du classement du menu principal.
	var menu: MainMenu = load(MainMenu.SCENE).instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	menu.show_screen(&"leaderboard")
	var list: Node = menu.find_child("List", true, false)
	await _until(func() -> bool: return list.get_child_count() > 0, 10.0)
	var first: MainMenu.LeaderboardRow = list.get_child(0) if list.get_child_count() > 0 else null
	_check(first != null and first.rank == 1 and not first.time_text.is_empty(), "écran du classement rempli par l'API")
	menu.queue_free()
	await get_tree().process_frame

	# Import de la partie invitée de l'appareil, depuis le menu (comme après la vérification du code).
	_enter_menu()
	Account.logout()
	GameState.use_profile("")
	GameState.reset()
	GameState.intro_done = true
	GameState.books.assign([&"projenomicon"])
	GameState.placed_books.assign([&"projenomicon"])
	GameState.fragments.assign([5])
	GameState.time_left = 3000.0
	GameState.save_game()
	await _login(email)
	GameState.use_profile(Account.profile_id())
	_check(not GameSync.guest_import_candidate().is_empty(), "partie invitée à rattacher détectée")
	var imported: Dictionary = await GameSync.import_guest_game()
	game = await _server_game()
	_check(imported.ok and GameSync.status == "in_progress" and game.get("is_paused", false) and not game.get("is_rankable", true),
		"partie invitée rattachée : en pause, jamais classée")
	_check(GameState.has_placed(&"projenomicon") and GameState.read_save(GameState.SAVE_PATH).get("intro_done", false) == false,
		"progression importée dans le compte, sauvegarde invitée vidée")
	_enter_level()
	await get_tree().process_frame
	await get_tree().process_frame
	await _idle()
	game = await _server_game()
	_check(not game.get("is_paused", true), "partie importée relancée quand le joueur reprend la main")

	# Coupure réseau : l'action est retentée, le joueur prévenu, puis la connexion revient.
	var notices: Array[String] = []
	var on_notice := func(text: String) -> void: notices.append(text)
	GameSync.notice.connect(on_notice)
	var server := Api.base_url
	Api.base_url = "http://127.0.0.1:9/api/v1"
	var offline: Dictionary = await Api.get_json("/health", false)
	_check(not offline.ok and offline.status == 0 and offline.kind == "network" and "connexion" in offline.error, "serveur injoignable : message clair")
	_enter_level()
	GameSync.save_position()
	await _until(func() -> bool: return not notices.is_empty(), 10.0)
	Api.base_url = server
	await _idle(30.0)
	GameSync.notice.disconnect(on_notice)
	_check(notices.size() >= 2 and "perdue" in notices[0] and "rétablie" in notices[-1], "coupure : sauvegarde retentée, joueur prévenu puis rassuré")

	# Jeton refusé : retour à la connexion.
	_enter_level()
	Api.token = "jeton-revoque"
	await GameSync.sync_with_server()
	await _until(func() -> bool: return get_tree().current_scene is MainMenu, 10.0)
	_check(not Account.is_logged_in(), "jeton refusé : session fermée")
	var current := get_tree().current_scene
	_check(current is MainMenu and (current as MainMenu).current_screen() == &"login", "jeton refusé : écran de connexion")
	if current is MainMenu:
		current.queue_free()
	get_tree().current_scene = self

	# Jeton refusé pendant la lecture de la partie, depuis le menu : l'écran de connexion s'ouvre aussitôt.
	await _login(email)
	var home: MainMenu = load(MainMenu.SCENE).instantiate()
	get_tree().root.add_child(home)
	get_tree().current_scene = home
	Api.token = "jeton-revoque"
	home.show_screen(&"home")
	await _until(func() -> bool: return home.current_screen() == &"login", 10.0)
	_check(not Account.is_logged_in() and home.current_screen() == &"login", "jeton refusé dans le menu : écran de connexion")
	home.queue_free()
	get_tree().current_scene = self
	GameState.use_profile("")


func _login(address: String) -> void:
	var before := _mail_count(address)
	var challenge: Dictionary = await Account.login(address, PASSWORD)
	if not challenge.ok:
		_check(false, "connexion : %s" % challenge.error)
		return
	var code := await _read_code(address, before)
	var opened: Dictionary = await Account.verify_code(code)
	if not opened.ok:
		_check(false, "code de connexion : %s" % opened.error)


## Entrée dans la zone (sans charger la scène), livre trouvé, puis livre posé avec confirmation du serveur.
func _solve_and_place(zone: StringName, enter := true) -> void:
	if enter:
		GameState.current_level = zone
		GameSync.on_level_changed(zone)
	var book: StringName = GameState.ZONE_BOOKS[zone]
	GameState.collect_book(book)
	var placed: Dictionary = await GameState.request_place_book(book)
	_check(placed.ok and GameState.has_placed(book), "%s : énigme résolue et livre posé" % zone)


## Égalité élément par élément : tableaux typés ou non, nombres entiers ou issus du JSON.
func _same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for index in a.size():
		if a[index] != b[index]:
			return false
	return true


func _server_game() -> Dictionary:
	var result: Dictionary = await Api.get_json("/game-sessions/%d" % GameSync.game_id)
	return result.data if result.ok else {}


func _server_progress() -> Dictionary:
	var result: Dictionary = await Api.get_json("/game-sessions/%d/progress" % GameSync.game_id)
	return result.data if result.ok else {}


func _idle(timeout := 20.0) -> void:
	await _until(GameSync.is_idle, timeout)


func _until(condition: Callable, timeout: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await get_tree().process_frame
	return true


func _mail_count(address: String) -> int:
	var path := _mail_dir.path_join(address + ".log")
	return FileAccess.get_file_as_string(path).split("\n", false).size() if FileAccess.file_exists(path) else 0


## Attend un nouveau code dans la boîte du faux serveur SMTP.
func _read_code(address: String, previous: int) -> String:
	await _until(func() -> bool: return _mail_count(address) > previous, 20.0)
	var lines := FileAccess.get_file_as_string(_mail_dir.path_join(address + ".log")).split("\n", false)
	return lines[-1].strip_edges() if lines.size() > previous else ""
