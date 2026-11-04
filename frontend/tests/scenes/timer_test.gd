extends "res://tests/scenes/common_test.gd"
## Chronometre du volcan : il s'ecoule, une penalite retire 5 minutes, puis l'eruption termine la partie.


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
	check("chronometre au rouge sous 5 minutes", timer.modulate.r > 0.9 and timer.modulate.g < 0.5)
	state.time_left = 0.05
	await wait(10)
	check("eruption", state.has_erupted)
	check("ecran de fin affiche", hud().get_node("%GameOver").visible)
	check("jeu en pause", paused)
	hud().get_node("%Restart").pressed.emit()
	await wait(60)
	check("partie recommencee", not state.has_erupted and absf(state.time_left - state.TOTAL_TIME) < 2.0 and not paused)
	check("retour au hub", current_scene != null and current_scene.name == "Hub")
	level = current_scene
	finish()
