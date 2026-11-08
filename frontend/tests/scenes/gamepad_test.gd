extends "res://tests/scenes/common_test.gd"
## Manette (scripts/gamepad.gd) : de vrais événements de manette (InputEventJoypadButton, InputEventJoypadMotion), comme
## ceux d'une manette branchée, sur l'accueil, la connexion et le clavier virtuel, puis dans le Marais (déplacement,
## caméra, saut, PNJ, panneau, pause, indices, mécanisme aux cinq cercles) et au Village (dispositif des codes avec le
## clavier virtuel, carnet). Vérifie aussi la bascule des invites entre la manette et le clavier, et qu'au clavier les
## boutons ne prennent toujours pas le focus.


func _initialize() -> void:
	_run.call_deferred()


## Appuie puis relâche un bouton de la manette ; settle() après chaque événement injecté.
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


## Incline un stick (ou le relâche avec 0).
func stick(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	await settle()


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await settle()
	var release := InputEventKey.new()
	release.keycode = code
	release.physical_keycode = code
	release.pressed = false
	Input.parse_input_event(release)
	await settle()


func focus_name() -> String:
	var owner := root.gui_get_focus_owner()
	return String(owner.name) if owner else "<aucun>"


## Touche dessinée de l'invite (Ornate.KeyCap).
func prompt_key() -> Node:
	for child in hud().get_node("PromptPlate").get_children():
		if child.has_method("glyph"):
			return child
	return null


## Interactable dont l'invite contient ce texte.
func find_prompt(text: String) -> Node3D:
	for node in level.find_children("*", "Node3D", true, false):
		var value: Variant = node.get("prompt")
		if value is String and String(value).contains(text) and node.get("enabled") == true:
			return node as Node3D
	return null


## Place le joueur à 1,6 m de la cible, tourné vers elle, en essayant plusieurs côtés, jusqu'à voir son invite.
func approach(target: Node3D, expected: String) -> bool:
	for step in 8:
		var angle := step * TAU / 8.0
		var spot := target.global_position + Vector3(sin(angle), 0.0, cos(angle)) * 1.6
		player.global_position = Vector3(spot.x, target.global_position.y + 0.3, spot.z)
		player.velocity = Vector3.ZERO
		await wait(20)
		await face(target.global_position)
		await settle()
		if prompt().contains(expected):
			return true
	return false


func _run() -> void:
	state = root.get_node("GameState")
	await _menu()
	await _marais()
	await _village()
	finish()


# --- Accueil, introduction, connexion et clavier virtuel ------------------------------------------------------

func _menu() -> void:
	var account: Node = root.get_node("Account")
	account.logout()
	if "simulated" in account:
		account.simulated = true
	state.use_profile("")
	state.reset()
	change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
	await wait(10)
	await key(KEY_SHIFT)
	var menu := current_scene
	check("au clavier, aucun bouton ne prend le focus", menu.find_child("NewGame", true, false).focus_mode == Control.FOCUS_NONE and root.gui_get_focus_owner() == null)
	check("au clavier, rappel des touches", menu.find_child("PadShortcuts", true, false).visible == false)

	await pad(JOY_BUTTON_DPAD_DOWN)
	check("bouton de la manette : mode manette", Gamepad.active)
	check("premier appui : le bouton mis en avant est choisi, sans bouger (%s)" % focus_name(), focus_name() == "NewGame")
	check("rappel des boutons de la manette", menu.find_child("PadShortcuts", true, false).visible)
	await pad(JOY_BUTTON_DPAD_RIGHT)
	check("croix droite : carte du joueur (%s)" % focus_name(), focus_name() == "Seconnecter")
	await pad(JOY_BUTTON_DPAD_LEFT)
	check("croix gauche : retour aux boutons du milieu (%s)" % focus_name(), focus_name() in ["NewGame", "LoadGame"])
	menu.find_child("NewGame", true, false).grab_focus()
	await pad(JOY_BUTTON_DPAD_DOWN)
	check("croix bas : Charger partie (%s)" % focus_name(), focus_name() == "LoadGame")
	await pad(JOY_BUTTON_DPAD_UP)
	await pad(JOY_BUTTON_A)
	await wait(3)
	check("A : introduction", menu.current_screen() == &"intro")
	await settle()
	check("introduction : Commencer choisi (%s)" % focus_name(), focus_name() == "Commencer")
	await pad(JOY_BUTTON_B)
	await wait(3)
	check("B : retour à l'accueil", menu.current_screen() == &"home")

	# Connexion : A sur le champ ouvre le clavier virtuel, qui écrit dans le champ.
	menu.show_screen(&"login")
	await wait(3)
	await settle()
	check("connexion : champ de l'adresse choisi (%s)" % focus_name(), focus_name().begins_with("@LineEdit") or root.gui_get_focus_owner() is LineEdit)
	var email: LineEdit = root.gui_get_focus_owner() as LineEdit
	await pad(JOY_BUTTON_A)
	check("A sur le champ : clavier virtuel", PadKeyboard.current() != null)
	check("clavier : touche 1 choisie (%s)" % focus_name(), focus_name() == "Key00")
	await pad(JOY_BUTTON_DPAD_DOWN)
	await pad(JOY_BUTTON_A)
	await pad(JOY_BUTTON_DPAD_RIGHT)
	await pad(JOY_BUTTON_A)
	check("clavier : « ab » écrit (%s)" % email.text, email.text == "ab")
	await pad(JOY_BUTTON_X)
	check("X efface (%s)" % email.text, email.text == "a")
	await pad(JOY_BUTTON_LEFT_SHOULDER)
	await pad(JOY_BUTTON_A)
	check("LB : majuscules (%s)" % email.text, email.text == "aB")
	await pad(JOY_BUTTON_START)
	check("Menu valide : clavier fermé", PadKeyboard.current() == null)
	check("adresse validée : le mot de passe prend la main", root.gui_get_focus_owner() is LineEdit and root.gui_get_focus_owner() != email)
	await pad(JOY_BUTTON_A)
	check("A : clavier sur le mot de passe", PadKeyboard.current() != null)
	await pad(JOY_BUTTON_B)
	check("B : clavier fermé", PadKeyboard.current() == null)
	await pad(JOY_BUTTON_B)
	await wait(3)
	check("B : retour à l'accueil depuis la connexion", menu.current_screen() == &"home")

	# Code de vérification : le clavier virtuel remplit les six cases, chiffre par chiffre.
	menu.show_screen(&"verify")
	await wait(3)
	await settle()
	var boxes: Node = menu.find_child("Code", true, false)
	check("vérification : première case choisie", root.gui_get_focus_owner() == boxes.boxes[0])
	await pad(JOY_BUTTON_A)
	await pad(JOY_BUTTON_A)
	await pad(JOY_BUTTON_DPAD_RIGHT)
	await pad(JOY_BUTTON_A)
	check("clavier : « 12 » dans les cases (%s)" % boxes.code(), boxes.code() == "12")
	await pad(JOY_BUTTON_X)
	check("X : dernier chiffre effacé (%s)" % boxes.code(), boxes.code() == "1")
	await pad(JOY_BUTTON_B)
	check("B : clavier fermé, case suivante choisie", PadKeyboard.current() == null and root.gui_get_focus_owner() == boxes.boxes[1])
	await pad(JOY_BUTTON_B)
	await wait(3)
	check("B : retour à la connexion", menu.current_screen() == &"login")
	await pad(JOY_BUTTON_B)
	await wait(3)
	check("B : retour à l'accueil", menu.current_screen() == &"home")

	await key(KEY_SHIFT)
	check("touche du clavier : mode clavier", not Gamepad.active)
	check("au clavier, plus de bouton choisi", root.gui_get_focus_owner() == null and menu.find_child("NewGame", true, false).focus_mode == Control.FOCUS_NONE)


# --- Marais : déplacement, caméra, PNJ, panneau, pause, indices, cercles -------------------------------------

func _marais() -> void:
	await start_level("res://scenes/levels/marais/marais.tscn")
	await wait(30)
	await key(KEY_SHIFT)
	check("au clavier dans le jeu", not Gamepad.active)

	# Déplacement au stick gauche.
	var pivot: Node3D = player.get_node("CameraPivot")
	var start := player.global_position
	await stick(JOY_AXIS_LEFT_Y, -1.0)
	check("stick gauche : mode manette", Gamepad.active)
	await wait(40)
	await stick(JOY_AXIS_LEFT_Y, 0.0)
	await wait(10)
	var moved := Vector2(player.global_position.x - start.x, player.global_position.z - start.z)
	var forward := Vector2(-sin(pivot.rotation.y), -cos(pivot.rotation.y))
	check("stick gauche : le joueur avance (%.1f m)" % moved.dot(forward), moved.dot(forward) > 1.0)

	# Caméra au stick droit.
	var yaw := pivot.rotation.y
	var pitch := pivot.rotation.x
	await stick(JOY_AXIS_RIGHT_X, 1.0)
	await wait(20)
	await stick(JOY_AXIS_RIGHT_X, 0.0)
	check("stick droit : la caméra tourne à droite (%.2f rad)" % (yaw - pivot.rotation.y), yaw - pivot.rotation.y > 0.3)
	await stick(JOY_AXIS_RIGHT_Y, 1.0)
	await wait(10)
	await stick(JOY_AXIS_RIGHT_Y, 0.0)
	check("stick droit : la caméra regarde vers le bas (%.2f rad)" % (pitch - pivot.rotation.x), pitch - pivot.rotation.x > 0.1)
	pivot.rotation.x = 0.0
	var turned := pivot.rotation.y
	await stick(JOY_AXIS_RIGHT_X, 0.08)
	await wait(20)
	await stick(JOY_AXIS_RIGHT_X, 0.0)
	check("stick droit : zone morte (%.3f rad)" % absf(turned - pivot.rotation.y), absf(turned - pivot.rotation.y) < 0.001)

	# Saut (X) et course (B).
	await wait(10)
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_X
	event.pressed = true
	Input.parse_input_event(event)
	await wait(6)
	check("X : saut", not player.is_on_floor() or player.velocity.y > 0.5)
	event = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_X
	Input.parse_input_event(event)
	await wait(60)
	check("sprint lié à B", InputMap.event_is_action(_button(JOY_BUTTON_B), &"sprint"))

	# PNJ : l'invite montre A, puis E au clavier ; A ouvre son texte, B le referme.
	var ghost := find_prompt("Parler")
	check("PNJ trouvé", ghost != null)
	if ghost:
		check("devant le PNJ", await approach(ghost, "Parler"))
		check("invite du PNJ : %s" % prompt(), prompt().contains("Parler"))
		var cap: Node = prompt_key()
		check("invite à la manette : bouton A (%s)" % cap.glyph(), cap.glyph() == "A")
		await key(KEY_SHIFT)
		check("invite au clavier : touche E (%s / %s)" % [cap.glyph(), cap.text], cap.glyph() == "" and cap.text == "E")
		await pad(JOY_BUTTON_DPAD_UP)
		check("invite de nouveau à la manette (%s)" % cap.glyph(), cap.glyph() == "A")
		await pad(JOY_BUTTON_A)
		check("A : le PNJ parle", hud().get_node("%Reader").visible)
		await pad(JOY_BUTTON_B)
		check("B : texte refermé", not hud().get_node("%Reader").visible)

	# Panneau du marais.
	var sign := find_prompt("Lire le panneau")
	check("panneau trouvé", sign != null)
	if sign:
		check("devant le panneau", await approach(sign, "panneau"))
		await pad(JOY_BUTTON_A)
		check("A : panneau lu (%s)" % hud().get_node("%ReaderTitle").text, hud().get_node("%Reader").visible)
		await pad(JOY_BUTTON_A)
		check("A : panneau refermé", not hud().get_node("%Reader").visible)

	# Pause.
	var pause: Node = root.get_node("PauseMenu")
	await pad(JOY_BUTTON_START)
	check("Menu : pause ouverte", pause.is_open() and paused)
	check("pause : Reprendre choisi (%s)" % focus_name(), focus_name() == "Resume")
	await pad(JOY_BUTTON_DPAD_DOWN)
	check("croix bas : Menu principal (%s)" % focus_name(), focus_name() == "MainMenu")
	await pad(JOY_BUTTON_DPAD_UP)
	await pad(JOY_BUTTON_A)
	check("A sur Reprendre : pause fermée", not pause.is_open() and not paused)
	await pad(JOY_BUTTON_START)
	await pad(JOY_BUTTON_B)
	check("B : pause fermée", not pause.is_open() and not paused)

	# Indices : Y ouvre, B ou A sur « Fermer » referme, la croix relit les précédents.
	var hints: Node = root.get_node("Hints")
	await pad(JOY_BUTTON_Y)
	check("Y : indices ouverts", hints.is_open() and paused)
	check("indices : Fermer choisi (%s)" % focus_name(), focus_name() == "Done")
	var counter: Label = hints.get_node("Hint").find_child("Counter", true, false)
	check("indices : « rouvrez avec Y » (%s)" % counter.text, counter.text.contains("avec Y"))
	await pad(JOY_BUTTON_B)
	check("B : indices fermés", not hints.is_open() and not paused)
	await pad(JOY_BUTTON_Y)
	await pad(JOY_BUTTON_A)
	check("A sur Fermer : indices fermés", not hints.is_open())
	await pad(JOY_BUTTON_Y)
	check("troisième indice : %s" % counter.text, counter.text.begins_with("Indice 3 sur 3"))
	await pad(JOY_BUTTON_DPAD_LEFT)
	check("croix gauche : indice précédent (%s)" % counter.text, counter.text.begins_with("Indice 2 sur 3"))
	await pad(JOY_BUTTON_DPAD_RIGHT)
	check("croix droite : indice suivant (%s)" % counter.text, counter.text.begins_with("Indice 3 sur 3"))
	await pad(JOY_BUTTON_Y)
	check("Y : indices fermés", not hints.is_open() and not paused)
	check("indices à la manette : « maintenez A »", Gamepad.adapt("maintenez E devant un tas") == "maintenez A devant un tas")
	check("indices à la manette : « avec le bouton Affichage »", Gamepad.adapt("Relisez-les avec I.") == "Relisez-les avec le bouton Affichage.")
	check("indices à la manette : un mot qui commence par H ne change pas", Gamepad.adapt("avec Hexcole") == "avec Hexcole")

	# Mécanisme aux cinq cercles : la croix choisit une flèche, A tourne le cercle, puis « Valider ».
	await level._travel(true)
	await wait(30)
	player.global_position = Vector3(0, -40, -7.0)
	player.velocity = Vector3.ZERO
	await wait(10)
	await face(Vector3(0, -40, -12))
	check("invite du mécanisme : %s" % prompt(), prompt().contains("mécanisme"))
	await pad(JOY_BUTTON_A)
	await wait(5)
	var puzzle: Node = level.get_node("RingPuzzle")
	var mechanism: Node = level.mechanism()
	check("A : mécanisme ouvert", puzzle.is_open())
	check("cercles : flèche du cercle I choisie (%s)" % focus_name(), focus_name() == "Right0")
	var first: int = mechanism.letters[0]
	await pad(JOY_BUTTON_A)
	check("A : le cercle I avance d'une lettre", mechanism.letters[0] == (first + 1) % mechanism.LETTERS.length())
	await pad(JOY_BUTTON_DPAD_RIGHT)
	check("croix droite : flèche gauche du cercle II (%s)" % focus_name(), focus_name() == "Left1")
	var second: int = mechanism.letters[1]
	await pad(JOY_BUTTON_A)
	check("A : le cercle II recule d'une lettre", mechanism.letters[1] == posmod(second - 1, mechanism.LETTERS.length()))
	for ring in 5:
		var target: int = mechanism.LETTERS.find("FLGFD"[ring])
		while mechanism.letters[ring] != target:
			puzzle.turn(ring, 1)
	await wait(20)
	await pad(JOY_BUTTON_DPAD_DOWN)
	check("croix bas : Valider (%s)" % focus_name(), focus_name() == "Validate")
	await pad(JOY_BUTTON_A)
	await wait(5)
	check("A sur Valider : FLGFD accepté", not puzzle.is_open())
	await wait(60)


func _button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	return event


# --- Village : dispositif des codes et clavier virtuel, carnet -------------------------------------------------

func _village() -> void:
	await start_level("res://scenes/levels/village/village.tscn")
	await wait(30)
	await pad(JOY_BUTTON_DPAD_UP)
	check("manette au Village", Gamepad.active)
	# Carnet : Affichage l'ouvre, le stick droit le fait défiler, B le referme.
	for index in level.FRAGMENTS.size():
		level._found[index] = level.FRAGMENTS[index]
	await pad(JOY_BUTTON_BACK)
	var notebook: Node = level.get_node("PaperNotebook")
	check("Affichage : carnet ouvert", notebook.is_open())
	var scroll: ScrollContainer = notebook.find_child("Scroll", true, false)
	await stick(JOY_AXIS_RIGHT_Y, 1.0)
	await wait(20)
	await stick(JOY_AXIS_RIGHT_Y, 0.0)
	check("stick droit : le carnet défile (%d px)" % scroll.scroll_vertical, scroll.scroll_vertical > 50)
	await pad(JOY_BUTTON_B)
	check("B : carnet fermé", not notebook.is_open() and player.process_mode == Node.PROCESS_MODE_INHERIT)
	level._found.clear()

	# Dispositif des codes : A sur le champ ouvre le clavier virtuel, qui rappelle la question.
	await level._travel(true)
	await wait(30)
	level._open_device()
	await wait(5)
	await settle()
	var puzzle: Node = level.get_node("CodePuzzle")
	var answer: LineEdit = puzzle.get_node("%Answer")
	check("dispositif ouvert", puzzle.is_open())
	check("dispositif : champ de réponse choisi (%s)" % focus_name(), root.gui_get_focus_owner() == answer)
	await pad(JOY_BUTTON_A)
	var keyboard: Node = PadKeyboard.current()
	check("A : clavier virtuel", keyboard != null)
	if keyboard:
		var context: Label = keyboard.find_child("Context", true, false)
		check("clavier : la question est rappelée (%s)" % context.text, context.text.contains("Combien"))
	await pad(JOY_BUTTON_DPAD_RIGHT)
	await pad(JOY_BUTTON_DPAD_RIGHT)
	await pad(JOY_BUTTON_A)
	check("clavier : « 3 » écrit (%s)" % answer.text, answer.text == "3")
	await pad(JOY_BUTTON_START)
	await wait(3)
	check("Menu valide : code 1 résolu", puzzle.solved[0] and PadKeyboard.current() == null)
	await wait(80)
	check("épreuve suivante : CSS (%d)" % puzzle.current, puzzle.current == 1)
	await settle()
	check("dispositif : champ de réponse rechoisi (%s)" % focus_name(), root.gui_get_focus_owner() == answer)
	await pad(JOY_BUTTON_DPAD_RIGHT)
	check("croix droite : Valider (%s)" % focus_name(), focus_name() == "Validate")
	await pad(JOY_BUTTON_DPAD_UP)
	check("croix haut : un onglet (%s)" % focus_name(), root.gui_get_focus_owner() != null and root.gui_get_focus_owner().get_class() == "Button" and focus_name() != "Validate")
	await pad(JOY_BUTTON_B)
	check("B : dispositif fermé", not puzzle.is_open())
	await key(KEY_SHIFT)
	check("clavier : plus de focus manette", root.gui_get_focus_owner() == null or root.gui_get_focus_owner() is LineEdit)
