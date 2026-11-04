extends "res://tests/scenes/common_test.gd"
## Marche dans tout le hub : chaque maison par sa porte, chaque chemin jusqu'au bout, le château jusqu'au trône.
## Argument : nombre de livres posés (0 = tout en ruine, 4 = tout reconstruit).


func _initialize() -> void:
	_run.call_deferred()


func place(x: float, z: float, look: Vector3) -> void:
	player.global_position = Vector3(x, level.get_node("Terrain").surface_height(x, z) + 0.4, z)
	player.velocity = Vector3.ZERO
	await wait(5)
	await face(look)


func _run() -> void:
	var books := int(OS.get_cmdline_user_args()[0])
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

	var houses: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/scenes/hub_houses.json"))
	for index in houses.size():
		var door: Array = houses[index].door
		var inside: Array = houses[index].inside
		await place(door[0], door[1], Vector3(inside[0], 1, inside[1]))
		await walk_to(Vector3(inside[0], 0, inside[1]), "maison %d : entree" % index, 300)
		await walk_to(Vector3(door[0], 0, door[1]), "maison %d : sortie" % index, 300)

	var roads := {"plaine": Vector2(-38, -38), "desert": Vector2(38, -38), "marais": Vector2(38, 38), "village": Vector2(-38, 38), "bunker": Vector2(72, 0)}
	for name: String in roads:
		var target: Vector2 = roads[name]
		var direction := target.normalized()
		var start := direction * 5.0
		var stop := target - direction * (5.0 if name != "bunker" else 0.0)
		await place(start.x, start.y, Vector3(stop.x, 1, stop.y))
		await walk_to(Vector3(stop.x, 0, stop.y), "chemin %s" % name, 1200)

	await place(0, -6, Vector3(0, 1, -50))
	await walk_path([Vector3(0, 0, -45), Vector3(0, 0, -56), Vector3(0, 0, -66), Vector3(0, 0, -76), Vector3(-1.5, 0, -82.0)], "vers le trone")
	for path in [[Vector3(-18, 0, -57)], [Vector3(18, 0, -57)], [Vector3(-18, 0, -66), Vector3(-18, 0, -88)], [Vector3(8, 0, -66)]]:
		await place(0, -62, path[0])
		await walk_path(path, "cour du chateau %s" % path[-1])
	# La vallée n'est plus un cercle : la limite se lit dans le terrain, à l'est (126 m) et à l'ouest (106 m).
	for angle: float in [0.0, PI]:
		var limit: float = HubTerrain.limit_radius(angle)
		var direction := Vector2.from_angle(angle)
		var start := direction * (limit - 8.0)
		await place(start.x, start.y, Vector3(direction.x * 200.0, 1, direction.y * 200.0))
		await walk_to(Vector3(direction.x * (limit + 20.0), 0, direction.y * (limit + 20.0)), "limite infranchissable (doit echouer)", 300)
		check("le joueur reste dans le hub (%.1f / %.0f)" % [Vector2(player.global_position.x, player.global_position.z).length(), limit],
			Vector2(player.global_position.x, player.global_position.z).length() < limit + 1.0)
	finish()
