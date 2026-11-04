extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/grid_test.gd"
## Sonde : à quelques cases signalées « mur invisible », ce que voient la couche visuelle et la couche solide.


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	space = level.get_world_3d().direct_space_state
	level.get_node("Interior").visible = true
	level.get_node("Exterior").visible = true
	_build_visual_layer()
	await wait(4)
	for cell in [Vector3(-28.0, 0.22, 9.0), Vector3(-28.0, -0.05, 4.5), Vector3(-32.0, 0.65, 29.0)]:
		print("case ", cell)
		for hit in _capsule(cell.x, cell.y + 0.15, cell.z, 0.4, 1.8, SOLID):
			var part: Node3D = hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
			print("  solide : ", level.get_path_to(part), " ", part.global_position)
			if part is CollisionShape3D and (part as CollisionShape3D).shape is ConvexPolygonShape3D:
				var points: PackedVector3Array = ((part as CollisionShape3D).shape as ConvexPolygonShape3D).points
				var box := AABB(part.global_transform * points[0], Vector3.ZERO)
				for p in points:
					box = box.expand(part.global_transform * p)
				print("    enveloppe : ", box)
		for radius in [0.9, 1.5, 3.0]:
			var shape := BoxShape3D.new()
			shape.size = Vector3(radius * 2, 2.5, radius * 2)
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.transform = Transform3D(Basis(), cell + Vector3(0, 1.0, 0))
			query.collision_mask = VISUAL_LAYER
			var names := []
			for hit in space.intersect_shape(query, 32):
				var owner_node: Node = hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
				var source: String = owner_node.get_meta("source", "?")
				if "Terrain" in source:
					continue
				names.append("%s@%s" % [source.get_file(), (owner_node as Node3D).global_position.snappedf(0.01)])
			print("  visuel, boîte de ±%.1f m : %s" % [radius, names])
	# Instances des MultiMesh de rochers proches des cases.
	for node in level.find_children("*Rocks*", "MultiMeshInstance3D", true, false):
		var multi := (node as MultiMeshInstance3D).multimesh
		for index in multi.instance_count:
			var at: Transform3D = (node as Node3D).global_transform * multi.get_instance_transform(index)
			for spot in [Vector2(-28.1, 8.52), Vector2(-28.04, 3.86)]:
				if Vector2(at.origin.x, at.origin.z).distance_to(spot) < 1.5:
					print("instance ", node.name, " ", at.origin, " aabb ", at * multi.mesh.get_aabb())
	finish()
