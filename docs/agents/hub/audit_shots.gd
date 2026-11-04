extends SceneTree
## Captures des interactables depuis les points de vue trouvés par hub_audit.gd :
## -- <livres> <premier> <nombre>  (lit audit_<livres>.json, écrit dans audit_shots_<livres>/)
const AGENT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/hub/"
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var books := int(args[0])
	var first := int(args[1])
	var count := int(args[2])
	var out := AGENT + "audit_shots_%d/" % books
	DirAccess.make_dir_recursive_absolute(out)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	for index in books:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	for i in 40:
		await process_frame
	var level: Node = current_scene
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("Hud").visible = false
	var camera := Camera3D.new()
	camera.fov = 70.0
	level.add_child(camera)
	camera.current = true
	var views: Array = JSON.parse_string(FileAccess.get_file_as_string(AGENT + "audit_%d.json" % books))
	for view: Dictionary in views.slice(first, first + count):
		var eye := Vector3(view.eye[0], view.eye[1], view.eye[2])
		var target := Vector3(view.target[0], view.target[1], view.target[2])
		var inside: bool = eye.y < -20.0
		level.call("_set_location", inside)
		camera.global_position = eye
		camera.look_at(target)
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + String(view.name) + ".png")
	state.reset()
	quit()
