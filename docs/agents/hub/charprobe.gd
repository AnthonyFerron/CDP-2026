extends SceneTree
## Structure des modèles de personnages : nœuds, maillages et leurs boîtes, squelette, animations.
func _initialize() -> void:
	for m in OS.get_cmdline_user_args():
		print("=== ", m)
		var s: Node3D = load("res://assets/models/kenney/%s.glb" % m).instantiate()
		root.add_child(s)
		for n in s.find_children("*", "", true, false):
			var line := "%s%s (%s)" % ["  ".repeat(str(s.get_path_to(n)).count("/")), n.name, n.get_class()]
			if n is MeshInstance3D:
				var b: AABB = n.global_transform * n.get_aabb()
				line += " aabb pos %s size %s" % [b.position.snappedf(0.01), b.size.snappedf(0.01)]
			if n is Node3D:
				line += " at %s" % (n as Node3D).global_position.snappedf(0.01)
			print(line)
			if n is Skeleton3D:
				var sk := n as Skeleton3D
				for i in sk.get_bone_count():
					print("    bone %d %s parent %d rest %s global %s" % [i, sk.get_bone_name(i), sk.get_bone_parent(i), sk.get_bone_rest(i).origin.snappedf(0.01), sk.get_bone_global_rest(i).origin.snappedf(0.01)])
			if n is AnimationPlayer:
				var ap := n as AnimationPlayer
				print("    animations: ", ap.get_animation_list())
		s.free()
	quit()
