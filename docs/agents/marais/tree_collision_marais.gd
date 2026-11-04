extends SceneTree
## Pour chaque niveau : chaque arbre (multimesh ou modèle posé) a-t-il une collision à son tronc ?
## Affiche les arbres sans collision, avec leur distance au centre, et le nombre total.
const LEVELS := ["marais/marais"]
const TREE_WORDS := ["tree", "pine", "cactus", "dead", "trunk", "birch"]

func _initialize() -> void:
	_run.call_deferred()

func is_tree(text: String) -> bool:
	text = text.to_lower()
	for word in TREE_WORDS:
		if text.contains(word):
			return true
	return false

func _run() -> void:
	var state: Node = root.get_node("GameState")
	for level_name in LEVELS:
		state.reset()
		state.intro_done = true
		change_scene_to_file("res://scenes/levels/%s.tscn" % level_name)
		for i in 30:
			await physics_frame
		var level: Node3D = current_scene
		var trees: Array = []  # [position, nom]
		for node in level.find_children("*", "MultiMeshInstance3D", true, false):
			var mm: MultiMesh = node.multimesh
			if not mm or not mm.mesh:
				continue
			var label: String = mm.mesh.resource_path + " " + mm.mesh.resource_name + " " + node.name
			if not is_tree(label):
				continue
			for index in mm.instance_count:
				var t: Transform3D = node.global_transform * mm.get_instance_transform(index)
				trees.append([t.origin, label.get_file()])
		for node in level.find_children("*", "Node3D", true, false):
			if node is MultiMeshInstance3D or node.scene_file_path.is_empty():
				continue
			if is_tree(node.scene_file_path.get_file()) and node.is_visible_in_tree():
				trees.append([node.global_position, node.scene_file_path.get_file()])
		var space := level.get_world_3d().direct_space_state
		var sphere := SphereShape3D.new()
		sphere.radius = 0.25
		var missing := 0
		var lines: Array[String] = []
		for entry in trees:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = sphere
			query.transform = Transform3D(Basis(), entry[0] + Vector3.UP * 1.0)
			var hits := space.intersect_shape(query, 4)
			var solid := false
			for hit in hits:
				if not (hit.collider is Area3D):
					solid = true
			if not solid:
				missing += 1
				var flat := Vector2(entry[0].x, entry[0].z)
				if lines.size() < 400:
					lines.append("  %s (%.1f, %.1f, %.1f) r=%.0f" % [entry[1], entry[0].x, entry[0].y, entry[0].z, flat.length()])
		print("== %s : %d arbres, %d sans collision" % [level_name, trees.size(), missing])
		for line in lines:
			print(line)
	state.reset()
	quit()
