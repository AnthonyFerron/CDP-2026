extends "res://tests/scenes/common_test.gd"
## Marais : descente dans la crypte, inscription, mecanisme aux cinq cercles, tombeau et Logiconomicon.


func _initialize() -> void:
	_run.call_deferred()


func set_word(puzzle: Node, mechanism: Node, word: String) -> void:
	for ring in 5:
		var target: int = mechanism.LETTERS.find(word[ring])
		while mechanism.letters[ring] != target:
			puzzle.turn(ring, 1)
	await wait(20)


func _run() -> void:
	await start_level("res://scenes/levels/marais/marais.tscn")
	check("premiere personne", player.first_person)
	await walk_path([Vector3(-3, 0, 48), Vector3(-18, 0, 27), Vector3(-16, 0, 19), Vector3(6, 0, 4), Vector3(8.4, 0, 2.0),
		Vector3(8.4, 0, -8.0), Vector3(8.5, 0, -10.0), Vector3(3, 0, -28), Vector3(0, 0, -34.6)], "vers la crypte")
	await face(Vector3(0, 1.4, -36))
	await use("Descendre")
	await wait(150)
	check("dans la crypte (%.1f)" % player.global_position.y, player.global_position.y < -30)
	check("pas de vase sous terre", player.global_position.y < -30 and level.get_node("Hud").get_node("%Message").text.contains("crypte"))

	await walk_to(Vector3(0, -40, -1.0), "dans le couloir")
	await walk_to(Vector3(-2.5, -40, -17.5), "vers l'inscription")
	await face(Vector3(0, -38.4, -21))
	await read("inscription")
	await walk_to(Vector3(0, -40, -7.0), "devant le mecanisme")
	await face(Vector3(0, -40, -12))
	await use("mécanisme")
	var puzzle: Node = level.get_node("RingPuzzle")
	var mechanism: Node = level.mechanism()
	check("vue rapprochee", level.get_node("Interior/MechanismCamera").current and puzzle.is_open())

	var before: float = state.time_left
	await set_word(puzzle, mechanism, "CODIA")
	check("cercles sur CODIA : " + mechanism.code(), mechanism.code() == "CODIA")
	puzzle.get_node("%Validate").pressed.emit()
	await wait(5)
	check("CODIA tel quel refuse : penalite (%.0f s)" % (before - state.time_left), before - state.time_left >= 299.0)
	check("les cercles gardent leur position", mechanism.code() == "CODIA" and puzzle.is_open())
	await set_word(puzzle, mechanism, "FLGFD")
	puzzle.get_node("%Validate").pressed.emit()
	await wait(5)
	check("FLGFD accepte", not puzzle.is_open())
	check("retour a la vue du joueur", level.get_node("Player/CameraPivot/SpringArm3D/Camera3D").current)
	await wait(170)
	check("le tombeau s'est ouvert", level.get_node("Interior/Tomb/Lid").position.x > 1.5)
	check("le livre est visible", level.get_node("Interior/Tomb/Book").visible)

	await walk_path([Vector3(6, -40, -12), Vector3(12, -40, -12), Vector3(18, -40, -12), Vector3(21.4, -40, -12)], "vers le tombeau")
	await face(level.get_node("Interior/Tomb/Book").global_position)
	await use("Logiconomicon")
	check("Logiconomicon enregistre", state.has_book(&"logiconomicon"))
	await walk_path([Vector3(12, -40, -12), Vector3(6, -40, -12), Vector3(0, -40, -4), Vector3(0, -40, 0.8)], "vers la sortie")
	await face(Vector3(0, -38.8, 2.4))
	await use("Remonter")
	await wait(80)
	check("revenu a la surface", player.global_position.y > -2)
	check("portail rouvert", level.get_node("Portal").is_open)
	finish()
