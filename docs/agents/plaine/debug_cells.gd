extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Diagnostic : sol et obstacles en quelques points du passage derrière la dalle.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	var stone: Node3D = level.get_node("Interior/Stone")
	stone.position.x -= 3.4
	await wait(4)
	print("pierre : ", stone.global_position)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	for z in [-35.2, -35.5, -35.8, -36.1, -36.4, -36.7, -37.0, -37.6, -38.2, -38.8, -39.2]:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(0, -37.8, z), Vector3(0, -42.5, z))
		var hit: Dictionary = space.intersect_ray(ray)
		var ground: float = hit.position.y if hit else NAN
		var line := "z %.1f sol %s (%s)" % [z, ground, hit.collider.name if hit else "-"]
		if hit:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis(), Vector3(0, ground + 1.05, z))
			query.exclude = [player.get_rid()]
			for other in space.intersect_shape(query, 4):
				line += " | gêne : %s/%s forme %d" % [other.collider.get_parent().name, other.collider.name, other.shape]
		print(line)
	finish()
