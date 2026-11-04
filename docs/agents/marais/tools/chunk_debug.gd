extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.get_node("GameState").reset()
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	for i in 20:
		await process_frame
	var scatter: Node = current_scene.get_node("Scatter")
	var shown := 0
	for node in scatter.get_children():
		var chunk := node as MultiMeshInstance3D
		if chunk and String(chunk.name).begins_with("Detail_") and shown < 4:
			shown += 1
			var mm := chunk.multimesh
			var first := chunk.global_transform * mm.get_instance_transform(0).origin
			print(chunk.name, " pos ", chunk.global_position, " aabb ", chunk.get_aabb(), " n ", mm.instance_count, " premier ", first)
	quit()
