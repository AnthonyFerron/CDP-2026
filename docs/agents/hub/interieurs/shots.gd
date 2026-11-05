extends SceneTree
## Captures du hub depuis des caméras libres, avec un nombre de livres posés :
##   -- <dossier> <livres> <fichier de vues>
## Fichier de vues : une ligne par capture, « nom x,y,z tx,ty,tz [ortho] ».
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count:
		await process_frame

func vec(text: String) -> Vector3:
	var p := text.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))

func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	var out := args[0] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var books := int(args[1])
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	state.intro_done = true
	for index in books:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await frames(40)
	var level: Node = current_scene
	level.get_node("Hud").visible = false
	var player: Node3D = level.get_node("Player")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.visible = false
	var camera := Camera3D.new()
	camera.fov = 75.0
	camera.near = 0.05
	camera.far = 500.0
	level.add_child(camera)
	camera.current = true
	var lines := FileAccess.get_file_as_string(args[2]).split("\n", false)
	# Planches de quatre vues (2 x 2, à demi-taille), pour les regarder par groupes.
	var sheet: Image
	var sheet_names: Array[String] = []
	var sheet_index := 0
	for line in lines:
		var parts := line.strip_edges().split(" ", false)
		if parts.size() < 3 or line.begins_with("#"):
			continue
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		if parts.size() > 3:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = float(parts[3])
		camera.global_position = vec(parts[1])
		# Le joueur suit la caméra, pour les scripts qui regardent où il est (lumières des intérieurs).
		player.global_position = camera.global_position - Vector3(0, 1.6, 0)
		var target := vec(parts[2])
		var up := Vector3.FORWARD if absf((target - camera.global_position).normalized().y) > 0.99 else Vector3.UP
		camera.look_at(target, up)
		await frames(10)
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png(out + parts[0] + ".png")
		var small := image.duplicate() as Image
		small.resize(640, 360, Image.INTERPOLATE_BILINEAR)
		if sheet == null:
			sheet = Image.create(1280, 720, false, small.get_format())
		var slot := sheet_names.size()
		sheet.blit_rect(small, Rect2i(0, 0, 640, 360), Vector2i((slot % 2) * 640, (slot / 2) * 360))
		sheet_names.append(parts[0])
		if sheet_names.size() == 4:
			sheet.save_png(out + "planche_%02d.png" % sheet_index)
			print("PLANCHE %02d : %s" % [sheet_index, " ".join(sheet_names)])
			sheet_index += 1
			sheet = null
			sheet_names.clear()
	if sheet != null:
		sheet.save_png(out + "planche_%02d.png" % sheet_index)
		print("PLANCHE %02d : %s" % [sheet_index, " ".join(sheet_names)])
	print("CAPTURES ", lines.size())
	state.reset()
	quit()
