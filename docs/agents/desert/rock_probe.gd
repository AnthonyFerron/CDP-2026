extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_grid_test.gd"
## Le rocher du bord signalé par la grille : sa forme de collision et ce qui est visible autour du contact.

const POINT := Vector3(46.4, 2.95, -42.1)


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	terrain = level.get_node("Exterior/Terrain")
	space = player.get_world_3d().direct_space_state
	await wait(5)
	_collect_visuals(level)
	_build_hash()
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.1
	query.shape = sphere
	query.transform = Transform3D(Basis(), POINT)
	for hit: Dictionary in space.intersect_shape(query, 8):
		var body := hit.collider as CollisionObject3D
		var owner_id := body.shape_find_owner(hit.shape)
		var holder := body.shape_owner_get_owner(owner_id) as CollisionShape3D
		print("ROCHER %s forme %d : %s en %s" % [body.get_path(), hit.shape, holder.shape.get_class(), holder.global_position.snappedf(0.01)])
	print("ROCHER sol %.2f ; visible 0,5 %s, 1 %s, 2 %s" % [terrain.surface_height(POINT.x, POINT.z), _visible_near(POINT, 0.5), _visible_near(POINT, 1.0), _visible_near(POINT, 2.0)])
	for instance in multimeshes:
		for i in instance.multimesh.instance_count:
			var xform := instance.global_transform * instance.multimesh.get_instance_transform(i)
			var box := xform * instance.multimesh.mesh.get_aabb()
			if box.grow(1.5).has_point(POINT):
				print("ROCHER multimesh %s #%d boîte %s visible %s" % [instance.get_path(), i, box, instance.is_visible_in_tree()])
	for mesh in meshes:
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		if box.grow(1.5).has_point(POINT) and box.size.length() < 100.0:
			print("ROCHER maillage %s boîte %s visible %s" % [mesh.get_path(), box, mesh.is_visible_in_tree()])
	finish()
