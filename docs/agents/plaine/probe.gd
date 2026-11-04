extends SceneTree
## Boîte englobante de modèles Kenney (échelle 1), et pour les meubles creux, hauteurs des surfaces
## horizontales rencontrées en descendant au milieu (étagères) : -- kit/modele ...
func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var models := OS.get_cmdline_user_args()
	var world := Node3D.new()
	root.add_child(world)
	await physics_frame
	for m in models:
		var probe := m.begins_with("+")
		if probe:
			m = m.substr(1)
		var s: Node3D = load("res://assets/models/kenney/%s.glb" % m).instantiate()
		world.add_child(s)
		var box := AABB()
		var first := true
		var body := StaticBody3D.new()
		world.add_child(body)
		for n: MeshInstance3D in s.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = n.global_transform * n.get_aabb()
			box = b if first else box.merge(b)
			first = false
			if probe:
				var shape := CollisionShape3D.new()
				shape.shape = n.mesh.create_trimesh_shape()
				shape.transform = n.global_transform
				body.add_child(shape)
		print("%-45s pos %s size %s" % [m, box.position.snappedf(0.01), box.size.snappedf(0.01)])
		if probe:
			await physics_frame
			await physics_frame
			var space := world.get_world_3d().direct_space_state
			var c := box.get_center()
			for column in [Vector2(c.x, c.z), Vector2(c.x - box.size.x * 0.3, c.z), Vector2(c.x + box.size.x * 0.3, c.z)]:
				var y := box.end.y + 0.5
				var hits: Array[float] = []
				for i in 20:
					var q := PhysicsRayQueryParameters3D.create(Vector3(column.x, y, column.y), Vector3(column.x, box.position.y - 0.5, column.y))
					q.hit_back_faces = false
					var hit := space.intersect_ray(q)
					if hit.is_empty():
						break
					hits.append(snappedf(hit.position.y, 0.005))
					y = hit.position.y - 0.004
				print("    colonne %s : surfaces %s" % [column.snappedf(0.01), hits])
			# Face avant : rayon horizontal depuis +Z et depuis -Z au milieu.
			for dir in [1.0, -1.0]:
				var from := Vector3(c.x, c.y, c.z + dir * (box.size.z + 1.0))
				var q2 := PhysicsRayQueryParameters3D.create(from, Vector3(c.x, c.y, c.z))
				var h := space.intersect_ray(q2)
				print("    depuis z %s : %s" % ["+" if dir > 0 else "-", h.position.snappedf(0.005) if h else "rien"])
		body.free()
		s.free()
	quit()
