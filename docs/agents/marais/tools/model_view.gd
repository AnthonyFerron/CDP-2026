extends SceneTree
## Vue d'un modèle sous plusieurs angles : -- kit/modele sortie distance hauteur
const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/gallery/"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
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
	var node: Node3D = load("res://assets/models/kenney/%s.glb" % args[0]).instantiate()
	world.add_child(node)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	var d := float(args[2])
	var h := float(args[3])
	var views := {"px": Vector3(d, h, 0), "nx": Vector3(-d, h, 0), "pz": Vector3(0, h, d), "nz": Vector3(0, h, -d), "diag": Vector3(d, h * 1.5, d) * 0.8}
	for key in views:
		camera.position = views[key]
		camera.look_at(Vector3(0, h * 0.4, 0))
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + args[1] + "_" + key + ".png")
	quit()
