extends "res://tests/scenes/common_test.gd"
## Musique : pour chaque scène, la bonne piste joue sur le bus « Music », en fondu enchaîné, sans relancer une piste
## déjà en cours. Menu, bunker (introduction) puis hub dehors, les quatre lieux, la bonne fin et l'épilogue au hub
## (victoire, qui continue), l'éruption (défaite, une seule fois, puis plus rien jusqu'au menu principal).
## Musique différée du web : une piste absente du paquet du jeu attend en silence, sans erreur, et part dès que le
## second paquet est monté ; un téléchargement raté est retenté plus tard.

## Pistes du faux second paquet : un dossier qui n'existe pas dans le projet (tests/ n'est jamais exporté).
const DEFERRED_DIR := "res://tests/musique_differee/"
const DEFERRED := [&"plaine", &"desert"]

var music: Node
var errors := ErrorCounter.new()


## Compte les erreurs et, à part, les avertissements écrits dans le journal du moteur.
class ErrorCounter extends Logger:
	var count := 0
	var warnings := 0
	var last := ""

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			warnings += 1
		else:
			count += 1
			last = "%s (%s, %s:%d %s)" % [rationale, code, file.get_file(), line, function]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	music = root.get_node("Music")
	state = root.get_node("GameState")
	var bus := AudioServer.get_bus_index(&"Music")
	check("bus Music cree, sous le Master", bus > 0 and AudioServer.get_bus_send(bus) == &"Master" and AudioServer.get_bus_volume_db(bus) < -3.0)

	# Comme sur le web avant le premier geste du joueur : la piste du menu attend, puis part au premier clic.
	music.set("_unlocked", false)
	music.set_process_input(true)
	change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
	await wait(10)
	check("menu avant le premier geste : piste en attente, silencieuse", music.current_track() == &"menu" and not music.is_playing())
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(5, 0)
	Input.parse_input_event(motion)
	await wait(3)
	check("un mouvement de souris ne compte pas comme un geste", not music.is_playing())
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(4, 4)
	Input.parse_input_event(click)
	await wait(2)
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	await wait(8)
	_check_track("menu principal, apres le premier clic", &"menu")
	# Fondu d'entrée : le volume monte en 1,5 s jusqu'au gain de la piste.
	var player: AudioStreamPlayer = music.active_player()
	check("fondu d'entree en cours (%.2f)" % player.volume_linear, player.volume_linear > 0.0 and player.volume_linear < db_to_linear(music.TRACKS[&"menu"]))
	await wait(120)
	check("fondu d'entree fini (%.2f)" % player.volume_linear, is_equal_approx(player.volume_linear, db_to_linear(music.TRACKS[&"menu"])))

	# Partie neuve : l'introduction joue au bunker, jusqu'à la première sortie, même une fois la mission confiée.
	await start_level("res://scenes/levels/hub/hub.tscn")
	_check_track("bunker au debut de la partie", &"intro")
	var menu_player := player
	player = music.active_player()
	check("fondu enchaine : l'ancienne piste s'efface pendant que la nouvelle monte", menu_player != player and menu_player.playing and player.playing)
	await wait(120)
	check("ancienne piste arretee apres le fondu", not menu_player.playing)
	state.begin_mission()
	await wait(10)
	_check_track("bunker, mission confiee", &"intro")
	await level._on_bunker_exit()
	await wait(10)
	_check_track("hub dehors apres la sortie du bunker", &"hub")
	var hub_player: AudioStreamPlayer = music.active_player()
	var position := hub_player.get_playback_position()
	await level._travel(true)
	await level._travel(false)
	await wait(10)
	check("le thème du hub continue d'une porte du bunker a l'autre", music.active_player() == hub_player and hub_player.get_playback_position() > position)

	# Chaque lieu a sa piste ; revenir dans le même lieu ne la relance pas.
	for zone: StringName in state.ZONE_ORDER:
		change_scene_to_file(state.ZONE_SCENES[zone])
		await wait(30)
		_check_track(String(zone), zone)
	var village_player: AudioStreamPlayer = music.active_player()
	await wait(30)
	position = village_player.get_playback_position()
	change_scene_to_file(state.ZONE_SCENES[&"village"])
	await wait(30)
	check("le village rechargé ne relance pas sa piste", music.active_player() == village_player and village_player.get_playback_position() > position)

	# Bonne fin : la victoire joue pendant la cinématique, puis en boucle pendant l'épilogue au hub.
	for zone: StringName in state.ZONE_ORDER:
		state.books.append(state.ZONE_BOOKS[zone])
		state.placed_books.append(state.ZONE_BOOKS[zone])
	state.save_game()
	state.ending = &"victory"
	change_scene_to_file(state.HUB_SCENE)
	await wait(10)
	level = current_scene
	_check_track("bonne fin", &"victoire")
	check("la victoire boucle", music.active_player().stream.loop)
	var victory_player: AudioStreamPlayer = music.active_player()
	for i in 60:
		await create_timer(1.0).timeout
		if level.get_node("Player").process_mode != Node.PROCESS_MODE_DISABLED:
			break
	check("le joueur reprend la main apres la bonne fin", level.get_node("Player").process_mode != Node.PROCESS_MODE_DISABLED)
	_check_track("epilogue au hub", &"victoire")
	check("la victoire continue sans reprendre du debut", music.active_player() == victory_player and victory_player.playing)
	change_scene_to_file(state.ZONE_SCENES[&"plaine"])
	await wait(30)
	_check_track("un lieu apres la victoire", &"plaine")
	change_scene_to_file(state.HUB_SCENE)
	await wait(30)
	_check_track("retour au hub pendant l'epilogue", &"victoire")

	# Éruption : la musique en cours s'efface, la défaite joue une seule fois au hub, puis rien jusqu'au menu principal.
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	_check_track("plaine avant l'eruption", &"plaine")
	# Pistes entendues, dans l'ordre : « arret » quand rien ne joue. L'arrêt dure moins d'une image (sans affichage, le
	# changement de scène est immédiat) : il est relevé au moment même de l'éruption.
	var heard: Array[StringName] = [music.current_track()]
	var note := func() -> void:
		var track: StringName = music.current_track() if music.current_track() != &"" else &"arret"
		if heard[-1] != track:
			heard.append(track)
	state.erupted.connect(note, CONNECT_ONE_SHOT)
	state.time_left = 0.05
	var defeat_player: AudioStreamPlayer
	var deadline := Time.get_ticks_msec() + 45000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		note.call()
		var track: StringName = music.current_track()
		if track == &"defaite" and not defeat_player:
			defeat_player = music.active_player()
			check("defaite sur le bus Music, sans boucle", defeat_player.bus == &"Music" and not defeat_player.stream.loop and defeat_player.playing)
		if current_scene and current_scene.scene_file_path.ends_with("main_menu.tscn"):
			break
	await wait(10)
	check("eruption : arret, defaite, puis menu (%s)" % [heard], heard == [&"plaine", &"arret", &"defaite", &"menu"])
	_check_track("menu principal apres l'eruption", &"menu")
	await _check_deferred()
	finish()


## Comme sur le web avant la fin du téléchargement de musique.pck : les pistes des lieux manquent (autre dossier).
func _check_deferred() -> void:
	OS.add_logger(errors)
	music.dir = DEFERRED_DIR
	var menu_player: AudioStreamPlayer = music.active_player()
	music.prefetch(state.ZONE_SCENES[&"plaine"])
	music.play(&"plaine")
	var start := Time.get_ticks_msec()
	await wait(30)
	check("piste absente : pas de gel (30 images en %d ms)" % (Time.get_ticks_msec() - start), Time.get_ticks_msec() - start < 5000)
	check("piste absente : demandee, en attente du paquet, silencieuse", music.current_track() == &"plaine"
		and music.is_waiting_for_pack() and not music.is_playing() and not music.is_pack_loaded())
	check("piste absente : l'ancienne piste s'efface", menu_player.playing and menu_player.volume_linear < db_to_linear(music.TRACKS[&"menu"]))
	await wait(120)
	check("piste absente : l'ancienne piste arretee apres le fondu", not menu_player.playing)
	music.play(&"desert")
	await wait(10)
	check("une autre piste absente remplace la premiere, toujours en attente", music.current_track() == &"desert" and music.is_waiting_for_pack())
	check("aucune erreur tant que le paquet manque (%d : %s)" % [errors.count, errors.last], errors.count == 0)

	# Faux second paquet : les fichiers d'import des deux pistes, rangés dans le dossier simulé, renvoient aux pistes
	# importées du projet.
	var pack := "user://musique_test.pck"
	var packer := PCKPacker.new()
	var ok := packer.pck_start(pack) == OK
	for track: StringName in DEFERRED:
		var source := ProjectSettings.globalize_path("res://assets/audio/music/%s.ogg.import" % track)
		ok = ok and packer.add_file(DEFERRED_DIR + "%s.ogg.import" % track, source) == OK
	ok = ok and packer.flush() == OK
	check("faux paquet de musique ecrit", ok)
	var loaded := [false]
	music.pack_loaded.connect(func() -> void: loaded[0] = true, CONNECT_ONE_SHOT)
	var warnings := errors.warnings
	check("paquet monte", music.load_pack(ProjectSettings.globalize_path(pack)) and music.is_pack_loaded() and loaded[0])
	# Le faux paquet n'a que deux pistes : l'avertissement qui le signale prouve que le compteur suit bien le journal.
	check("le compteur du journal releve l'avertissement du paquet incomplet", errors.warnings == warnings + 1)
	await wait(10)
	var player: AudioStreamPlayer = music.active_player()
	var path := player.stream.resource_path if player.stream else ""
	check("la piste en attente part des que le paquet est monte (%s)" % path.get_file(), music.current_track() == &"desert"
		and path == DEFERRED_DIR + "desert.ogg" and player.playing and not music.is_waiting_for_pack())
	check("elle monte en fondu (%.2f)" % player.volume_linear, player.volume_linear > 0.0 and player.volume_linear < db_to_linear(music.TRACKS[&"desert"]))
	music.play(&"plaine")
	await wait(10)
	player = music.active_player()
	path = player.stream.resource_path if player.stream else ""
	check("puis les pistes du paquet s'enchainent (%s)" % path.get_file(), music.current_track() == &"plaine"
		and path == DEFERRED_DIR + "plaine.ogg" and player.playing)
	check("le paquet ne remplace aucun fichier du jeu", ResourceLoader.exists("res://assets/audio/music/plaine.ogg")
		and not ResourceLoader.exists(DEFERRED_DIR + "marais.ogg"))

	# Téléchargement raté (adresse morte) : nouvelle tentative quelques secondes plus tard, la musique continue.
	var failures_before: int = music.pack_failures()
	music.fetch_pack("http://127.0.0.1:9/musique.pck")
	start = Time.get_ticks_msec()
	while music.pack_failures() == failures_before and Time.get_ticks_msec() - start < 10000:
		await process_frame
	check("telechargement rate : echec releve", music.pack_failures() == failures_before + 1)
	var first := Time.get_ticks_msec()
	while music.pack_failures() == failures_before + 1 and Time.get_ticks_msec() - first < 20000:
		await process_frame
	var spacing := (Time.get_ticks_msec() - first) / 1000.0
	check("nouvelle tentative, espacee (%.1f s)" % spacing, music.pack_failures() == failures_before + 2
		and spacing >= music.PACK_RETRY[0] - 0.5)
	check("la musique continue malgre les echecs", music.current_track() == &"plaine" and music.is_playing())
	OS.remove_logger(errors)

	# Retour aux pistes du jeu : celle du faux paquet s'efface et s'arrête.
	music.dir = music.DIR
	var deferred_player: AudioStreamPlayer = music.active_player()
	music.play(&"menu")
	await wait(120)
	_check_track("retour aux pistes du jeu apres celles du paquet", &"menu")
	check("la piste du paquet arretee apres le fondu", not deferred_player.playing)


func _check_track(where: String, track: StringName) -> void:
	var player: AudioStreamPlayer = music.active_player()
	var path := player.stream.resource_path if player.stream else ""
	check("%s : piste %s sur le bus Music (%s, %s)" % [where, track, music.current_track(), path.get_file()],
		music.current_track() == track and path == "res://assets/audio/music/%s.ogg" % track and player.bus == &"Music"
		and player.playing)
