extends SceneTree
## Coupe d'un modèle : -- chemin axe(x|z) ; pour des tranches de l'autre axe horizontal, l'étendue en y et sur l'axe.

func _initialize() -> void:
	var args := Array(OS.get_cmdline_user_args()).filter(func(arg: String) -> bool: return not arg.begins_with("--"))
	var scene: Node = (load(args[0]) as PackedScene).instantiate()
	var points: Array[Vector3] = []
	_collect(scene, Transform3D.IDENTITY, points)
	var box := AABB(points[0], Vector3.ZERO)
	for p in points:
		box = box.expand(p)
	print("boîte ", box)
	# Tranches selon z : pour chaque bande de z, l'étendue en y et en x des sommets.
	var slices := 12
	for i in slices:
		var z0 := box.position.z + box.size.z * i / slices
		var z1 := box.position.z + box.size.z * (i + 1) / slices
		var lo := Vector3.INF
		var hi := -Vector3.INF
		for p in points:
			if p.z >= z0 and p.z <= z1:
				lo = lo.min(p)
				hi = hi.max(p)
		print("z %.2f..%.2f : x %.2f..%.2f y %.2f..%.2f" % [z0, z1, lo.x, hi.x, lo.y, hi.y])
	scene.free()
	quit()


func _collect(node: Node, parent: Transform3D, points: Array[Vector3]) -> void:
	var xf := parent
	if node is Node3D:
		xf = parent * node.transform
	if node is MeshInstance3D and node.mesh:
		for v in node.mesh.get_faces():
			points.append(xf * v)
	for child in node.get_children():
		_collect(child, xf, points)
