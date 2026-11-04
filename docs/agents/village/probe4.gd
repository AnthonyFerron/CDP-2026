extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await start_level("res://scenes/levels/village/village.tscn")
	for spot in [Vector3(0, 0.1, -44), Vector3(-36, 0.1, -36), Vector3(0, 0.1, 30)]:
		var ray := PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 20, spot + Vector3.DOWN * 20)
		ray.exclude = [player.get_rid()]
		var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
		var foot: Vector3 = hit.position
		player.global_position = foot + Vector3.UP * 0.05
		player.velocity = Vector3.ZERO
		player.get_node("CameraPivot").rotation.y = 0.0
		await physics_frame
		var start := player.global_position
		Input.action_press("move_forward")
		for frame in 30:
			await physics_frame
		Input.action_release("move_forward")
		print("%s sol %s -> %s (sur le sol : %s, mode %s, collider %s)" % [spot, foot.snappedf(0.01), player.global_position.snappedf(0.01), player.is_on_floor(), player.process_mode, hit.collider.name])
	finish()
