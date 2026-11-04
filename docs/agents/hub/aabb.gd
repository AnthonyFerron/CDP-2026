extends SceneTree
## Boîtes englobantes des modèles Kenney donnés en arguments (kit/modèle), au format de MODEL_BOXES.
func _initialize():
	for m in OS.get_cmdline_user_args():
		var path := "res://assets/models/kenney/%s.glb" % m
		if not ResourceLoader.exists(path):
			print("ABSENT ", m)
			continue
		var s: Node = load(path).instantiate()
		root.add_child(s)
		var box := AABB()
		var first := true
		for n in s.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = n.global_transform * n.get_aabb()
			box = b if first else box.merge(b)
			first = false
		var p := box.position.snappedf(0.01)
		var z := box.size.snappedf(0.01)
		print('    "%s": ((%s, %s, %s), (%s, %s, %s)),' % [m, p.x, p.y, p.z, z.x, z.y, z.z])
		s.free()
	quit()
