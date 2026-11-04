extends SceneTree
## Profil de hauteur d'un modèle : -- kit/modele axe(x|z) [n]
## Lance des rayons verticaux le long de l'axe donné (au centre de l'autre axe) et en travers, et imprime la hauteur
## de la surface la plus haute du modèle, à l'échelle 1.
func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var model: Node3D = load("res://assets/models/kenney/%s.glb" % args[0]).instantiate()
	root.add_child(model)
	var box := AABB()
	var first := true
	for n: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		n.create_trimesh_collision()
		var b: AABB = n.global_transform * n.get_aabb()
		box = b if first else box.merge(b)
		first = false
	await physics_frame
	await physics_frame
	var space := model.get_world_3d().direct_space_state
	var steps := 12
	for axis in ["x", "z"]:
		var line := "%s :" % axis
		for i in steps + 1:
			var t := float(i) / steps
			var p := box.get_center()
			if axis == "x":
				p.x = box.position.x + box.size.x * t
			else:
				p.z = box.position.z + box.size.z * t
			var query := PhysicsRayQueryParameters3D.create(Vector3(p.x, box.end.y + 1.0, p.z), Vector3(p.x, box.position.y - 1.0, p.z))
			var hit := space.intersect_ray(query)
			line += " %.2f@%.2f" % [hit.position.y if hit else -99.0, p.x if axis == "x" else p.z]
		print(line)
	# Coupe en travers au quart.
	for frac: float in [0.25, 0.5]:
		var line := "z=%.2f, le long de x :" % (box.position.z + box.size.z * frac)
		for i in steps + 1:
			var x := box.position.x + box.size.x * float(i) / steps
			var z: float = box.position.z + box.size.z * frac
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, box.end.y + 1.0, z), Vector3(x, box.position.y - 1.0, z)))
			line += " %.2f" % (hit.position.y if hit else -99.0)
		print(line)
	quit()
