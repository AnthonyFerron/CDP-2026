extends SceneTree
## Profil des arbres : pour chaque modèle, à chaque tranche de hauteur (échelle 1), la distance horizontale maximale
## des sommets à l'axe du tronc (pris au pied du modèle).

func _initialize() -> void:
	for path: String in OS.get_cmdline_user_args():
		if path.begins_with("--"):
			continue
		var scene: Node = (load(path) as PackedScene).instantiate()
		var points: Array[Vector3] = []
		_collect(scene, Transform3D.IDENTITY, points)
		var base := Vector3.ZERO
		var count := 0
		for p in points:
			if p.y < 0.05:
				base += p
				count += 1
		base = base / max(count, 1)
		var bottom := 1e9
		var top := -1e9
		for p in points:
			bottom = min(bottom, p.y)
			top = max(top, p.y)
		var line := "%s base (%.2f, %.2f) y %.2f..%.2f :" % [path.get_file(), base.x, base.z, bottom, top]
		for slice in 10:
			var y0 := bottom + (top - bottom) * slice / 10.0
			var y1 := bottom + (top - bottom) * (slice + 1) / 10.0
			var reach := 0.0
			for p in points:
				if p.y >= y0 and p.y <= y1:
					reach = max(reach, Vector2(p.x - base.x, p.z - base.z).length())
			line += " [%.2f %.2f]" % [y0, reach]
		print(line)
		# Feuillage : les sommets à plus de 0,15 de l'axe ; leur bas, leur centre et leur rayon autour de ce centre,
		# pour les sommets sous 0,6 (ce que le joueur peut toucher à l'échelle 3,5).
		var low := 1e9
		var center := Vector2.ZERO
		var n := 0
		for p in points:
			if Vector2(p.x - base.x, p.z - base.z).length() > 0.15:
				low = min(low, p.y)
				if p.y < 0.6:
					center += Vector2(p.x, p.z)
					n += 1
		center /= max(n, 1)
		var radius := 0.0
		for p in points:
			if p.y < 0.6 and Vector2(p.x - base.x, p.z - base.z).length() > 0.15:
				radius = max(radius, Vector2(p.x, p.z).distance_to(center))
		print("  feuillage dès y %.2f, centre bas %s, rayon bas %.2f (%d sommets)" % [low, center, radius, n])
		scene.free()
	quit()


func _collect(node: Node, parent: Transform3D, points: Array[Vector3]) -> void:
	var xf := parent
	if node is Node3D:
		xf = parent * node.transform
	if node is MeshInstance3D and node.mesh:
		for s in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(s)
			for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				points.append(xf * v)
	for child in node.get_children():
		_collect(child, xf, points)
