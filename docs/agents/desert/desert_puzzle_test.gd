extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Desert (copie de l'agent du Desert : le coffre de pierre est passe dans le coin nord-est de la cave) : runes ramassees et degagees du sable, table ronde, mauvaise puis bonne reponse, coffre et livre.


func _initialize() -> void:
	_run.call_deferred()


func rune(name: String) -> Node3D:
	return level.get_node("Runes/" + name)


func pile(name: String) -> Node3D:
	return level.get_node("SandPiles/" + name)


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	check("premiere personne", player.first_person)
	check("rune cachee invisible au depart", not rune("Puiser").visible)

	await walk_path([Vector3(0, 0, 40), Vector3(0, 0, 19), Vector3(0, 0, 12), Vector3(8.4, 0, 9.4)], "vers une rune")
	await face(rune("Porter").global_position)
	await use("Ramasser la rune")
	check("rune ramassee", &"porter" in level.inventory() and not rune("Porter").visible)

	# Tas de sable a degager en maintenant E : la progression est gardee si on relache.
	await walk_to(Vector3(-7.3, 0, -1.0), "devant un tas de sable")
	await face(pile("PileWest").global_position)
	check("invite du tas : " + prompt(), prompt().contains("Maintenir"))
	await hold("interact", 50)
	var partial: float = pile("PileWest").progress
	check("balayage partiel garde (%.2f)" % partial, partial > 0.2 and partial < 1.0)
	await hold("interact", 120)
	check("tas degage", pile("PileWest").is_cleared)
	check("la rune affleure", rune("Puiser").visible)
	await wait(5)
	await use("Ramasser la rune")
	check("rune du sable ramassee", &"puiser" in level.inventory())
	await walk_to(Vector3(-4, 0, 6.4), "devant un tas vide")
	await face(pile("PileGate").global_position)
	await hold("interact", 150)
	check("tas vide degage sans rune", pile("PileGate").is_cleared and message().contains("Rien"))
	rune("TantQue").interact()
	rune("Pour").interact()
	await wait(3)

	await walk_to(Vector3(0, 0, -3.8), "devant la trappe")
	await face(Vector3(0, 0, -6))
	await use("trappe")
	await wait(80)
	check("dans la cave", player.global_position.y < -30)
	await walk_to(Vector3(-7.0, -40, -4.0), "devant la table de la cave")
	await face(rune("Si").global_position)
	await use("Ramasser la rune")
	for name in ["PileCaveWest", "PileCaveEast"]:
		pile(name).progress = 0.99
		pile(name).focused = true
	Input.action_press("interact")
	await wait(10)
	Input.action_release("interact")
	for name in ["Ouvrir", "Sinon", "Fermer"]:
		check("rune %s disponible" % name, rune(name).enabled)
		rune(name).interact()
	await wait(3)
	check("huit runes ramassees (%d)" % level.inventory().size(), level.inventory().size() == 8)

	await walk_to(Vector3(0, -40, -3.6), "devant la table ronde")
	await face(Vector3(0, -39, -6))
	await use("table ronde")
	var puzzle: Node = level.get_node("RunePuzzle")
	check("table ouverte", puzzle.is_open())
	check("valider desactive tant que les algorithmes sont incomplets", puzzle.get_node("%Validate").disabled)
	var before: float = state.time_left
	var wrong: Array[StringName] = [&"pour", &"puiser", &"porter", &"si", &"ouvrir", &"sinon"]
	for slot in 6:
		puzzle.place(wrong[slot], slot)
	puzzle.get_node("%Validate").pressed.emit()
	await wait(5)
	check("mauvaise reponse : penalite (%.0f s)" % (before - state.time_left), before - state.time_left >= 299.0)
	check("mauvaise reponse : table encore ouverte", puzzle.is_open())
	for slot in 6:
		puzzle.place(puzzle.SOLUTION[slot], slot)
	puzzle.get_node("%Validate").pressed.emit()
	await wait(5)
	check("bonne reponse : table fermee", not puzzle.is_open())
	await wait(260)
	check("le coffre est apparu", level.get_node("Interior/Chest").visible)
	check("le livre est sorti du coffre", level.get_node("Interior/Book").visible)
	await walk_to(Vector3(5.9, -40, -8.3), "devant le coffre, dans le coin nord-est")
	await face(level.get_node("Interior/Book").global_position)
	await use("Algonicon")
	check("Algonicon enregistre", state.has_book(&"algonicon"))
	finish()
