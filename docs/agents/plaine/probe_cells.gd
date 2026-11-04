extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/grid_test.gd"
## Sonde : de la dalle à la petite salle, sur l'axe x = 0, ce que la grille voit en chaque case.


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	space = level.get_world_3d().direct_space_state
	var stone: Node3D = level.get_node("Interior/Stone")
	stone.position.x -= level.stone_travel
	await wait(4)
	for k in 26:
		var z := -35.0 - k * 0.25
		var hit := _ground(0.0, z, -36.3, -42.5)
		if hit.is_empty():
			print("z %.2f : pas de sol" % z)
			continue
		var y: float = hit.position.y
		var names := []
		for blocker in _capsule(0.0, y + 0.15, z, 0.4, 1.8, SOLID):
			var body: CollisionObject3D = blocker.collider
			var part: Node = body.shape_owner_get_owner(body.shape_find_owner(blocker.shape))
			names.append("%s %s" % [level.get_path_to(part), (part as Node3D).global_position.snappedf(0.01)])
		print("z %.2f : sol %.2f (%s) normale %.2f, gêne : %s" % [z, y, level.get_path_to(hit.collider), hit.normal.y, names])
	finish()
