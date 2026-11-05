extends SceneTree
## Hauteur du dessus des tables (sommets du maillage), à l'échelle 1.
const MODELS := ["mini_dungeon/table", "furniture_kit/table"]
func _initialize():
	for m in MODELS:
		var s: Node = load("res://assets/models/kenney/%s.glb" % m).instantiate()
		root.add_child(s)
		var tops := {}
		for n: MeshInstance3D in s.find_children("*", "MeshInstance3D", true, false):
			var box: AABB = n.global_transform * n.get_aabb()
			print("%s aabb %s %s" % [m, box.position.snappedf(0.001), box.size.snappedf(0.001)])
			for surface in n.mesh.get_surface_count():
				var arrays := n.mesh.surface_get_arrays(surface)
				for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
					var p: Vector3 = n.global_transform * v
					var key := snappedf(p.y, 0.001)
					if key > box.end.y - 0.05:
						tops[key] = tops.get(key, 0) + 1
		var keys := tops.keys()
		keys.sort()
		print("  sommets hauts : ", keys.map(func(k): return "%s(%d)" % [k, tops[k]]))
		s.free()
	quit()
