extends SceneTree
## Profil d'un modèle : -- kit/modele axe(x|z) min max pas bande_min bande_max
## Pour chaque tranche le long de l'axe, la hauteur max des sommets dont l'autre coordonnée est dans la bande,
## et la coordonnée max (avant) des sommets par tranche de hauteur si axe = y.

func _initialize():
	var a := OS.get_cmdline_user_args()
	var s: Node3D = load("res://assets/models/kenney/%s.glb" % a[0]).instantiate()
	root.add_child(s)
	var axis: String = a[1]
	var lo := float(a[2])
	var hi := float(a[3])
	var step := float(a[4])
	var band_lo := float(a[5])
	var band_hi := float(a[6])
	var points := PackedVector3Array()
	for n: MeshInstance3D in s.find_children("*", "MeshInstance3D", true, false):
		var mesh := n.mesh
		for surface in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(surface)
			for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				points.append(n.global_transform * v)
	var t := lo
	while t < hi:
		var best := -INF
		for p in points:
			if axis == "z" and p.z >= t and p.z < t + step and p.x >= band_lo and p.x <= band_hi:
				best = maxf(best, p.y)
			elif axis == "x" and p.x >= t and p.x < t + step and p.z >= band_lo and p.z <= band_hi:
				best = maxf(best, p.y)
			elif axis == "y" and p.y >= t and p.y < t + step and p.x >= band_lo and p.x <= band_hi:
				best = maxf(best, p.z)
		print("%s %.2f..%.2f : %.3f" % [axis, t, t + step, best])
		t += step
	quit()
