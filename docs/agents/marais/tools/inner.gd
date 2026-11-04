extends SceneTree
## Faces intérieures : -- kit/modele ymin ymax zmin zmax : plus petit x positif et plus grand x négatif des sommets.

func _initialize():
	var a := OS.get_cmdline_user_args()
	var s: Node3D = load("res://assets/models/kenney/%s.glb" % a[0]).instantiate()
	root.add_child(s)
	var y0 := float(a[1])
	var y1 := float(a[2])
	var z0 := float(a[3])
	var z1 := float(a[4])
	var pos := INF
	var neg := -INF
	var front := -INF
	for n: MeshInstance3D in s.find_children("*", "MeshInstance3D", true, false):
		for surface in n.mesh.get_surface_count():
			for v: Vector3 in n.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var p := n.global_transform * v
				if p.y < y0 or p.y > y1 or p.z < z0 or p.z > z1:
					continue
				if p.x > 0.0:
					pos = minf(pos, p.x)
				else:
					neg = maxf(neg, p.x)
				front = maxf(front, p.z)
	print("inner x+ %.3f  x- %.3f  front z %.3f" % [pos, neg, front])
	quit()
