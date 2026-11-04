extends SceneTree
## Boîtes exactes des modèles (kit/modele en arguments), en composant les transformations locales de chaque
## maillage jusqu'à la racine du modèle (les maillages imbriqués, comme le couvercle du cercueil, comptent).

func _initialize() -> void:
	for m in OS.get_cmdline_user_args():
		var s: Node3D = load("res://assets/models/kenney/%s.glb" % m).instantiate()
		var box := AABB()
		var first := true
		for n in s.find_children("*", "MeshInstance3D", true, false):
			var t := Transform3D()
			var node: Node = n
			while node and node != s:
				t = (node as Node3D).transform * t
				node = node.get_parent()
			var b: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
			box = b if first else box.merge(b)
			first = false
		print("\"%s\": ((%.2f, %.2f, %.2f), (%.2f, %.2f, %.2f))," % [m, box.position.x, box.position.y, box.position.z, box.size.x, box.size.y, box.size.z])
		s.free()
	quit()
