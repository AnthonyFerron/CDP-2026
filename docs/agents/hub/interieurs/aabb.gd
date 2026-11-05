extends SceneTree
## Boîtes englobantes (coin, taille) des modèles listés en arguments, à l'échelle 1.
func _initialize():
	for m in OS.get_cmdline_user_args():
		if m.begins_with("--"):
			continue
		var s: Node = load("res://assets/models/kenney/%s.glb" % m).instantiate()
		root.add_child(s)
		var box := AABB()
		var first := true
		for n in s.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = n.global_transform * n.get_aabb()
			box = b if first else box.merge(b)
			first = false
		var materials := []
		for n in s.find_children("*", "MeshInstance3D", true, false):
			var mesh: Mesh = n.mesh
			for i in mesh.get_surface_count():
				var mat := mesh.surface_get_material(i) as StandardMaterial3D
				if mat:
					materials.append("%s %s" % [mat.resource_name, mat.albedo_color.to_html(false)])
		print('    "%s": ((%.2f, %.2f, %.2f), (%.2f, %.2f, %.2f)),  # %s' % [m, box.position.x, box.position.y, box.position.z, box.size.x, box.size.y, box.size.z, ", ".join(materials)])
		s.free()
	quit()
