extends SceneTree
## Captures du hub depuis des caméras libres :
## -- <dossier> books=<n> [noshadow] [inside|outside] [debug] <nom>=x,y,z:tx,ty,tz[:taille_ortho] ...
## books=<n> recharge le hub avec n livres posés (0 à 4) ; inside/outside bascule sur le bunker.
const BASE := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/"
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]

var level: Node
var camera: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func vec(text: String) -> Vector3:
	var p := text.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


func load_hub(books: int, found := -1) -> void:
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	for index in books:
		state.placed_books.append(ALL[index])
	for index in maxi(found, books):
		state.books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await frames(40)
	level = current_scene
	level.get_node("Hud").visible = false
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	# Le menu de pause s'ouvre quand la fenêtre perd la souris : on le neutralise pour les captures.
	if root.has_node("PauseMenu"):
		root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
		for child in root.get_node("PauseMenu").get_children():
			if child is CanvasItem or child is CanvasLayer:
				child.visible = false
	get_root().get_tree().paused = false
	camera = Camera3D.new()
	camera.fov = 75.0
	camera.far = 500.0
	level.add_child(camera)
	camera.current = true


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := BASE + args[0] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	await load_hub(0)
	for entry in args.slice(1):
		# --api=… : l'adresse morte du serveur, lue par Api, pas une vue.
		if entry.begins_with("--"):
			continue
		if entry.begins_with("books="):
			await load_hub(int(entry.substr(6)))
			continue
		# ash=<posés> : les quatre livres trouvés, une partie seulement posée (ciel de cendres).
		if entry.begins_with("ash="):
			await load_hub(int(entry.substr(4)), 4)
			continue
		if entry == "repaircam":
			level.get_node("RepairCamera").current = true
			await frames(8)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out + "repaircam.png")
			camera.current = true
			continue
		if entry == "noshadow":
			level.get_node("Sun").shadow_enabled = false
			continue
		if entry == "nofog":
			level.get_node("WorldEnvironment").environment.fog_enabled = false
			continue
		if entry == "debug":
			debug_collisions_hint = true
			continue
		if entry == "inside" or entry == "outside":
			level.call("_set_location", entry == "inside")
			await frames(4)
			continue
		if entry == "survivors":
			level.call("_release_survivors")
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
	root.get_node("GameState").reset()
	quit()
