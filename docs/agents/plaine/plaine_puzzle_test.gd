extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Plaine (copie adaptée : un livre fouillé n'est plus interactif) : fouille des livres, tablette de la conversation, mauvais ordre puis bon ordre, livre et retour.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	check("premiere personne", player.first_person)
	check("chronometre plein", absf(state.time_left - state.TOTAL_TIME) < 2.0)
	await walk_to(Vector3(0, 0, 10), "devant la bibliotheque")
	await use("Entrer")
	await wait(70)
	check("dans la bibliotheque", player.global_position.y < -30)

	# Un livre fouille a la main, les autres directement.
	await walk_to(Vector3(-3.8, -40, -3), "devant le registre des emprunts")
	await face(level.get_node("Interior/Books/West03").global_position)
	await read("Examiner le livre")
	check("premier fragment trouve", level.found_fragments().size() == 1)
	check("livre au fragment pris : plus visible ni interactif", not level.get_node("Interior/Books/West03").visible and not level.get_node("Interior/Books/West03").enabled)
	var plain_book: Node = level.get_node("Interior/Books/West15")
	plain_book.interact()
	await press("interact")
	check("un livre sans fragment n'en donne pas", level.found_fragments().size() == 1)
	for book in level.get_node("Interior/Books").get_children():
		if book.fragment >= 0 and not level.found_fragments().has(book.fragment):
			book.interact()
			await press("interact")
	check("six fragments trouves", level.found_fragments().size() == 6)

	await walk_path([Vector3(-4, -40, -10.5), Vector3(-4, -40, -13.5), Vector3(0, -40, -16.5),
		Vector3(4, -40, -22.5), Vector3(4, -40, -25.5), Vector3(0, -40, -31.2)], "vers la tablette")
	await use("tablette")
	var puzzle: Node = level.get_node("TabletPuzzle")
	check("tablette ouverte", puzzle.is_open())
	check("valider desactive tant que la tablette est incomplete", puzzle.get_node("%Validate").disabled)

	var before: float = state.time_left
	var wrong := [1, 0, 2, 3, 4, 5]
	for slot in 6:
		puzzle.place(wrong[slot], slot)
	await wait(2)
	check("valider actif une fois les six emplacements remplis", not puzzle.get_node("%Validate").disabled)
	puzzle.get_node("%Validate").pressed.emit()
	await wait(5)
	check("mauvais ordre : penalite de 5 minutes (%.0f s)" % (before - state.time_left), before - state.time_left >= 299.0)
	check("mauvais ordre : la tablette reste ouverte", puzzle.is_open())
	check("message d'echec : " + puzzle.get_node("%Feedback").text, puzzle.get_node("%Feedback").text.contains("rouge"))

	for slot in 6:
		puzzle.place(slot, slot)
	puzzle.get_node("%Validate").pressed.emit()
	await wait(5)
	check("bon ordre : tablette fermee", not puzzle.is_open())
	await wait(180)
	check("la dalle a glisse", level.get_node("Interior/Stone").position.x < -3.0)
	await walk_path([Vector3(2.2, -40, -31.5), Vector3(2.2, -40, -34.8), Vector3(0, -40, -35.0), Vector3(0, -40, -37.2)], "vers le livre")
	await use("Projenomicon")
	check("Projenomicon enregistre", state.has_book(&"projenomicon"))
	check("portail rouvert", level.get_node("Exterior/Portal").is_open)
	finish()
