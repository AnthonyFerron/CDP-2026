extends SceneTree
## Boîtes englobantes des modèles Kenney donnés en arguments (kit/modèle), à l'échelle 1.

func _initialize():
	for m in OS.get_cmdline_user_args():
		var s: Node = load("res://assets/models/kenney/%s.glb" % m).instantiate()
		root.add_child(s)
		var box := AABB()
		var first := true
		for n in s.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = n.global_transform * n.get_aabb()
			box = b if first else box.merge(b)
			first = false
		print("\"%s\": ((%.2f, %.2f, %.2f), (%.2f, %.2f, %.2f))," % [m, box.position.x, box.position.y, box.position.z, box.size.x, box.size.y, box.size.z])
		s.free()
	quit()
