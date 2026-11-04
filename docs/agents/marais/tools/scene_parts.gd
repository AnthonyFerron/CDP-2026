extends SceneTree
## Boîtes réelles, dans la scène lancée, des maillages des nœuds dont le chemin contient le motif : -- motif

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.get_node("GameState").reset()
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	for i in 20:
		await process_frame
	var level: Node = current_scene
	var pattern: String = OS.get_cmdline_user_args()[0]
	var shown := 0
	for node in level.find_children("*", "MeshInstance3D", true, false):
		var path := String(level.get_path_to(node))
		if not path.contains(pattern) or shown > 12:
			continue
		shown += 1
		var mesh := node as MeshInstance3D
		var box: AABB = mesh.global_transform * mesh.mesh.get_aabb()
		print("%s local %s aabb %s %s" % [path, mesh.position.snappedf(0.001), box.position.snappedf(0.01), box.size.snappedf(0.01)])
	quit()
