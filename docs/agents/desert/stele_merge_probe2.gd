extends SceneTree
## Comme le test de performances : caméra du joueur dans la cave, appels de dessin avant et après le regroupement
## des stèles (desert.gd lancé avec la fusion des stèles désactivée), et visibilité du corps du joueur.

const CAVE := [Vector3(0, -40, -1.5), Vector3(-6, -40, -4.5), Vector3(-6, -40, -8), Vector3(6, -40, -8)]


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func _measure(level: Node, player: Node3D, tag: String) -> void:
	var pivot: Node3D = player.get_node("CameraPivot")
	var line := ""
	for index in CAVE.size() - 1:
		var from: Vector3 = CAVE[index]
		var to: Vector3 = CAVE[index + 1]
		player.global_position = from
		pivot.rotation.y = atan2(-(to.x - from.x), -(to.z - from.z))
		await frames(10)
		line += " %d/%d" % [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)]
	var visual: Node3D = player.get_node("Visual")
	print("FUSION2 %s : appels/objets%s ; corps visible %s, caméra %s" % [tag, line, visual.is_visible_in_tree(),
		root.get_viewport().get_camera_3d().get_path()])


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	change_scene_to_file("res://scenes/levels/desert/desert.tscn")
	await frames(90)
	var level: Node = current_scene
	var player: Node3D = level.get_node("Player")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	level.set("_inside", true)
	level.call("_apply_location")
	await frames(10)
	await _measure(level, player, "sans fusion")
	for stele: Node3D in [level.get_node("Exterior/Clues/Levant"), level.get_node("Exterior/Clues/Zenith"), level.get_node("Exterior/Clues/Couchant")]:
		level.call("_merge_static", stele)
	await frames(5)
	await _measure(level, player, "fusion")
	state.reset()
	quit()
