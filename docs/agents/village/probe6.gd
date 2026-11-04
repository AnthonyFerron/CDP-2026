extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Ce qui est dessiné autour d'un point : -- x y z [rayon]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := Array(OS.get_cmdline_user_args()).filter(func(arg: String) -> bool: return not arg.begins_with("--"))
	var point := Vector3(float(args[0]), float(args[1]), float(args[2]))
	var radius := float(args[3]) if args.size() > 3 else 1.5
	await start_level("res://scenes/levels/village/village.tscn")
	for i in 5:
		await process_frame
	var probe := AABB(point - Vector3.ONE * radius, Vector3.ONE * radius * 2.0)
	_walk(level, probe)
	finish()

func _walk(node: Node, probe: AABB) -> void:
	if node is MeshInstance3D and node.mesh:
		var box: AABB = node.global_transform * node.mesh.get_aabb()
		if box.intersects(probe):
			print("mesh ", node.get_path(), " ", box)
	elif node is MultiMeshInstance3D and node.multimesh and node.multimesh.mesh:
		var mm: MultiMesh = node.multimesh
		for i in mm.instance_count:
			var box: AABB = node.global_transform * mm.get_instance_transform(i) * mm.mesh.get_aabb()
			if box.intersects(probe):
				print("multimesh ", node.get_path(), " #", i, " ", box, " ", mm.mesh.resource_path, " ", mm.mesh.resource_name, " ", mm.get_instance_transform(i), " surf ", [mm.mesh.surface_get_material(0).resource_name if mm.mesh.surface_get_material(0) else ""])
	for child in node.get_children():
		_walk(child, probe)
