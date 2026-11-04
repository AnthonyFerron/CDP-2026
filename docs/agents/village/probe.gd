extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	await start_level("res://scenes/levels/village/village.tscn")
	var space := player.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	for z in [-3.5, -4.0, -4.5, -5.0]:
		for x in [5.5, 6.0, 6.5]:
			var ray := PhysicsRayQueryParameters3D.create(Vector3(x, -35.0, z), Vector3(x, -37.0, z))
			var hit := space.intersect_ray(ray)
			var y: float = hit.position.y if hit else NAN
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x, y + 1.02, z))
			query.exclude = [player.get_rid()]
			var hits := space.intersect_shape(query, 8)
			var names := []
			for h in hits:
				var owner_id = h.collider.shape_find_owner(h.shape)
				var shape_owner = h.collider.shape_owner_get_owner(owner_id)
				names.append("%s/%s %s" % [h.collider.name, shape_owner.name, shape_owner.global_position])
			print("x %.1f z %.1f sol %.2f normal %s : %s" % [x, z, y, hit.normal if hit else Vector3.ZERO, names])
	finish()
