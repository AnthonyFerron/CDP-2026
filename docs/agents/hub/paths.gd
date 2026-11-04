extends SceneTree
## Chemins des nœuds d'un modèle : -- kit/modele ...
func _initialize() -> void:
	for m in OS.get_cmdline_user_args():
		var s: Node = load("res://assets/models/kenney/%s.glb" % m).instantiate()
		print("== ", m, " racine ", s.name, " (", s.get_class(), ")")
		for n in s.find_children("*", "", true, false):
			print("  ", s.get_path_to(n), " (", n.get_class(), ")")
		s.free()
	quit()
