extends SceneTree
## Captures de la grille de vues (views.json) : -- <groupe> [<groupe> ...]
## Écrit agents/hub/cap/<groupe>/<nom>.png.
const AGENT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/hub/"
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]

var level: Node
var camera: Camera3D
var loaded := -1


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func load_hub(books: int) -> void:
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	for index in books:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await frames(40)
	level = current_scene
	level.get_node("Hud").visible = false
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	if root.has_node("PauseMenu"):
		root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
		for child in root.get_node("PauseMenu").get_children():
			if child is CanvasItem or child is CanvasLayer:
				child.visible = false
	paused = false
	camera = Camera3D.new()
	camera.fov = 75.0
	camera.far = 500.0
	level.add_child(camera)
	camera.current = true
	loaded = books


func _run() -> void:
	var groups := OS.get_cmdline_user_args()
	var views: Array = JSON.parse_string(FileAccess.get_file_as_string(AGENT + "views.json"))
	for view: Dictionary in views:
		if not String(view.group) in groups:
			continue
		if int(view.books) != loaded:
			await load_hub(int(view.books))
		level.call("_set_location", bool(view.inside))
		var out: String = AGENT + "cap/" + String(view.group) + "/"
		DirAccess.make_dir_recursive_absolute(out)
		var eye := Vector3(view.eye[0], view.eye[1], view.eye[2])
		var target := Vector3(view.target[0], view.target[1], view.target[2])
		camera.global_position = eye
		var up := Vector3.FORWARD if absf((target - eye).normalized().y) > 0.98 else Vector3.UP
		camera.look_at(target, up)
		await frames(5)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + String(view.name) + ".png")
	root.get_node("GameState").reset()
	quit()
