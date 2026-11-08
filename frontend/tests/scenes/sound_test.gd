extends "res://tests/scenes/common_test.gd"
## Sons : bus « Interface », clic des boutons à la souris, ouverture et fermeture des panneaux (pause, indices, texte
## lu, énigmes), pas sur le bois et sur la pierre dans chaque lieu, eau de la rivière, feuillage et oiseaux du hub.

const LEVELS := "res://scenes/levels/%s/%s.tscn"
const STEP_SOUNDS := {
	&"wood": ["footstep_wood_1", "footstep_wood_2", "footstep_wood_3"],
	&"stone": ["footstep_stone_1", "footstep_stone_2", "footstep_stone_3"],
}
const PUZZLES := [
	"res://scenes/levels/plaine/tablet_puzzle.tscn", "res://scenes/levels/desert/rune_puzzle.tscn",
	"res://scenes/levels/marais/ring_puzzle.tscn", "res://scenes/levels/village/code_puzzle.tscn",
	"res://scenes/levels/village/paper_notebook.tscn",
]

var sounds: Node


func _initialize() -> void:
	_run.call_deferred()


func played(kind: StringName) -> int:
	return sounds.played[kind]


func _run() -> void:
	sounds = root.get_node("UiSounds")
	state = root.get_node("GameState")
	state.reset()
	_check_files()
	_check_export()
	_check_bus()
	_check_surface_tables()
	_check_village_houses()
	await _check_player_steps()
	await _check_menu_click()
	await _check_puzzle_panels()
	await _check_hub()
	finish()


func _check_files() -> void:
	for name in ["ui_click", "ui_open", "ui_close", "footstep_wood_1", "footstep_wood_2", "footstep_wood_3",
			"footstep_stone_1", "footstep_stone_2", "footstep_stone_3", "bird_1", "bird_2", "bird_3"]:
		var stream := load("res://assets/audio/%s.wav" % name) as AudioStreamWAV
		check("%s : son court, sans boucle" % name, stream != null and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED
			and stream.get_length() < 1.2)
	for name in ["river", "park_leaves"]:
		var stream := load("res://assets/audio/%s.wav" % name) as AudioStreamWAV
		check("%s : boucle entière (%s)" % [name, stream.loop_end if stream else -1], stream != null
			and stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_begin == 0
			and stream.loop_end >= int(stream.get_length() * stream.mix_rate) - 2)


## L'export ne suit pas les preload() des scripts : un son préchargé doit être dans include_filter des préréglages
## « Web » et « Windows Desktop » (export_presets.cfg), ou le script ne se compile pas dans le jeu exporté.
func _check_export() -> void:
	var config := ConfigFile.new()
	check("export_presets.cfg lu", config.load("res://export_presets.cfg") == OK)
	var filters := {}
	for section in config.get_sections():
		if section.ends_with(".options") or not config.has_section_key(section, "include_filter"):
			continue
		var preset: String = config.get_value(section, "name")
		if preset in ["Web", "Windows Desktop"]:
			filters[preset] = Array(String(config.get_value(section, "include_filter")).split(",")).map(
				func(pattern: String) -> String: return "res://" + pattern.strip_edges())
	check("préréglages Web et Windows Desktop", filters.size() == 2)
	var preload_pattern := RegEx.create_from_string("preload\\(\"(res://assets/audio/[^\"]+)\"\\)")
	var scripts: Array[String] = []
	for folder in ["res://scripts", "res://scenes"]:
		_collect_scripts(folder, scripts)
	var checked := 0
	for script_path in scripts:
		for found in preload_pattern.search_all(FileAccess.get_file_as_string(script_path)):
			var sound := found.get_string(1)
			checked += 1
			for preset: String in filters:
				var listed: bool = filters[preset].any(func(pattern: String) -> bool: return sound.match(pattern))
				if not listed:
					check("%s, préchargé par %s : dans l'export %s" % [sound, script_path.get_file(), preset], false)
	check("%d sons préchargés par les scripts, tous exportés" % checked, checked >= 15)


func _collect_scripts(folder: String, into: Array[String]) -> void:
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			into.append(folder.path_join(file))
	for sub in DirAccess.get_directories_at(folder):
		_collect_scripts(folder.path_join(sub), into)


func _check_bus() -> void:
	var index := AudioServer.get_bus_index(&"Interface")
	check("bus Interface", index >= 0)
	if index >= 0:
		check("bus Interface vers Master, %.1f dB" % AudioServer.get_bus_volume_db(index),
			AudioServer.get_bus_send(index) == &"Master" and AudioServer.get_bus_volume_db(index) < -3.0)
	for player: AudioStreamPlayer in sounds.find_children("*", "AudioStreamPlayer", false, false):
		check("lecteur %s sur le bus Interface" % player.name, player.bus == &"Interface")


## Tables de surfaces : un point de chaque zone, et le sol propre au lieu autour.
func _check_surface_tables() -> void:
	var points := {
		"hub": [
			[Vector3(78, -40, 0), 0, &"wood", "abri du bunker"],
			[Vector3(-9.2, 0, -22.2), 0, &"wood", "maison du village"],
			[Vector3(-24, 0, 66), 0, &"wood", "halle du marché"],
			[Vector3(-70, 0, 58), 0, &"wood", "salle de l'observatoire"],
			[Vector3(-68, 0, 60), 0, &"", "dehors, contre la tour tournée de l'observatoire"],
			[Vector3(0, 0.1, -70), 0, &"stone", "cour du château"],
			[Vector3(0, 0, -85), 0, &"stone", "salle du trône"],
			[Vector3(63.25, 0.1, 0), 0, &"wood", "grand pont de fortune"],
			[Vector3(63.25, 0.1, 0), 1, &"stone", "grand pont reconstruit"],
			[Vector3(63, 0.1, -66), 3, &"wood", "passerelle du jardin"],
			[Vector3(36, 0.26, -82), 3, &"stone", "estrade du kiosque"],
			[Vector3(54, 0.03, 6.5), 0, &"stone", "dallage du lavoir"],
			[Vector3(0, 0.1, 12), 0, &"", "place du feu de camp"],
			[Vector3(40, 0.1, -60), 0, &"", "pelouse du jardin"],
		],
		"plaine": [
			[Vector3(0, 0.04, 29.5), 0, &"stone", "pont de pierre"],
			[Vector3(0, 0.0, 12), 0, &"", "chemin de cendre"],
			[Vector3(0, -40, -20), 0, &"stone", "archives"],
		],
		"desert": [
			[Vector3(0, 0.02, -6), 0, &"stone", "salle des colonnes"],
			[Vector3(0, 0.0, 30), 0, &"", "allée de sable"],
			[Vector3(-30, 0.5, -4.5), 0, &"stone", "escalier de la citerne"],
			[Vector3(-30, -1.6, -2.5), 0, &"", "fond de sable de la citerne"],
			[Vector3(0, -40, -6), 0, &"stone", "cave des archives"],
		],
		"marais": [
			[Vector3(-10.5, 0.35, 37.5), 0, &"wood", "ponton"],
			[Vector3(-10.5, -0.4, 37.5), 0, &"", "dans l'eau, sous le ponton"],
			[Vector3(10.9, 0.35, 52.2), 0, &"wood", "débarcadère"],
			[Vector3(14, 0.4, 1.6), 0, &"stone", "allée du cimetière"],
			[Vector3(-36, 0.3, -4), 0, &"stone", "nef de la chapelle"],
			[Vector3(-22.5, 0.4, 21), 0, &"", "îlot du gardien"],
			[Vector3(0, -40, 0), 0, &"stone", "crypte"],
		],
		"village": [
			[Vector3(-10, 0, 30), 0, &"wood", "maison"],
			[Vector3(0, 0, -2), 0, &"stone", "place pavée"],
			[Vector3(0, 0, 40), 0, &"stone", "grande rue"],
			[Vector3(-20, 0, 6), 0, &"stone", "rue du pont"],
			[Vector3(-38, 0.14, 6), 0, &"wood", "pont du ruisseau"],
			[Vector3(22, 0, 40), 0, &"", "terre battue"],
			[Vector3(0, -40, 0), 0, &"wood", "accueil de la mairie"],
			[Vector3(-12, -35.5, 0), 0, &"stone", "salle secrète"],
		],
	}
	for place: String in points:
		var surfaces := FootstepSurfaces.for_scene(LEVELS % [place, place])
		check("%s : surfaces" % place, surfaces != null)
		if not surfaces:
			continue
		for point: Array in points[place]:
			var found := surfaces.at(point[0], point[1])
			check("%s, %s : %s" % [place, point[3], found if found else "sol du lieu"], found == point[2])
	check("pas de surfaces au menu", FootstepSurfaces.for_scene("res://scenes/ui/menus/main_menu.tscn") == null)


## Les maisons du Village sont recopiées de tools/build_village.py : elles doivent y être toutes, au même endroit.
func _check_village_houses() -> void:
	var text := FileAccess.get_file_as_string("res://tools/build_village.py")
	var start := text.find("HOUSES = (")
	var block := text.substr(start, text.find("\n)", start) - start)
	var pattern := RegEx.create_from_string("\\((-?[0-9.]+), (-?[0-9.]+), ([0-9]+), ([0-9]+), \"")
	var houses: Array[Vector4] = []
	for found in pattern.search_all(block):
		houses.append(Vector4(found.get_string(1).to_float(), found.get_string(2).to_float(),
			found.get_string(3).to_float(), found.get_string(4).to_float()))
	check("maisons du Village : %d dans build_village.py, %d dans FootstepSurfaces" % [houses.size(),
		FootstepSurfaces.VILLAGE_HOUSES.size()], houses == FootstepSurfaces.VILLAGE_HOUSES)


## Le joueur a son lecteur de pas même sans pas donnés dans sa scène : le Désert et le Marais ne les lui donnent qu'après
## son _ready, depuis le leur.
func _check_player_steps() -> void:
	var lone: Node = (load("res://scenes/player/player.tscn") as PackedScene).instantiate()
	root.add_child(lone)
	await settle()
	check("lecteur de pas sans pas donnés d'avance", lone.get("_footsteps") != null)
	lone.queue_free()
	await settle()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Menu d'accueil : un clic de souris sur un bouton actif sonne, pas sur un bouton grisé ni à côté.
func _check_menu_click() -> void:
	root.get_node("Account").logout()
	change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
	await wait(20)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var before := played(&"click")
	await _mouse_press(current_scene.find_child("NewGame", true, false) as Control)
	check("clic sur « Jouer » (%d)" % (played(&"click") - before), played(&"click") == before + 1)
	before = played(&"click")
	await _mouse_press(current_scene.find_child("LoadGame", true, false) as Control)
	check("pas de clic sur un bouton grisé", played(&"click") == before)
	before = played(&"click")
	await _mouse_press(null)
	check("pas de clic à côté des boutons", played(&"click") == before)


## Appuie (sans relâcher sur lui) au centre du contrôle, ou dans un coin vide de l'écran. Les positions sont celles du
## canevas de référence (1920 × 1080), d'où push_input(…, true) : sans fenêtre, comme dans une fenêtre étirée.
func _mouse_press(control: Control) -> void:
	var point := control.get_global_rect().get_center() if control else Vector2(4, 4)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await settle()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = point
	press.global_position = point
	root.push_input(press, true)
	await settle()
	# Relâché ailleurs : le bouton n'est pas actionné, le menu ne change pas.
	var away := Vector2(4, 4)
	motion = InputEventMouseMotion.new()
	motion.position = away
	motion.global_position = away
	root.push_input(motion, true)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = away
	release.global_position = away
	root.push_input(release, true)
	await settle()


## Panneaux d'énigme : chacun sonne à l'ouverture et à la fermeture.
func _check_puzzle_panels() -> void:
	for path: String in PUZZLES:
		var panel: Node = (load(path) as PackedScene).instantiate()
		root.add_child(panel)
		await settle()
		var panel_root := panel.find_child("Root", false, false) as Control
		check("%s : racine du panneau" % path.get_file(), panel_root != null)
		if panel_root:
			var opened := played(&"open")
			var closed := played(&"close")
			panel_root.show()
			await settle()
			check("%s : ouverture" % path.get_file(), played(&"open") == opened + 1 and played(&"close") == closed)
			await wait(6)
			panel_root.hide()
			await settle()
			check("%s : fermeture" % path.get_file(), played(&"close") == closed + 1)
		panel.queue_free()
		await settle()


func _check_hub() -> void:
	await start_level("res://scenes/levels/hub/hub.tscn")
	# Dans le bunker : plancher de bois.
	await _step_check(player.global_position, &"wood", "pas dans l'abri du bunker")
	var hub_sounds: Node = level.get_node("Sounds")
	await wait(12)
	check("aucune source du dehors dans le bunker", hub_sounds.active_sources() == 0)

	# Pause, indices et texte lu.
	var opened := played(&"open")
	var closed := played(&"close")
	var pause: Node = root.get_node("PauseMenu")
	pause.open()
	await settle()
	pause.close()
	await settle()
	check("pause : ouverture et fermeture", played(&"open") == opened + 1 and played(&"close") == closed + 1)
	await wait(6)
	var hints: Node = root.get_node("Hints")
	hints.open()
	await settle()
	hints.close()
	await settle()
	check("indices : ouverture et fermeture", played(&"open") == opened + 2 and played(&"close") == closed + 2)
	await wait(6)
	hud().show_text("Essai", "Texte d'essai.")
	await settle()
	check("texte lu : ouverture", played(&"open") == opened + 3)
	await press("interact")
	check("texte lu : fermeture", played(&"close") == closed + 3 and not hud().get_node("%Reader").visible)

	# Dehors : la mission commence, le joueur sort au feu de camp.
	state.begin_mission()
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await wait(60)
	level = current_scene
	player = level.get_node("Player")
	hub_sounds = level.get_node("Sounds")
	var terrain: HubTerrain = level.get_node("Terrain")
	await _step_check(_ground(terrain, 0, 12), &"", "pas sur l'herbe de la place")
	await _step_check(_ground(terrain, -9.2, -22.2), &"wood", "pas dans une maison")
	await _step_check(_ground(terrain, 0, -66), &"stone", "pas dans la cour du château")
	await _step_check(Vector3(63.25, 0.4, -1.0), &"wood", "pas sur le grand pont de fortune")
	player.global_position = _ground(terrain, 0, 12)
	await wait(20)
	check("place du village : aucune source (%d)" % hub_sounds.active_sources(), hub_sounds.active_sources() == 0)

	# Au bord de la rivière : sa source joue, au plus près, au ras de l'eau.
	player.global_position = _ground(terrain, 53, -24)
	await wait(20)
	var river: AudioStreamPlayer3D = hub_sounds.get_node("River")
	check("rivière entendue de la berge (%s)" % river.global_position.snappedf(0.1), river.playing
		and absf(river.global_position.x - 61.0) < 1.5 and absf(river.global_position.z - -24.0) < 1.5)
	check("rivière sous la musique : %.1f dB, au plus %.1f dB tout près" % [river.volume_db, river.max_db],
		river.volume_db <= -13.0 and river.max_db <= river.volume_db + 1.0)

	# Jardin du roi, avant sa reconstruction : feuilles mortes, ni oiseaux ni roue.
	player.global_position = _ground(terrain, 36, -62)
	await wait(20)
	var leaves: AudioStreamPlayer3D = hub_sounds.get_node("Leaves")
	var bird: AudioStreamPlayer3D = hub_sounds.get_node("Bird")
	check("feuillage dans le jardin, au plus %.1f dB" % leaves.max_db, leaves.playing and leaves.global_position.y > 2.0
		and leaves.max_db <= -10.0)
	hub_sounds.set("_bird_wait", 0.0)
	await wait(20)
	check("pas d'oiseaux avant le jardin reconstruit", not bird.playing)
	check("au plus 3 sources (%d)" % hub_sounds.active_sources(), hub_sounds.active_sources() <= 3)

	# Deux livres posés : le jardin reconstruit retrouve ses oiseaux, la roue du moulin bat l'eau.
	state.placed_books.assign([&"projenomicon", &"algonicon"])
	hub_sounds.set("_bird_wait", 0.0)
	await wait(20)
	check("un oiseau chante au jardin (%s)" % bird.global_position.snappedf(0.1), bird.playing
		and HubTerrain.PARK_AREA.has_point(Vector2(bird.global_position.x, bird.global_position.z)))
	check("au plus 3 sources au jardin (%d)" % hub_sounds.active_sources(), hub_sounds.active_sources() <= 3)
	player.global_position = _ground(terrain, 64, 44)
	await wait(20)
	check("roue du moulin", hub_sounds.get_node("MillWheel").playing)
	check("loin du jardin, l'oiseau se tait", not bird.playing)
	state.placed_books.clear()


func _ground(terrain: HubTerrain, x: float, z: float) -> Vector3:
	return Vector3(x, terrain.surface_height(x, z) + 0.2, z)


## Pose le joueur, attend qu'il touche le sol, puis lui fait faire un pas : sa surface et le son joué.
func _step_check(at: Vector3, expected: StringName, label: String) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	await wait(15)
	player.set("_stride", 100.0)
	await wait(3)
	var surface: StringName = player.footstep_surface
	var stream: AudioStream = player.get("_footsteps").stream
	var file := stream.resource_path.get_file().get_basename() if stream else ""
	var expected_files: Array = STEP_SOUNDS.get(expected, [])
	var sound_ok := file in expected_files if expected else not file.begins_with("footstep_wood") and not file.begins_with("footstep_stone")
	check("%s : %s, %s (%s)" % [label, surface if surface else "sol du lieu", file, player.global_position.snappedf(0.1)],
		surface == expected and sound_ok)
