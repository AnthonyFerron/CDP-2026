extends SceneTree
## Plan du modèle mini_arena/wall-corner à la hauteur h : # si le point est dans le volume (un rayon vers +x en sort
## un nombre impair de fois), . sinon. x et z de -0.55 à 0.45, au pas de 0,05.


func _initialize() -> void:
	var scene: Node3D = load("res://assets/models/kenney/mini_arena/wall-corner.glb").instantiate()
	root.add_child(scene)
	var mesh_instance: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
	var faces := mesh_instance.mesh.get_faces()
	for h in [0.3, 0.6]:
		print("PLAN h %.1f (lignes : z croissant, colonnes : x croissant)" % h)
		for j in 21:
			var z := -0.55 + j * 0.05 + 0.0013
			var line := ""
			for i in 21:
				var x := -0.55 + i * 0.05 + 0.0017
				var origin := Vector3(x, h + 0.0011, z)
				var crossings := 0
				for f in range(0, faces.size(), 3):
					if Geometry3D.ray_intersects_triangle(origin, Vector3.RIGHT, faces[f], faces[f + 1], faces[f + 2]) != null:
						crossings += 1
				line += "#" if crossings % 2 == 1 else "."
			print("PLAN z %+.2f %s" % [z, line])
	quit()
