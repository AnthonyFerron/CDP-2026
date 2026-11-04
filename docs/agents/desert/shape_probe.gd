extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_grid_test.gd"
## Formes de collision signalées par la grille : leur boîte, et les maillages visibles dont la boîte est proche du contact.

const PROBES := [
	[41, Vector3(-4.0, 1.2, -17.1)], [42, Vector3(6.0, 1.4, -17.9)], [89, Vector3(-29.25, 1.15, -29.0)],
	[88, Vector3(-38.55, 1.2, -21.7)], [97, Vector3(-40.0, 1.1, -32.8)], [97, Vector3(-43.05, 1.1, -35.45)],
	[134, Vector3(23.25, 1.15, -44.8)],
]


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	terrain = level.get_node("Exterior/Terrain")
	await wait(5)
	_collect_visuals(level)
	_build_hash()
	var body: StaticBody3D = level.get_node("Exterior/Ruins/Collision")
	for probe: Array in PROBES:
		var index: int = probe[0]
		var point: Vector3 = probe[1]
		var owner_id := body.shape_find_owner(index)
		var holder := body.shape_owner_get_owner(owner_id) as CollisionShape3D
		var shape := holder.shape
		var size := ""
		if shape is BoxShape3D:
			size = "boîte %s" % (shape as BoxShape3D).size
		elif shape is CylinderShape3D:
			size = "cylindre r %.2f h %.2f" % [(shape as CylinderShape3D).radius, (shape as CylinderShape3D).height]
		else:
			size = shape.get_class()
		print("SONDE forme %d (%s) en %s, base %s : %s ; visible 0,5 %s, 1 %s" % [index, holder.name, holder.global_position.snappedf(0.01),
			holder.global_basis.get_euler().snappedf(0.01), size, _visible_near(point, 0.5), _visible_near(point, 1.0)])
		for mesh in meshes:
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			if box.grow(1.2).has_point(point):
				print("    maillage %s boîte %s" % [str(mesh.get_path()).replace("/root/Desert/", ""), box])
		for instance in multimeshes:
			for i in instance.multimesh.instance_count:
				var xform := instance.global_transform * instance.multimesh.get_instance_transform(i)
				var box := xform * instance.multimesh.mesh.get_aabb()
				if box.grow(1.2).has_point(point):
					print("    multimesh %s #%d boîte %s" % [str(instance.get_path()).replace("/root/Desert/", ""), i, box])
	finish()
