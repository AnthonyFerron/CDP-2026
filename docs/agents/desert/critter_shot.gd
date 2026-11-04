extends SceneTree
## Captures au plus près de quelques lézards et scorpions de desert_life.gd, là où ils se trouvent.
const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/life/"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.reset()
	change_scene_to_file("res://scenes/levels/desert/desert.tscn")
	for i in 90:
		await process_frame
	var level: Node = current_scene
	level.get_node("Hud").visible = false
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	var camera := Camera3D.new()
	camera.fov = 50.0
	level.add_child(camera)
	camera.current = true
	var critters: Array = level.get_node("Exterior/Life").get("_critters")
	for index in [0, 2, 4, 7]:
		var node: Node3D = critters[index].node
		var spot := node.global_position
		camera.global_position = spot + Vector3(1.1, 0.8, 1.1)
		camera.look_at(spot + Vector3.UP * 0.05)
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "bete_%d.png" % index)
	state.reset()
	quit()
