extends SceneTree
## Planches de captures à hauteur d'yeux : pour chaque point, 8 vues (tous les 45 degrés, légèrement plongeantes),
## deux points par planche de 4 × 4 vignettes. Arguments : dossier de sortie, puis des points « nom=x,z » (dehors,
## posés sur le sol) ou « nom=x,y,z » (hauteur des yeux donnée), « inside » pour passer dans la cave,
## « up » pour que les points suivants regardent aussi vers le plafond.

const BASE := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/"
const THUMB := Vector2i(320, 180)


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


## La fenêtre de capture peut perdre le focus : le menu de pause s'ouvrirait par-dessus la vue.
func _no_pause() -> void:
	var pause: Node = root.get_node_or_null("PauseMenu")
	if pause and pause.is_open():
		pause.close()
	paused = false


func _run() -> void:
	var args := PackedStringArray()
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			args.append(arg)
	var out := BASE + args[0] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	change_scene_to_file("res://scenes/levels/desert/desert.tscn")
	await frames(40)
	var level: Node = current_scene
	level.get_node("Hud").visible = false
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	var terrain: Node = level.get_node("Exterior/Terrain")
	var camera := Camera3D.new()
	camera.fov = 75.0
	level.add_child(camera)
	camera.current = true
	var sheet: Image
	var slot := 0
	var names: Array[String] = []
	var looking_up := false
	for entry in args.slice(1):
		if entry == "inside":
			level.set("_inside", true)
			level.call("_apply_location")
			await frames(6)
			continue
		if entry == "up":
			looking_up = true
			continue
		var name := entry.split("=")[0]
		var values := entry.split("=")[1].split(",")
		var spot: Vector3
		if values.size() == 2:
			var x := float(values[0])
			var z := float(values[1])
			spot = Vector3(x, terrain.surface_height(x, z) + 1.65, z)
		else:
			spot = Vector3(float(values[0]), float(values[1]), float(values[2]))
		names.append(name)
		for view in 8:
			if sheet == null:
				sheet = Image.create(THUMB.x * 4, THUMB.y * 4, false, Image.FORMAT_RGB8)
			var yaw := TAU * view / 8.0
			camera.global_position = spot
			var pitch := 0.9 if looking_up and view % 2 == 1 else -0.18
			camera.global_rotation = Vector3(pitch, yaw, 0.0)
			await frames(5)
			_no_pause()
			await frames(2)
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			image.resize(THUMB.x, THUMB.y, Image.INTERPOLATE_BILINEAR)
			image.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(image, Rect2i(Vector2i.ZERO, THUMB), Vector2i((slot % 4) * THUMB.x, (slot / 4) * THUMB.y))
			slot += 1
		if slot >= 16:
			sheet.save_png(out + "+".join(names) + ".png")
			sheet = null
			slot = 0
			names.clear()
	if sheet != null:
		sheet.save_png(out + "+".join(names) + ".png")
	state.reset()
	quit()
