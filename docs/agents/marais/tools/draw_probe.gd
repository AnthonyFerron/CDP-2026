extends SceneTree
## Appels de dessin d'une vue, puis en cachant tour à tour des parties du niveau : où vont les appels.
## -- dehors|crypte x,y,z:tx,ty,tz chemin1 chemin2 ...

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count:
		await process_frame

func vec(text: String) -> Vector3:
	var p := text.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))

func draws() -> int:
	await frames(4)
	await RenderingServer.frame_post_draw
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)

func _run() -> void:
	var args := Array(OS.get_cmdline_user_args()).filter(func(arg: String) -> bool: return not arg.begins_with("--"))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var state: Node = root.get_node("GameState")
	state.reset()
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	await frames(60)
	var level: Node = current_scene
	root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
	paused = false
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("Hud").visible = false
	level.set("_inside", args[0] == "crypte")
	level.call("_apply_location")
	var camera := Camera3D.new()
	camera.fov = 75.0
	level.add_child(camera)
	camera.current = true
	var spec: PackedStringArray = String(args[1]).split(":")
	camera.global_position = vec(spec[0])
	camera.look_at(vec(spec[1]))
	await frames(20)
	print("PROBE tout : %d" % await draws())
	var moon: DirectionalLight3D = level.get_node("Moon")
	if moon.visible:
		moon.shadow_enabled = false
		print("PROBE sans ombre de lune : %d" % await draws())
		moon.shadow_enabled = true
	for path: String in args.slice(2):
		var node: Node3D = level.get_node(path)
		node.visible = false
		print("PROBE sans %s : %d" % [path, await draws()])
		node.visible = true
	state.reset()
	quit()
