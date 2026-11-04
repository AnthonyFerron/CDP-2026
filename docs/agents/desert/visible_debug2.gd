extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_grid_test.gd"


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	terrain = level.get_node("Exterior/Terrain")
	await wait(5)
	_collect_visuals(level)
	_build_hash()
	for point: Vector3 in [Vector3(-16.5, 1.1, 16.1), Vector3(-15.1, 1.15, 14.5)]:
		var key := Vector2i(floori(point.x / HASH), floori(point.z / HASH))
		var near := 0
		for entry: Array in _mesh_hash.get(key, []):
			var node: GeometryInstance3D = entry[0]
			var xform: Transform3D = node.global_transform
			var local_box: AABB
			if entry[1] < 0:
				local_box = (node as MeshInstance3D).get_aabb()
			else:
				xform = xform * (node as MultiMeshInstance3D).multimesh.get_instance_transform(entry[1])
				local_box = (node as MultiMeshInstance3D).multimesh.mesh.get_aabb()
			if (xform * local_box).grow(0.5).has_point(point):
				near += 1
				var shape := tri((node as MeshInstance3D).mesh if entry[1] < 0 else (node as MultiMeshInstance3D).multimesh.mesh)
				var inverse := xform.affine_inverse()
				var hit := shape.intersect_segment(inverse * (point + Vector3(-1, 0, 0)), inverse * (point + Vector3(1, 0, 0)))
				var hit2 := shape.intersect_segment(inverse * (point + Vector3(0, 0, -1)), inverse * (point + Vector3(0, 0, 1)))
				print("DBG %s : %s[%d] %s rayon x %s rayon z %s" % [point, node.get_path(), entry[1], node.get_class(), hit, hit2])
		print("DBG %s : %d candidats, visible %s" % [point, near, _visible_near(point, 0.5)])
	for mesh: MeshInstance3D in level.get_node("Exterior/Ruins").find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		if box.grow(1.0).has_point(Vector3(-15, 1.1, 16)):
			var faces := mesh.mesh.get_faces()
			var arrays := mesh.mesh.surface_get_arrays(0)
			var span := AABB()
			for i in faces.size():
				span = AABB(faces[i], Vector3.ZERO) if i == 0 else span.expand(faces[i])
			print("DBG maillage %s det %.2f boîte %s surfaces %d sommets %d faces %d étendue des faces %s" % [mesh.get_path(), mesh.global_transform.basis.determinant(), box, mesh.mesh.get_surface_count(), (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), faces.size() / 3, span])
	finish()
