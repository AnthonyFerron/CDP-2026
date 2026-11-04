extends SceneTree
## Où est l'étoffe des drapeaux (échelle 1) : pour chaque hauteur, l'étendue en z de la géométrie, vue de côté.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for model in ["castle_kit/flag-banner-long", "castle_kit/flag-wide", "castle_kit/flag-pennant"]:
		var world := Node3D.new()
		root.add_child(world)
		var flag: Node3D = load("res://assets/models/kenney/%s.glb" % model).instantiate()
		world.add_child(flag)
		await process_frame
		var body := StaticBody3D.new()
		world.add_child(body)
		for mesh: MeshInstance3D in flag.find_children("*", "MeshInstance3D", true, false):
			var shape := CollisionShape3D.new()
			shape.shape = mesh.mesh.create_trimesh_shape()
			shape.transform = mesh.global_transform
			body.add_child(shape)
		await physics_frame
		await physics_frame
		var space := world.get_world_3d().direct_space_state
		var top := 2.17 if "long" in model else 0.866
		print(model)
		for step in 12:
			var y := top * (step + 0.5) / 12.0
			var hits: Array[float] = []
			for k in 41:
				var z := -0.6 + k * 0.03
				var query := PhysicsRayQueryParameters3D.create(Vector3(0.5, y, z), Vector3(-0.5, y, z))
				query.hit_back_faces = true
				if not space.intersect_ray(query).is_empty():
					hits.append(z)
			print("  y %.2f : %s" % [y, ("z %.2f..%.2f" % [hits.min(), hits.max()]) if hits else "vide"])
		world.free()
	quit()
