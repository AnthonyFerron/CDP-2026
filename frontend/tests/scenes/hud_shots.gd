extends "res://tests/scenes/common_test.gd"
## Captures du HUD dans chaque lieu : chronomètre, invite devant un panneau et un PNJ, message, lecteur de texte,
## chronomètre au rouge, chaque panneau d'énigme ouvert (avec le bandeau « Mauvaise réponse »), menu pause et indices.
##
##   godot --path frontend --resolution 1280x720 --script res://tests/scenes/hud_shots.gd -- <dossier> [lieu...] --api=…
##
## Sans lieu, tous sont capturés ; sinon seulement ceux nommés : hub, plaine, desert, marais, village.
## Lancer avec une fenêtre (xvfb-run sur un serveur), sans --headless. Pour chaque panneau d'énigme ouvert, l'outil
## vérifie aussi que le chronomètre passe au-dessus sans en cacher le titre ni les boutons (lignes OK / ECHEC).

var out := ""
var only: PackedStringArray = []


func _initialize() -> void:
	_run.call_deferred()


func wanted(name: String) -> bool:
	if only.is_empty():
		return true
	for prefix in only:
		if name.begins_with(prefix) or prefix.begins_with(name):
			return true
	return false


func shot(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + name + ".png")
	print("capture ", name)


## Place le joueur à un point, tourné vers une cible, et laisse l'invite se mettre à jour.
func stand(position: Vector3, target: Vector3) -> void:
	player.global_position = position
	player.velocity = Vector3.ZERO
	await wait(10)
	await face(target)
	await wait(10)


## Passe le niveau à l'intérieur, comme sa porte (fondu, point d'arrivée), puis attend que le message d'arrivée parte.
func inside() -> void:
	await level._travel(true)
	await wait(30)
	hud().get_node("%Message").hide()
	hud().get_node("MessagePlate").hide()


func level_start(path: String, intro := true) -> void:
	state = root.get_node("GameState")
	state.reset()
	state.intro_done = intro
	if intro:
		state.begin_mission()
	change_scene_to_file(path)
	await wait(90)
	level = current_scene
	player = level.get_node("Player")


func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	state = root.get_node("GameState")
	out = args[0] + "/"
	only = args.slice(1)
	DirAccess.make_dir_recursive_absolute(out)

	if wanted("hub"):
		await _hub()
	if wanted("plaine"):
		await _plaine()
	if wanted("desert"):
		await _desert()
	if wanted("marais"):
		await _marais()
	if wanted("village"):
		await _village()
	finish()


func _hub() -> void:
	# Dans le bunker, avant la mission : invite devant le roi, puis son texte.
	await level_start("res://scenes/levels/hub/hub.tscn", false)
	var king: Node3D = level.get_node("Characters/Codeon")
	await stand(king.global_position + Vector3(0, 0, 2.2), king.global_position + Vector3.UP)
	await shot("hub_invite_pnj")
	king.interact()
	await wait(5)
	await shot("hub_lecteur_roi")
	await press("interact")
	# Dehors, la mission en cours : message d'arrivée, chronomètre, invite devant un panneau.
	await level_start("res://scenes/levels/hub/hub.tscn")
	hud().show_message("Le portail des plaines d'Hexcole vous attend au nord-ouest du village, non loin des ruines du château.")
	await wait(20)
	await shot("hub_dehors_message")
	var sign: Node3D = level.get_node("Lore/SchoolSign")
	var front: Vector3 = sign.global_position + sign.global_basis.z * 1.8
	await stand(Vector3(front.x, sign.global_position.y + 0.5, front.z), sign.global_position + Vector3(0, 1.2, 0))
	await shot("hub_invite_panneau")
	state.time_left = 4.0 * 60.0 + 12.0
	await wait(10)
	await shot("hub_chrono_rouge")
	state.time_left = 41.0 * 60.0 + 7.0
	root.get_node("PauseMenu").open()
	await wait(5)
	await shot("hub_pause")
	root.get_node("PauseMenu").close()
	await wait(5)
	root.get_node("Hints").open()
	await wait(5)
	await shot("hub_indices")
	root.get_node("Hints").close()
	await wait(5)


func _plaine() -> void:
	await level_start("res://scenes/levels/plaine/plaine.tscn")
	await wait(30)
	await shot("plaine_dehors")
	var books: Node = level.get_node("Interior/Books")
	for book in books.get_children():
		if book.fragment >= 0:
			book.interact()
			await wait(5)
			await shot("plaine_lecteur_parchemin")
			await press("interact")
			break
	hud().show_message("Fragment de conversation trouvé : 1 / 6")
	await wait(10)
	await shot("plaine_message")
	await inside()
	level._open_tablet()
	await wait(10)
	await shot("plaine_tablette")
	check_timer_over(level.get_node("TabletPuzzle"), "TabletPuzzle")
	state.penalize()
	await wait(20)
	await shot("plaine_tablette_penalite")


func _desert() -> void:
	await level_start("res://scenes/levels/desert/desert.tscn")
	await wait(30)
	await shot("desert_dehors")
	hud().set_prompt("Maintenir pour dégager le sable (40 %)")
	await wait(3)
	await shot("desert_invite_maintenir")
	hud().set_prompt("")
	level._read(level.get_node("Exterior/Clues/Caravan"))
	await wait(5)
	await shot("desert_lecteur_long")
	await press("interact")
	await inside()
	level._open_table()
	await wait(10)
	await shot("desert_table")
	check_timer_over(level.get_node("RunePuzzle"), "RunePuzzle")
	state.penalize()
	await wait(20)
	await shot("desert_table_penalite")


func _marais() -> void:
	await level_start("res://scenes/levels/marais/marais.tscn")
	await wait(30)
	await shot("marais_dehors")
	await inside()
	level._open_mechanism()
	await wait(10)
	await shot("marais_cercles")
	check_timer_over(level.get_node("RingPuzzle"), "RingPuzzle")
	state.penalize()
	await wait(20)
	await shot("marais_cercles_penalite")


func _village() -> void:
	await level_start("res://scenes/levels/village/village.tscn")
	await wait(30)
	await shot("village_dehors")
	hud().show_message("Fragment de papier trouvé : 2 / 10. [I] pour relire vos fragments.")
	await wait(10)
	await shot("village_message_touche")
	level._open_panel()
	level.get_node("PaperNotebook").open(level.found_fragments(), 10)
	await wait(10)
	await shot("village_carnet")
	check_timer_over(level.get_node("PaperNotebook"), "PaperNotebook")
	await press("inventory")
	await inside()
	level._open_device()
	await wait(10)
	await shot("village_dispositif")
	check_timer_over(level.get_node("CodePuzzle"), "CodePuzzle")
	state.penalize()
	await wait(20)
	await shot("village_dispositif_penalite")


## Comme dans timer_test : le chronomètre est au-dessus du panneau (couche plus haute), sans recouvrir le titre du
## panneau (plaque des cadres Ornate.Frame) ni aucun de ses boutons, croix de fermeture comprise.
func check_timer_over(panel: CanvasLayer, where: String) -> void:
	var clock: CanvasLayer = hud().get_node("Clock")
	var plate: Control = hud().get_node("Clock/TimerPlate")
	check("chronometre au-dessus de %s (couche %d sur %d)" % [where, clock.layer, panel.layer],
		clock.layer > panel.layer and clock.visible and plate.is_visible_in_tree())
	var area := plate.get_global_rect()
	var hidden: Array[String] = []
	for node in panel.find_children("*", "Control", true, false):
		var item := node as Control
		if not item.is_visible_in_tree():
			continue
		if item is BaseButton and item.get_global_rect().intersects(area):
			hidden.append(item.name)
		var title := str(item.get("title")) if item.get("title") != null else ""
		if not title.is_empty():
			var size: int = item.get("title_size")
			var font: Font = load("res://ui/cinzel_bold.tres")
			var plaque := Vector2(font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + size * 2.6, size * 1.9)
			var center := item.get_global_rect().position + Vector2(item.size.x / 2.0, 0.0)
			if Rect2(center - plaque / 2.0, plaque).intersects(area):
				hidden.append("titre " + title)
	check("chronometre sans rien cacher de %s %s" % [where, hidden], hidden.is_empty())
