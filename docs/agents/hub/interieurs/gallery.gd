extends SceneTree
## Galerie de modèles : -- <fichier png> <modele> ... ; quatre vues (+x, -z, -x, +z) de la rangée, en planche 2 x 2.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			args.append(a)
	var out: String = args[0]
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
		node.position = Vector3(0, 0, index * 1.6)
		world.add_child(node)
	var camera := Camera3D.new()
	world.add_child(camera)
	var middle := (models.size() - 1) * 0.8
	var sheet: Image
	var dirs := [Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 0, 1)]
	for k in 4:
		var d: Vector3 = dirs[k]
		var dist := 1.2 + models.size() * 0.9
		camera.position = Vector3(0, 0.9, middle) + d * dist + Vector3(0, 0.6, 0)
		camera.look_at(Vector3(0, 0.4, middle))
		camera.current = true
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.resize(640, 360)
		if sheet == null:
			sheet = Image.create(1280, 720, false, image.get_format())
		sheet.blit_rect(image, Rect2i(0, 0, 640, 360), Vector2i((k % 2) * 640, (k / 2) * 360))
	sheet.save_png(out)
	quit()
