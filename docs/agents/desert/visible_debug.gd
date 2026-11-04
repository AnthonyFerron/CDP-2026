extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_grid_test.gd"


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	terrain = level.get_node("Exterior/Terrain")
	set_inside(true)
	await wait(5)
	_collect_visuals(level)
	_build_hash()
	var point := Vector3(-2.65, -38.95, -1.3)
	var key := Vector2i(floori(point.x / HASH), floori(point.z / HASH))
	print("DBG entrées %d" % _mesh_hash.get(key, []).size())
	for entry: Array in _mesh_hash.get(key, []):
		var node: GeometryInstance3D = entry[0]
		var xform: Transform3D
		var local_box: AABB
		if entry[1] < 0:
			xform = node.global_transform
			local_box = (node as MeshInstance3D).get_aabb()
		else:
			xform = node.global_transform * (node as MultiMeshInstance3D).multimesh.get_instance_transform(entry[1])
			local_box = (node as MultiMeshInstance3D).multimesh.mesh.get_aabb()
		var box := xform * local_box
		if box.grow(0.5).has_point(point):
			print("DBG proche %s[%d] boîte %s visible %s" % [node.name, entry[1], box, node.is_visible_in_tree()])
	print("DBG visible 0,5 : %s" % _visible_near(point, 0.5))
	var shapes := level.get_node("Interior/Cellar/Shapes")
	print("DBG formes de la cave : %d enfants" % shapes.get_child_count())
	for child in shapes.get_children():
		print("DBG enfant %s %s" % [child.name, child.get_class()])
		if child is MultiMeshInstance3D and child.multimesh.instance_count == 4:
			print("DBG 4 instances : %s / %s" % [child.multimesh.get_instance_transform(0), child.global_transform])
		if child is MultiMeshInstance3D:
			for index in child.multimesh.instance_count:
				var box: AABB = child.global_transform * child.multimesh.get_instance_transform(index) * child.multimesh.mesh.get_aabb()
				if box.grow(0.5).has_point(point):
					print("DBG multimesh %s[%d] %s dans la liste %s" % [child.name, index, box, multimeshes.has(child)])
	finish()
