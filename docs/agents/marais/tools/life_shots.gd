extends SceneTree
## Captures de la vie du Marais : une grenouille, un corbeau, une lanterne pendue, des ronds dans l'eau,
## des chauves-souris en vol, et les roseaux.
const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/life/"

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count:
		await process_frame

func shot(camera: Camera3D, name: String, from: Vector3, to: Vector3) -> void:
	camera.global_position = from
	camera.look_at(to)
	await frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var state: Node = root.get_node("GameState")
	state.reset()
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	await frames(40)
	var level: Node = current_scene
	level.get_node("Hud").visible = false
	var player: Node3D = level.get_node("Player")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var camera := Camera3D.new()
	level.add_child(camera)
	camera.current = true
	var life: Node = level.get_node("Life")
	var frog: Dictionary = life._frogs[0]
	var home: Vector3 = frog.home
	print("grenouille ", home, " corbeaux ", life._crows.size(), " chauves-souris ", life._bats.size())
	await shot(camera, "1_grenouille", home + Vector3(1.2, 0.7, 1.2), home + Vector3(0, 0.1, 0))
	var crow: Dictionary = life._crows[0]
	var seat: Vector3 = crow.seat
	await shot(camera, "2_corbeau", seat + Vector3(1.6, 0.6, 1.6), seat + Vector3(0, 0.2, 0))
	await shot(camera, "3_potence", Vector3(-13.5, 1.9, 27.5), Vector3(-15.6, 1.8, 25.6))
	player.global_position = Vector3(-5, 0.4, 40)
	for i in 300:
		await process_frame
	await shot(camera, "4_ronds", Vector3(-5, 2.2, 40), Vector3(-12, 0, 30))
	await shot(camera, "5_roseaux", Vector3(-24, 1.2, 15), Vector3(-30, 0.5, 10))
	level.set("_inside", true)
	level.call("_apply_location")
	player.global_position = Vector3(-18, -40, 2)
	for i in 50:
		await process_frame
	await shot(camera, "6_chauves_souris", Vector3(-15, -38.3, -0.5), Vector3(-18, -37.0, 2.5))
	state.reset()
	quit()
