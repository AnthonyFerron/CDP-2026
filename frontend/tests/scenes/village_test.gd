extends "res://tests/scenes/common_test.gd"
## Village : la grande rue jusqu'a la mairie, fouille des deux niveaux, carnet, dispositif des cinq codes,
## bibliotheque qui glisse, Codonomicon, puis retour au hub par le portail.


func _initialize() -> void:
	_run.call_deferred()


func fragment(number: int) -> Node3D:
	return level.get_node("Interior/Fragments/Fragment%d" % number)


func inside(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y - 40.0, z)


func _run() -> void:
	await start_level("res://scenes/levels/village/village.tscn")
	check("premiere personne", player.first_person)
	check("portail eteint sans le livre", not level.get_node("Portal").is_open)
	await walk_path([Vector3(0, 0, 46), Vector3(0, 0, 30), Vector3(0, 0, 8), Vector3(4.5, 0, 2), Vector3(4.5, 0, -12),
		Vector3(0, 0, -17.5)], "vers la mairie")
	await face(Vector3(0, 1.4, -21))
	await use("Entrer dans la mairie")
	await wait(80)
	check("dans la mairie (%.1f)" % player.global_position.y, player.global_position.y < -30)

	# Rez-de-chaussee : un fragment sur le comptoir, un autre dans le tiroir de l'accueil.
	await walk_to(inside(-2.4, 0, 1.0), "devant le comptoir")
	await face(fragment(0).global_position)
	await use("Ramasser le fragment")
	check("premier fragment", level.found_fragments().size() == 1 and not fragment(0).visible)
	await walk_to(inside(0.4, 0, 0.9), "devant le tiroir de l'accueil")
	await face(level.get_node("Interior/Storages/ReceptionDrawer").global_position)
	await use("Ouvrir le tiroir de l'accueil")
	check("le tiroir revele un fragment", fragment(3).visible and message().contains("fragment"))
	await wait(3)
	await face(fragment(3).global_position)
	await use("Ramasser le fragment")
	check("deuxieme fragment", level.found_fragments().size() == 2)
	level.get_node("Interior/Storages/Dresser").interact()
	await wait(3)
	check("meuble vide", message().contains("poussière"))

	# Carnet des fragments, avec la touche I.
	await press("inventory")
	check("carnet ouvert", level.get_node("PaperNotebook").is_open() and level.get_node("PaperNotebook/%Title").text.contains("2 / 10"))
	await press("inventory")
	check("carnet ferme", not level.get_node("PaperNotebook").is_open() and player.process_mode == Node.PROCESS_MODE_INHERIT)

	# Les autres fragments, sans refaire chaque trajet.
	for storage in level.get_node("Interior/Storages").get_children():
		if not storage.is_open:
			storage.interact()
	for item in level.get_node("Interior/Fragments").get_children():
		if not item.collected:
			check("fragment %d accessible" % item.fragment, item.visible and item.enabled)
			item.interact()
	await wait(3)
	check("dix fragments", level.found_fragments().size() == 10)

	# L'escalier, a pied, jusqu'au bureau du maire.
	await walk_path([inside(4.0, 0, 5.4), inside(6.0, 0, 5.4), inside(6.0, 0, 0), inside(6.0, 4.5, -5.0), inside(2.0, 4.5, -5.0)], "escalier")
	check("a l'etage (%.1f)" % player.global_position.y, player.global_position.y > -36.0)
	await walk_to(inside(-1.0, 4.5, -3.6), "devant le dispositif")
	await face(inside(-1.0, 5.7, -5.4))
	await use("dispositif")
	var puzzle: Node = level.get_node("CodePuzzle")
	check("dispositif ouvert", puzzle.is_open())
	check("codes suivants scelles", puzzle.is_unlocked(0) and not puzzle.is_unlocked(1))

	var before: float = state.time_left
	puzzle.get_node("%Answer").text = "4"
	puzzle.get_node("%Validate").pressed.emit()
	await wait(5)
	check("mauvaise reponse : penalite (%.0f s)" % (before - state.time_left), before - state.time_left >= 299.0)
	check("mauvaise reponse : section rouge", (level.get_node("Interior/Device/Sections/Section0").get_active_material(0) as StandardMaterial3D).emission.r > 0.9)
	var answers := ["3", "Green", "10", " 2 ", "12"]
	for index in 5:
		puzzle.select(index)
		puzzle.get_node("%Answer").text = answers[index]
		puzzle.get_node("%Validate").pressed.emit()
		await wait(3)
		check("code %d resolu" % (index + 1), puzzle.solved[index])
		if index < 4:
			check("section %d verte" % (index + 1), (level.get_node("Interior/Device/Sections/Section%d" % index).get_active_material(0) as StandardMaterial3D).emission.g > 0.9)
	check("dispositif ferme", not puzzle.is_open())
	await wait(220)
	check("la bibliotheque a glisse", level.get_node("Interior/SecretShelf").position.z > 3.0)

	await walk_path([inside(-5.0, 4.5, -0.3), inside(-8.0, 4.5, 0), inside(-10.6, 4.5, 0)], "vers la salle secrete")
	await face(level.get_node("Interior/Book").global_position)
	await use("Codonomicon")
	check("Codonomicon enregistre", state.has_book(&"codonomicon") and level.get_node("Portal").is_open)

	await walk_path([inside(-5.0, 4.5, 0), inside(2.0, 4.5, -5.0), inside(6.0, 4.5, -5.0), inside(6.0, 0, 4.6),
		inside(-2.0, 0, 4.4)], "redescend")
	check("au rez-de-chaussee (%.1f)" % player.global_position.y, player.global_position.y < -39.0)
	await face(inside(-2.0, 1.2, 6.0))
	await use("Sortir")
	await wait(80)
	check("dehors", player.global_position.y > -2)
	await walk_path([Vector3(4.5, 0, -12), Vector3(4.5, 0, 2), Vector3(0, 0, 8), Vector3(0, 0, 38), Vector3(0, 0, 56)], "vers le portail")
	await walk_to(Vector3(0, 0, 66), "a travers le portail", 300)
	await wait(40)
	check("retour au hub", current_scene != null and current_scene.name == "Hub")
	level = current_scene
	finish()
