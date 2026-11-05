extends "res://tests/scenes/common_test.gd"
## Musique : pour chaque scène, la bonne piste joue sur le bus « Music », en fondu enchaîné, sans relancer une piste
## déjà en cours. Menu, bunker (introduction) puis hub dehors, les quatre lieux, la bonne fin et l'épilogue au hub
## (victoire, qui continue), l'éruption (défaite, une seule fois, puis plus rien jusqu'au menu principal).

var music: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	music = root.get_node("Music")
	state = root.get_node("GameState")
	var bus := AudioServer.get_bus_index(&"Music")
	check("bus Music cree, sous le Master", bus > 0 and AudioServer.get_bus_send(bus) == &"Master" and AudioServer.get_bus_volume_db(bus) < -3.0)

	change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
	await wait(10)
	_check_track("menu principal", &"menu")
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
	finish()


func _check_track(where: String, track: StringName) -> void:
	var player: AudioStreamPlayer = music.active_player()
	var path := player.stream.resource_path if player.stream else ""
	check("%s : piste %s sur le bus Music (%s, %s)" % [where, track, music.current_track(), path.get_file()],
		music.current_track() == track and path == "res://assets/audio/music/%s.ogg" % track and player.bus == &"Music"
		and player.playing)
