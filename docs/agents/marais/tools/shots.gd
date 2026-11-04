extends SceneTree
## Captures depuis des caméras libres : -- <scène> <dossier> <nom>=x,y,z:tx,ty,tz[:taille] ...
## Options : inside (crypte), outside, nofog / fog, noshadow, open (le tombeau s'ouvre), wait=<images>.
const BASE := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/"

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count:
		await process_frame

func vec(text: String) -> Vector3:
	var p := text.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := BASE + args[1] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	change_scene_to_file(args[0])
	await frames(40)
	var level: Node = current_scene
	if level.has_node("Hud"):
		level.get_node("Hud").visible = false
	if level.has_node("Player"):
		level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	var camera := Camera3D.new()
	camera.fov = 75.0
	camera.far = 500.0
	level.add_child(camera)
	camera.current = true
	for entry in args.slice(2):
		# Options du jeu (--api=… : adresse locale morte du serveur), sans rapport avec les vues.
		if entry.begins_with("--"):
			continue
		if entry == "noshadow":
			level.get_node("Moon").shadow_enabled = false
			await frames(4)
			continue
		if entry == "nofog":
			level.get_node("WorldEnvironment").environment.fog_enabled = false
			await frames(4)
			continue
		if entry == "fog":
			level.get_node("WorldEnvironment").environment.fog_enabled = true
			await frames(4)
			continue
		if entry == "open":
			level.call("_on_mechanism_validated", true)
			await frames(220)
			camera.current = true
			continue
		if entry.begins_with("hide="):
			for path in entry.substr(5).split(","):
				level.get_node(path).visible = false
			await frames(4)
			continue
		if entry.begins_with("wait="):
			await frames(int(entry.substr(5)))
			continue
		if entry == "inside" or entry == "outside":
			level.set("_inside", entry == "inside")
			level.call("_apply_location")
			await frames(4)
			continue
		var name := entry.split("=")[0]
		var spec := entry.split("=")[1]
		var parts := spec.split(":")
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		if parts.size() > 2:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = float(parts[2])
		camera.global_position = vec(parts[0])
		var target := vec(parts[1])
		var up := Vector3.FORWARD if absf((target - camera.global_position).normalized().y) > 0.99 else Vector3.UP
		camera.look_at(target, up)
		await frames(8)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + name + ".png")
	state.reset()
	quit()
