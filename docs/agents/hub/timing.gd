extends SceneTree
## Temps de chargement du hub : terrain seul, puis scène complète.
func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var start := Time.get_ticks_msec()
	var terrain := HubTerrain.new()
	root.add_child(terrain)
	print("terrain : %d ms" % (Time.get_ticks_msec() - start))
	terrain.queue_free()
	await process_frame
	start = Time.get_ticks_msec()
	var scene: Node = load("res://scenes/levels/hub/hub.tscn").instantiate()
	print("chargement de la scène : %d ms" % (Time.get_ticks_msec() - start))
	start = Time.get_ticks_msec()
	root.get_node("GameState").reset()
	root.get_node("GameState").intro_done = true
	root.add_child(scene)
	print("ajout (ready) : %d ms" % (Time.get_ticks_msec() - start))
	await process_frame
	await process_frame
	var count := 0
	var meshes := 0
	var shapes := 0
	for node in scene.find_children("*", "", true, false):
		count += 1
		if node is MeshInstance3D or node is MultiMeshInstance3D:
			meshes += 1
		if node is CollisionShape3D:
			shapes += 1
	print("noeuds : %d, maillages : %d, formes : %d" % [count, meshes, shapes])
	var terrain_mesh: MeshInstance3D = scene.get_node("Terrain").get_child(0)
	print("sommets du terrain : %d" % terrain_mesh.mesh.surface_get_array_len(0))
	quit()
