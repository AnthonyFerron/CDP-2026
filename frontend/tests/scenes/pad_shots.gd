extends "res://tests/scenes/common_test.gd"
## Captures à la manette (scripts/gamepad.gd) : accueil au focus de la manette et au clavier, clavier virtuel de la
## connexion, invite devant un PNJ à la manette et au clavier, lecteur, pause et indices, message « [I] » du Village,
## chaque panneau d'énigme avec le bouton sélectionné, le clavier virtuel du dispositif des codes.
##
##   godot --path frontend --resolution 1280x720 --script res://tests/scenes/pad_shots.gd -- <dossier> [menu|marais|plaine|desert|village…] --api=…
##
## Sans lieu, tout est capturé. Lancer avec une fenêtre (xvfb-run sur un serveur), sans --headless. Les entrées sont de
## vrais événements de manette (InputEventJoypadButton, InputEventJoypadMotion), comme ceux d'une manette branchée.

var out := ""
var only: PackedStringArray = []


func _initialize() -> void:
	_run.call_deferred()


func wanted(name: String) -> bool:
	return only.is_empty() or name in only


func shot(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + name + ".png")
	print("capture ", name)


## Appuie puis relâche un bouton de la manette.
func pad(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await wait(2)
	await settle()
	var release := InputEventJoypadButton.new()
	release.device = 0
	release.button_index = button
	release.pressed = false
	Input.parse_input_event(release)
	await wait(2)
	await settle()


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await settle()
	var release := InputEventKey.new()
	release.physical_keycode = code
	release.keycode = code
	release.pressed = false
	Input.parse_input_event(release)
	await settle()


func level_start(path: String) -> void:
	state = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	state.begin_mission()
	change_scene_to_file(path)
	await wait(90)
	level = current_scene
	player = level.get_node("Player")


func stand(position: Vector3, target: Vector3) -> void:
	player.global_position = position
	player.velocity = Vector3.ZERO
	await wait(10)
	await face(target)
	await wait(10)


func inside() -> void:
	await level._travel(true)
	await wait(30)
	hud().get_node("%Message").hide()
	hud().get_node("MessagePlate").hide()


func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	state = root.get_node("GameState")
	out = args[0] + "/"
	only = args.slice(1)
	DirAccess.make_dir_recursive_absolute(out)
	if wanted("menu"):
		await _menu()
	if wanted("marais"):
		await _marais()
	if wanted("plaine"):
		await _plaine()
	if wanted("desert"):
		await _desert()
	if wanted("village"):
		await _village()
	finish()


func _menu() -> void:
	var account: Node = root.get_node("Account")
	account.logout()
	state.use_profile("")
	state.reset()
	change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
	await wait(20)
	await key(KEY_SHIFT)
	await shot("menu_accueil_clavier")
	await pad(JOY_BUTTON_DPAD_DOWN)
	await shot("menu_accueil_manette")
	await pad(JOY_BUTTON_DPAD_RIGHT)
	await shot("menu_accueil_manette_carte")
	current_scene.show_screen(&"login")
	await wait(5)
	await pad(JOY_BUTTON_A)
	for button in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_A, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_A, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_A]:
		await pad(button)
	await shot("menu_connexion_clavier_virtuel")
	await pad(JOY_BUTTON_B)
	await pad(JOY_BUTTON_B)
	await wait(3)
	current_scene.show_screen(&"intro")
	await wait(5)
	await shot("menu_introduction_manette")


func _marais() -> void:
	await level_start("res://scenes/levels/marais/marais.tscn")
	await wait(30)
	var ghost := _find_prompt(level, "Parler")
	if ghost:
		var spot := ghost.global_position + Vector3(0, 0, 2.0)
		await stand(Vector3(spot.x, player.global_position.y, spot.z), ghost.global_position + Vector3.UP)
		await key(KEY_SHIFT)
		await wait(5)
		await shot("marais_invite_clavier")
		await pad(JOY_BUTTON_DPAD_UP)
		await wait(5)
		await shot("marais_invite_manette")
		await pad(JOY_BUTTON_A)
		await wait(5)
		await shot("marais_lecteur_manette")
		await pad(JOY_BUTTON_B)
	await pad(JOY_BUTTON_START)
	await wait(5)
	await shot("marais_pause_manette")
	await pad(JOY_BUTTON_DPAD_DOWN)
	await shot("marais_pause_manette_menu")
	await pad(JOY_BUTTON_B)
	await pad(JOY_BUTTON_Y)
	await wait(5)
	await shot("marais_indices_manette")
	await pad(JOY_BUTTON_B)
	await inside()
	level._open_mechanism()
	await wait(10)
	await pad(JOY_BUTTON_A)
	await pad(JOY_BUTTON_DPAD_RIGHT)
	await pad(JOY_BUTTON_DPAD_RIGHT)
	await shot("marais_cercles_manette")
	await pad(JOY_BUTTON_DPAD_DOWN)
	await shot("marais_cercles_manette_valider")


func _plaine() -> void:
	await level_start("res://scenes/levels/plaine/plaine.tscn")
	await inside()
	var found: Dictionary = level.found_fragments()
	for index in 4:
		found[index] = level.FRAGMENTS[index]
	level._open_tablet()
	await wait(10)
	await pad(JOY_BUTTON_DPAD_DOWN)
	await shot("plaine_tablette_manette")
	await pad(JOY_BUTTON_A)
	await pad(JOY_BUTTON_DPAD_LEFT)
	await shot("plaine_tablette_manette_case")
	await pad(JOY_BUTTON_A)
	await shot("plaine_tablette_manette_posee")


func _desert() -> void:
	await level_start("res://scenes/levels/desert/desert.tscn")
	await inside()
	level._inventory.clear()
	level._inventory.append_array([&"tant_que", &"puiser", &"si", &"pour", &"sinon"])
	level._open_table()
	await wait(10)
	await pad(JOY_BUTTON_DPAD_DOWN)
	await shot("desert_table_manette")
	await pad(JOY_BUTTON_A)
	await pad(JOY_BUTTON_DPAD_UP)
	await shot("desert_table_manette_case")


func _village() -> void:
	await level_start("res://scenes/levels/village/village.tscn")
	await wait(30)
	await pad(JOY_BUTTON_DPAD_UP)
	hud().show_message("Fragment de papier trouvé : 2 / 10. [I] pour relire vos fragments.")
	await wait(10)
	await shot("village_message_manette")
	for index in 4:
		level._found[index] = level.FRAGMENTS[index]
	await pad(JOY_BUTTON_BACK)
	await wait(10)
	await shot("village_carnet_manette")
	await pad(JOY_BUTTON_BACK)
	await inside()
	level._open_device()
	await wait(10)
	await shot("village_dispositif_manette")
	await pad(JOY_BUTTON_A)
	await wait(5)
	for button in [JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_A]:
		await pad(button)
	await shot("village_clavier_virtuel")
	await pad(JOY_BUTTON_START)
	await wait(20)
	await shot("village_dispositif_manette_resolu")


func _find_prompt(node: Node, text: String) -> Node3D:
	for child in node.find_children("*", "Node3D", true, false):
		var prompt: Variant = child.get("prompt")
		if prompt is String and String(prompt).contains(text):
			return child as Node3D
	return null
