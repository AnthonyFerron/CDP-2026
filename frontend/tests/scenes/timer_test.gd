extends "res://tests/scenes/common_test.gd"
## Chronometre du volcan : il s'ecoule, une penalite retire 5 minutes, puis l'eruption termine la partie : une seule
## fin, la cinematique du volcan au hub, puis le retour au menu principal avec la partie effacee.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/hub/hub.tscn")
	var frozen: float = state.time_left
	await wait(60)
	check("chronometre arrete avant la mission", absf(frozen - state.time_left) < 0.01)
	state.begin_mission()
	var start: float = state.time_left
	await wait(120)
	var elapsed: float = start - state.time_left
	check("le chronometre s'ecoule (%.2f s)" % elapsed, elapsed > 1.5 and elapsed < 2.5)
	# Le texte et la couleur du chronometre sont poses dans le _process du HUD : sous charge, wait() peut finir sur une
	# suite d'images physiques sans _process. settle() laisse passer des images completes avant de les lire.
	await settle()
	var timer: Label = hud().get_node("%Timer")
	check("affichage : " + timer.text, timer.visible and timer.text.begins_with("Éruption du volcan : 59:"))
	var before: float = state.time_left
	state.penalize()
	await wait(2)
	check("penalite de 5 minutes", absf(before - state.time_left - 300.0) < 0.5)
	check("affichage de la penalite", hud().get_node("%Penalty").visible)
	state.save_game()
	state.load_game()
	check("temps restant sauvegarde", absf(state.time_left - (before - 300.0)) < 1.0)

	state.time_left = 4.0 * 60.0
	await wait(2)
	await settle()
	check("chronometre au rouge sous 5 minutes", timer.modulate.r > 0.9 and timer.modulate.g < 0.5)
	state.time_left = 0.05
	await wait(10)
	check("eruption", state.has_erupted)
	await _check_eruption_ending("au hub")

	# Dans un lieu, une validation fausse qui epuise le temps, tablette ouverte, mene a la meme fin, au hub : la
	# tablette se ferme avant.
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	level._open_tablet()
	var tablet: CanvasLayer = level.get_node("TabletPuzzle")
	await wait(5)
	await settle()
	check("tablette ouverte", tablet.is_open() and tablet.visible)
	check_timer_over(tablet, "la tablette")
	var seen := {}
	var on_erupted := func() -> void:
		seen.tablet_hidden = not tablet.visible
		seen.warning_hidden = not level.get_node("Hud/Warning/Banner").visible
	state.erupted.connect(on_erupted, CONNECT_ONE_SHOT)
	state.time_left = 100.0
	state.penalize()
	await wait(10)
	check("eruption depuis la Plaine", state.has_erupted)
	check("tablette fermee avant la fin", seen.get("tablet_hidden", false))
	check("bandeau de mauvaise reponse ferme avant la fin", seen.get("warning_hidden", false))
	await _check_eruption_ending("depuis la Plaine")
	finish()


## Une seule fin perdue : le hub joue l'eruption du volcan (sa camera de cinematique), sans autre ecran de fin, puis
## le joueur revient au menu principal et la partie est effacee.
func _check_eruption_ending(where: String) -> void:
	level = current_scene
	var ending: Node = level.get_node_or_null("Ending")
	check("retour au hub pour la fin (%s)" % where, level != null and level.name == "Hub" and ending != null)
	if ending == null:
		return
	check("cinematique de l'eruption (%s)" % where, ending.get("_camera") != null and ending.get("_camera").current)
	check("aucun autre ecran de fin (%s)" % where, hud().get_node_or_null("%GameOver") == null and not hud().visible)
	# Le chronometre est sur sa propre couche : il suit le HUD cache.
	check("chronometre cache pendant la fin (%s)" % where, not hud().get_node("Clock").visible)
	check("jeu pas en pause pendant la fin (%s)" % where, not paused)
	check("pas de menu pause pendant la fin (%s)" % where, not root.get_node("PauseMenu").can_open())
	for i in 40:
		await create_timer(1.0).timeout
		if current_scene and current_scene.scene_file_path.ends_with("main_menu.tscn"):
			break
	check("menu principal apres la fin (%s)" % where, current_scene != null and current_scene.scene_file_path.ends_with("main_menu.tscn"))
	check("partie effacee (%s)" % where, not state.has_erupted and not state.intro_done and absf(state.time_left - state.TOTAL_TIME) < 0.01)
	var save: Dictionary = state.read_save(state.save_path())
	check("sauvegarde effacee (%s)" % where, save.is_empty() or (not save.has_erupted and not save.intro_done and save.books.is_empty()))


## Le chronometre reste visible au-dessus d'un panneau d'enigme ouvert (sa couche est plus haute), sans recouvrir le
## titre du panneau (plaque des cadres Ornate.Frame) ni aucun de ses boutons, croix de fermeture comprise.
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
