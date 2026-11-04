extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Livres fouillés : celui qui cachait un fragment disparaît du rayonnage et ne propose plus rien ; celui qui n'en
## cachait pas rentre dans le rang et ne propose plus rien non plus ; l'état tient si l'on sort et revient.
## Avec fenêtre, captures avant et après devant le rayonnage du registre des emprunts.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/books/"


func _initialize() -> void:
	_run.call_deferred()


func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")


## Le joueur regarde le livre (ou sa place vide) de face, à hauteur d'yeux.
func look_at_spot(spot: Vector3) -> void:
	var pivot: Node3D = player.get_node("CameraPivot")
	var eye := player.global_position + Vector3.UP * 1.65
	var offset := spot - eye
	pivot.rotation.y = atan2(-offset.x, -offset.z)
	pivot.rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())
	paused = false
	await wait(4)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	await walk_to(Vector3(0, 0, 10), "devant la bibliothèque")
	await use("Entrer")
	await wait(70)
	var registre: SearchableBook = level.get_node("Interior/Books/West03")
	var chroniques: SearchableBook = level.get_node("Interior/Books/West15")
	var spot := registre.global_position

	await walk_to(Vector3(-3.7, -40, spot.z), "devant le registre des emprunts")
	await look_at_spot(spot)
	check("avant : l'invite du livre s'affiche (%s)" % prompt(), prompt().contains("Examiner le livre"))
	await capture("avant_registre")
	await read("Examiner le livre")
	check("le fragment est trouvé", level.found_fragments().has(registre.fragment))
	check("le livre au fragment a disparu du rayonnage", not registre.visible)
	check("il n'est plus interactif", not registre.enabled)
	await look_at_spot(spot)
	check("plus aucune invite devant le rayonnage (%s)" % prompt(), prompt() == "")
	await capture("apres_registre")

	# Un livre sans fragment : il reste à sa place, rangé, et ne propose plus rien.
	await walk_path([Vector3(-4, -40, -10.5), Vector3(-4, -40, -13.5), Vector3(-3.7, -40, chroniques.global_position.z)],
		"vers les chroniques")
	await look_at_spot(chroniques.global_position)
	await capture("avant_chroniques")
	await read("Examiner le livre")
	check("le livre sans fragment n'en donne pas", not level.found_fragments().has(-1) and level.found_fragments().size() == 1)
	check("le livre sans fragment reste visible, rangé", chroniques.visible)
	check("il n'est plus interactif", not chroniques.enabled)
	await look_at_spot(chroniques.global_position)
	check("plus aucune invite devant son rayonnage (%s)" % prompt(), prompt() == "")
	await capture("apres_chroniques")

	# Sortir de la bibliothèque et y revenir : l'état tient.
	await walk_path([Vector3(-4, -40, -13.5), Vector3(-4, -40, -10.5), Vector3(-1.0, -40, -3.0), Vector3(0, -40, -1.8)],
		"vers la sortie")
	await use("Sortir")
	await wait(70)
	check("dehors", player.global_position.y > -10.0)
	await walk_to(Vector3(0, 0, 10), "devant la bibliothèque")
	await face(level.get_node("Exterior/EntryDoor").global_position)
	await use("Entrer")
	await wait(70)
	check("au retour, le registre a toujours disparu", not registre.visible and not registre.enabled)
	check("au retour, les chroniques restent rangées et muettes", chroniques.visible and not chroniques.enabled)
	await walk_to(Vector3(-3.7, -40, spot.z), "de nouveau devant le registre")
	await look_at_spot(spot)
	check("au retour, plus d'invite devant le rayonnage (%s)" % prompt(), prompt() == "")
	await capture("retour_registre")
	finish()
