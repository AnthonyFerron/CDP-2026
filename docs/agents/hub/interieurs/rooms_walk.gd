extends "res://tests/scenes/common_test.gd"
## Entrer et sortir de chaque bâtiment du hub à pied : du dehors de la porte jusqu'au milieu de l'entrée, puis
## retour dehors. Argument : nombre de livres posés. Fichier des portes : une ligne « nom xd,zd xi,zi ».

func _initialize() -> void:
	_run.call_deferred()


func place(x: float, z: float, look: Vector3) -> void:
	player.global_position = Vector3(x, level.get_node("Terrain").surface_height(x, z) + 0.4, z)
	player.velocity = Vector3.ZERO
	await wait(5)
	await face(look)


func _run() -> void:
	var args := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			args.append(a)
	var books := int(args[0])
	state = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	var all: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]
	for index in books:
		state.books.append(all[index])
		state.placed_books.append(all[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await wait(60)
	level = current_scene
	player = level.get_node("Player")
	for line in FileAccess.get_file_as_string(args[1]).split("\n", false):
		var f := line.split(" ", false)
		if f.size() < 3:
			continue
		if f[0] == "lire":
			# Texte à lire : debout sur une case atteinte, tourné vers lui, E ouvre le lecteur.
			if books < 4:
				continue
			var at := f[2].split(",")
			var text := f[3].split(",")
			var title := " ".join(f.slice(4))
			await place(float(at[0]), float(at[1]), Vector3(float(text[0]), float(text[1]), float(text[2])))
			await face(Vector3(float(text[0]), float(text[1]), float(text[2])))
			check("%s : invite « %s »" % [f[1], prompt()], prompt().contains(title))
			await press("interact")
			check("%s : lecteur ouvert sur « %s »" % [f[1], hud().get_node("%ReaderTitle").text],
				hud().get_node("%Reader").visible and hud().get_node("%ReaderTitle").text == title)
			await press("interact")
			continue
		var door := f[1].split(",")
		var inside := f[2].split(",")
		var dx := float(door[0])
		var dz := float(door[1])
		var ix := float(inside[0])
		var iz := float(inside[1])
		if f.size() > 3 and f[3] == "porte":
			# Porte fermée : on la passe avec E, dans un sens puis dans l'autre.
			await place(dx, dz, Vector3(ix, 1.2, iz))
			await use("Entrer")
			await wait(150)
			check("%s : entree par la porte (%s)" % [f[0], player.global_position.snappedf(0.1)],
				Vector2(player.global_position.x - ix, player.global_position.z - iz).length() < 1.5)
			await face(Vector3(dx, 1.2, dz))
			await use("Sortir")
			await wait(150)
			check("%s : sortie par la porte (%s)" % [f[0], player.global_position.snappedf(0.1)],
				Vector2(player.global_position.x - dx, player.global_position.z - dz).length() < 1.5)
			continue
		await place(dx, dz, Vector3(ix, 1, iz))
		await walk_to(Vector3(ix, 0, iz), "%s : entree" % f[0], 400)
		await walk_to(Vector3(dx, 0, dz), "%s : sortie" % f[0], 400)
	finish()
