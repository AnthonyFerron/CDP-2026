extends SceneTree
## Performances du désert (rendu Compatibility, sans synchronisation verticale) : compte les nœuds, les maillages,
## les MultiMesh, les lumières et les ombres, puis promène la caméra du joueur sur un parcours fixe à 6 m/s
## (portail, allée, arche, salle des colonnes, chambres, sanctuaire, oasis, caravane, cave) et mesure le temps
## d'image (moyenne, 95e centile, pire) et les appels de dessin. À lancer sans --headless, en 1280 × 720.
## Argument : une étiquette (avant, après) pour le journal.

const PATH := [
	Vector3(0, 0, 48), Vector3(0, 0, 20), Vector3(0, 0, 0), Vector3(-10, 0, -12), Vector3(-16, 0, -12),
	Vector3(-10, 0, -12), Vector3(10, 0, -12), Vector3(16, 0, -11), Vector3(10, 0, -8), Vector3(8, 0, -21),
	Vector3(-8, 0, -21), Vector3(-8, 0, -18), Vector3(0, 0, 4), Vector3(22, 0, 2), Vector3(36, 0, 0),
	Vector3(30, 0, 14), Vector3(0, 0, 10), Vector3(-26, 0, -18), Vector3(-33, 0, -26),
]
const CAVE_PATH := [Vector3(0, -40, -1.5), Vector3(-6, -40, -4.5), Vector3(-6, -40, -8), Vector3(6, -40, -8), Vector3(6, -40, -3), Vector3(0, -40, -2)]
const SPEED := 6.0


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func _run() -> void:
	var label: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "mesure"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	change_scene_to_file("res://scenes/levels/desert/desert.tscn")
	await frames(90)
	var level: Node = current_scene
	var player: Node3D = level.get_node("Player")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	_count(level, label)
	var outside := await _walk(level, player, PATH, false)
	level.set("_inside", true)
	level.call("_apply_location")
	await frames(10)
	var inside := await _walk(level, player, CAVE_PATH, true)
	print("PERF %s surface : %s" % [label, outside])
	print("PERF %s cave : %s" % [label, inside])
	state.reset()
	quit()


func _count(level: Node, label: String) -> void:
	var nodes := 0
	var meshes := 0
	var shadow_meshes := 0
	var multimeshes := 0
	var instances := 0
	var lights := 0
	var shadow_lights := 0
	var particles := 0
	var bodies := 0
	var shapes := 0
	for node in level.find_children("*", "", true, false):
		nodes += 1
		if node is MeshInstance3D:
			meshes += 1
			if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				shadow_meshes += 1
		elif node is MultiMeshInstance3D and node.multimesh:
			multimeshes += 1
			instances += node.multimesh.instance_count
			if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				shadow_meshes += 1
		elif node is Light3D:
			lights += 1
			if node.shadow_enabled:
				shadow_lights += 1
		elif node is CPUParticles3D or node is GPUParticles3D:
			particles += 1
		elif node is CollisionObject3D:
			bodies += 1
		elif node is CollisionShape3D:
			shapes += 1
	print("PERF %s nœuds %d, maillages %d, MultiMesh %d (%d instances), qui projettent une ombre %d, lumières %d (ombres %d), particules %d, corps %d, formes de collision %d" % [
		label, nodes, meshes, multimeshes, instances, shadow_meshes, lights, shadow_lights, particles, bodies, shapes])


## Promène le joueur sur le parcours et rend un résumé des temps d'image et des appels de dessin.
func _walk(level: Node, player: Node3D, path: Array, inside: bool) -> String:
	var terrain: Node = level.get_node("Exterior/Terrain")
	var pivot: Node3D = player.get_node("CameraPivot")
	var times: Array[float] = []
	var draws: Array[int] = []
	var objects: Array[int] = []
	var spots: Array[Vector3] = []
	for index in path.size() - 1:
		var from: Vector3 = path[index]
		var to: Vector3 = path[index + 1]
		var length := Vector2(to.x - from.x, to.z - from.z).length()
		var steps := maxi(1, int(length / SPEED * 60.0))
		for step in steps:
			var spot := from.lerp(to, float(step) / steps)
			var ground: float = -40.0 if inside else terrain.surface_height(spot.x, spot.z)
			player.global_position = Vector3(spot.x, ground, spot.z)
			pivot.rotation.y = atan2(-(to.x - from.x), -(to.z - from.z))
			var start := Time.get_ticks_usec()
			await process_frame
			times.append((Time.get_ticks_usec() - start) / 1000.0)
			spots.append(spot)
			draws.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
			objects.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
	times = times.slice(5)
	draws = draws.slice(5)
	spots = spots.slice(5)
	var worst := 0
	for index in times.size():
		if times[index] > times[worst]:
			worst = index
	print("PERF pire image en %s (image %d)" % [spots[worst].snappedf(0.1), worst])
	var sorted := times.duplicate()
	sorted.sort()
	var total := 0.0
	for value in times:
		total += value
	var draw_total := 0
	var draw_max := 0
	for value in draws:
		draw_total += value
		draw_max = maxi(draw_max, value)
	var object_max := 0
	for value in objects:
		object_max = maxi(object_max, value)
	return "%d images, moyenne %.2f ms, 95 %% sous %.2f ms, pire %.2f ms ; appels de dessin moyenne %d, max %d ; objets max %d" % [
		times.size(), total / times.size(), sorted[int(sorted.size() * 0.95)], sorted[-1], draw_total / draws.size(), draw_max, object_max]
