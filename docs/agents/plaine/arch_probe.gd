extends SceneTree
## Largeur réelle de l'ouverture du mur voûté (fantasy_town_kit/wall-doorway-round) à l'échelle 4, par hauteur.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var arch: Node3D = load("res://assets/models/kenney/fantasy_town_kit/wall-doorway-round.glb").instantiate()
	arch.scale = Vector3.ONE * 4.0
	world.add_child(arch)
	await process_frame
	var body := StaticBody3D.new()
	world.add_child(body)
	for mesh: MeshInstance3D in arch.find_children("*", "MeshInstance3D", true, false):
		var shape := CollisionShape3D.new()
		shape.shape = mesh.mesh.create_trimesh_shape()
		shape.transform = mesh.global_transform
		body.add_child(shape)
	await physics_frame
	await physics_frame
	var space := world.get_world_3d().direct_space_state
	# Le mur du modèle est à x = 0,4..0,5 (échelle 1), son ouverture centrée en z = 0.
	for height in [0.2, 0.8, 1.4, 1.8, 2.2, 2.6, 2.9]:
		var line := "hauteur %.1f :" % height
		for direction in [-1.0, 1.0]:
			var query := PhysicsRayQueryParameters3D.create(Vector3(1.8, height, 0.0), Vector3(1.8, height, direction * 2.5))
			var hit := space.intersect_ray(query)
			line += " %s" % (str(snappedf(hit.position.z, 0.01)) if hit else "rien")
		print(line)
	quit()
