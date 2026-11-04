extends SceneTree
## Vue de dessus et de face de modèles à l'échelle 1, posés à leur origine sur un damier de 10 cm, avec en rouge la
## boîte écrite (argument « kit/modele=cx,cy,cz,sx,sy,sz ») : on voit laquelle des deux mesures est juste.
const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/gallery/"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.2, 0.2, 0.25)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 30, 0)
	world.add_child(sun)
	var args := OS.get_cmdline_user_args()
	var spacing := 2.5
	for index in args.size():
		var spec := args[index].split("=")
		var x := index * spacing
		for i in 21:
			for j in 31:
				if (i + j) % 2 == 0:
					var tile := MeshInstance3D.new()
					var plane := PlaneMesh.new()
					plane.size = Vector2(0.1, 0.1)
					tile.mesh = plane
					tile.position = Vector3(x - 1.0 + i * 0.1 + 0.05, -0.001, -2.0 + j * 0.1 + 0.05)
					world.add_child(tile)
		var node: Node3D = load("res://assets/models/kenney/%s.glb" % spec[0]).instantiate()
		node.position = Vector3(x, 0, 0)
		world.add_child(node)
		var v := spec[1].split(",")
		var box := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(float(v[3]), float(v[4]), float(v[5]))
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(1, 0, 0, 0.25)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material = material
		box.mesh = mesh
		box.position = Vector3(x + float(v[0]) + mesh.size.x / 2, float(v[1]) + mesh.size.y / 2, float(v[2]) + mesh.size.z / 2)
		world.add_child(box)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = args.size() * spacing * 0.6 + 1.0
	world.add_child(camera)
	var middle := (args.size() - 1) * spacing * 0.5
	camera.position = Vector3(middle, 10, -0.5)
	camera.look_at(Vector3(middle, 0, -0.5), Vector3.FORWARD)
	camera.current = true
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "boxes_top.png")
	camera.position = Vector3(middle, 0.4, 6)
	camera.look_at(Vector3(middle, 0.4, 0))
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "boxes_side.png")
	quit()
