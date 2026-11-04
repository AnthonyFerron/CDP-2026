extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_audit_test.gd"
## Affiche la grille de la cave : # bloqué, . libre, o accessible. Indique ce qui bloque une rangée.


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	space = player.get_world_3d().direct_space_state
	terrain = level.get_node("Exterior/Terrain")
	player_rid = player.get_rid()
	capsule.radius = 0.36
	capsule.height = 1.7
	set_inside(true)
	await wait(5)
	build_reach(level.get_node("Interior/InsideSpawn").global_position, true)
	for j in range(36, -1, -1):
		var line := ""
		for i in 45:
			var x := -11.0 + i * CELL
			var z := -13.0 + j * CELL
			if reach.has(Vector2i(i, j)):
				line += "o"
			elif is_nan(floor_at(x, z, true)):
				line += "#"
			else:
				line += "."
		print("GRID %6.1f %s" % [-13.0 + j * CELL, line])
	for z in [-3.0, -4.0]:
		var hit_floor := ray(Vector3(-2.0, -39.55, z), Vector3(-2.0, -40.6, z), [player_rid])
		print("BLOQUE sol en (-2, %.1f) : %s" % [z, hit_floor])
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis(), Vector3(-2.0, -40.0 + 1.03, z))
		query.exclude = [player_rid]
		for hit in space.intersect_shape(query, 4):
			print("BLOQUE en z %.1f : %s / %s" % [z, hit.collider.get_path(), hit.shape])
	finish()
