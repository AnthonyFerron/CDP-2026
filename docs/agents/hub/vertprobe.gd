extends SceneTree
## Sommets d'un maillage de personnage, par niveau de hauteur : -- <kit/modele> <nom du maillage>
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var s: Node = load("res://assets/models/kenney/%s.glb" % args[0]).instantiate()
	var mi: MeshInstance3D = s.find_child(args[1], true, false)
	var levels := {}
	for surface in mi.mesh.get_surface_count():
		var arrays := mi.mesh.surface_get_arrays(surface)
		for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			var key := snappedf(v.y, 0.01)
			if not levels.has(key):
				levels[key] = [INF, -INF, INF, -INF, 0]
			var l: Array = levels[key]
			l[0] = minf(l[0], v.x)
			l[1] = maxf(l[1], v.x)
			l[2] = minf(l[2], v.z)
			l[3] = maxf(l[3], v.z)
			l[4] += 1
	var keys := levels.keys()
	keys.sort()
	for k in keys:
		var l: Array = levels[k]
		print("y %.2f : x %.3f..%.3f z %.3f..%.3f (%d)" % [k, l[0], l[1], l[2], l[3], l[4]])
	s.free()
	quit()
