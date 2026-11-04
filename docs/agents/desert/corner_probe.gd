extends SceneTree
## Coupe du modèle mini_arena/wall-corner à l'échelle 5 : pour chaque hauteur et chaque x, le modèle est-il traversé
## par un rayon nord-sud (#) ou vide (.) ? Même chose en est-ouest pour chaque z.


func _initialize() -> void:
	var scene: Node3D = load("res://assets/models/kenney/mini_arena/wall-corner.glb").instantiate()
	root.add_child(scene)
	var mesh_instance: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
	var tm := mesh_instance.mesh.generate_triangle_mesh()
	var xform := mesh_instance.global_transform
	print("CORNER aabb %s" % (xform * mesh_instance.get_aabb()))
	for h in [0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95]:
		var line := ""
		for i in 21:
			var x := -0.55 + i * 0.05
			var hit := tm.intersect_segment(Vector3(x, h, -1.0), Vector3(x, h, 1.0))
			line += "#" if not hit.is_empty() else "."
		print("CORNER nord-sud h %.2f x -0.55..0.45 : %s" % [h, line])
	for h in [0.2, 0.5, 0.8]:
		var line := ""
		for i in 21:
			var z := -0.55 + i * 0.05
			var hit := tm.intersect_segment(Vector3(-1.0, h, z), Vector3(1.0, h, z))
			line += "#" if not hit.is_empty() else "."
		print("CORNER est-ouest h %.2f z -0.55..0.45 : %s" % [h, line])
	quit()
