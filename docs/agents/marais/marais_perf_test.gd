extends SceneTree
## Performances des marais (rendu Compatibility, sans synchronisation verticale) : compte les nœuds, les maillages,
## les MultiMesh, les lumières et les objets qui projettent une ombre, puis promène la caméra du joueur sur un
## parcours fixe à 6 m/s (arrivée, ponton du campement, campement, ponton du cimetière, cimetière, ponton de la
## crypte, îlot de la crypte ; dans la crypte : escalier, salle, chambres, embranchements) et mesure le temps d'image
## (moyenne, 95e centile, pire) et les appels de dessin. À lancer sans --headless, en 1280 × 720.
## Arguments : une étiquette (avant, après) pour le journal, puis --api=… (adresse morte du serveur).

const PATH := [
	Vector2(0, 60), Vector2(0, 52), Vector2(-3, 48), Vector2(-18, 27), Vector2(-20, 22), Vector2(-16, 19), Vector2(6, 4),
	Vector2(12, 0), Vector2(18, -2), Vector2(14, -8), Vector2(8.5, -10), Vector2(3, -28), Vector2(0, -32), Vector2(-8, -36),
	Vector2(8, -38),
]
const CRYPT_PATH := [
	Vector2(0, 11), Vector2(0, 2), Vector2(0, -6), Vector2(0, -12), Vector2(-12, -12), Vector2(-25, -12), Vector2(-12, -12),
	Vector2(12, -12), Vector2(25, -12), Vector2(12, -12), Vector2(12, -2), Vector2(18, 2), Vector2(12, -2), Vector2(0, -2),
	Vector2(-12, -2), Vector2(-18, 2),
]
const SPEED := 6.0


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func _run() -> void:
	var args := Array(OS.get_cmdline_user_args()).filter(func(arg: String) -> bool: return not arg.begins_with("--"))
	var label: String = args[0] if args.size() > 0 else "mesure"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	await frames(90)
	var level: Node = current_scene
	# La fenêtre peut perdre le focus : le menu de pause ne doit pas s'ouvrir pendant la mesure.
	root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
	paused = false
	var player: Node3D = level.get_node("Player")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	_count(level, label)
	var outside := await _walk(level, player, PATH, 0.0)
	level.set("_inside", true)
	level.call("_apply_location")
	await frames(10)
	var inside := await _walk(level, player, CRYPT_PATH, -40.0)
	print("PERF %s dehors : %s" % [label, outside])
	print("PERF %s crypte : %s" % [label, inside])
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
	var faded := 0
	for node in level.find_children("*", "", true, false):
		nodes += 1
		if node is GeometryInstance3D and (node as GeometryInstance3D).visibility_range_end > 0.0:
			faded += 1
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
	print("PERF %s nœuds %d, maillages %d, MultiMesh %d (%d instances), qui projettent une ombre %d, lumières %d (ombres %d), particules %d, corps %d, formes de collision %d, à distance de visibilité %d" % [
		label, nodes, meshes, multimeshes, instances, shadow_meshes, lights, shadow_lights, particles, bodies, shapes, faded])


## Promène le joueur sur le parcours et rend un résumé des temps d'image et des appels de dessin.
func _walk(level: Node, player: Node3D, path: Array, base: float) -> String:
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	var pivot: Node3D = player.get_node("CameraPivot")
	var times: Array[float] = []
	var draws: Array[int] = []
	var objects: Array[int] = []
	var spots: Array[Vector3] = []
	for index in path.size() - 1:
		var from: Vector2 = path[index]
		var to: Vector2 = path[index + 1]
		var steps := maxi(1, int(from.distance_to(to) / SPEED * 60.0))
		for step in steps:
			var spot := from.lerp(to, float(step) / steps)
			# Sol sous le point : pontons, berges ou dalles ; dehors, jamais sous l'eau.
			# Dans la crypte, le rayon part sous le plafond : au-dessus des marches, il suit leur pente.
			var top := base + 8.0
			if base < 0.0:
				top = base + 3.0 + clampf((spot.y - 4.17) / 5.48 * 4.05, 0.0, 4.05)
			var ray := PhysicsRayQueryParameters3D.create(Vector3(spot.x, top, spot.y), Vector3(spot.x, top - 14.0, spot.y))
			ray.collision_mask = 1
			var hit := space.intersect_ray(ray)
			var ground: float = hit.position.y if not hit.is_empty() else base
			if base == 0.0:
				ground = maxf(ground, -0.3)
			player.global_position = Vector3(spot.x, ground, spot.y)
			pivot.rotation.y = atan2(-(to.x - from.x), -(to.y - from.y))
			var start := Time.get_ticks_usec()
			await process_frame
			times.append((Time.get_ticks_usec() - start) / 1000.0)
			spots.append(player.global_position)
			draws.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
			objects.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
	times = times.slice(5)
	draws = draws.slice(5)
	objects = objects.slice(5)
	spots = spots.slice(5)
	var worst := 0
	var most := 0
	for index in times.size():
		if times[index] > times[worst]:
			worst = index
		if draws[index] > draws[most]:
			most = index
	print("PERF pire image en %s ; le plus d'appels de dessin en %s" % [spots[worst].snappedf(0.1), spots[most].snappedf(0.1)])
	var sorted := times.duplicate()
	sorted.sort()
	var total := 0.0
	for value in times:
		total += value
	var draw_total := 0
	for value in draws:
		draw_total += value
	var object_total := 0
	var object_max := 0
	for value in objects:
		object_total += value
		object_max = maxi(object_max, value)
	return "%d images, moyenne %.2f ms, 95 %% sous %.2f ms, pire %.2f ms ; appels de dessin moyenne %d, max %d ; objets moyenne %d, max %d" % [
		times.size(), total / times.size(), sorted[int(sorted.size() * 0.95)], sorted[-1], draw_total / draws.size(), draws[most],
		object_total / objects.size(), object_max]
