extends SceneTree
## Galerie de modèles : arguments « nom kit/modele ... », alignés et photographiés de face (+Z) et de dos.
const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/gallery/"
const STEP := 2.6


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var args := OS.get_cmdline_user_args()
	var prefix: String = args[0]
	var models := args.slice(1)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.6, 0.8)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	world.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	world.add_child(ground)
	for index in models.size():
		var node: Node3D = load("res://assets/models/kenney/%s.glb" % models[index]).instantiate()
		node.position = Vector3(index * STEP, 0, 0)
		node.scale = Vector3.ONE * 2.4
		world.add_child(node)
		var label := Label3D.new()
		label.text = models[index].get_file()
		label.pixel_size = 0.003
		label.position = Vector3(index * STEP, 2.2, 0)
		world.add_child(label)
	var camera := Camera3D.new()
	world.add_child(camera)
	var middle := (models.size() - 1) * STEP * 0.5
	for side in [1, -1]:
		camera.position = Vector3(middle, 2.6, side * (models.size() * STEP * 0.4 + 1.0))
		camera.look_at(Vector3(middle, 0.9, 0))
		camera.current = true
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + prefix + ("_face" if side > 0 else "_dos") + ".png")
	quit()
