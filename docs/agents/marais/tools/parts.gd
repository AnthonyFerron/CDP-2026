extends SceneTree
## Boîte de chaque maillage d'un modèle : -- kit/modele

func _initialize() -> void:
	var s: Node3D = load("res://assets/models/kenney/%s.glb" % OS.get_cmdline_user_args()[0]).instantiate()
	root.add_child(s)
	for n in s.find_children("*", "Node3D", true, false):
		var line := "%s %s pos %s" % [n.name, n.get_class(), (n as Node3D).global_position.snappedf(0.001)]
		if n is MeshInstance3D:
			var box: AABB = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).mesh.get_aabb()
			line += " aabb %s %s" % [box.position.snappedf(0.001), box.size.snappedf(0.001)]
		print(line)
	quit()
