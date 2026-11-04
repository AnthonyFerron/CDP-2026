extends SceneTree
## Poses des animations d'un personnage : -- <kit/modele> <sortie> anim1 anim2 ...
const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/hub/gallery/"


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
	var anims := args.slice(2)
	for index in anims.size():
		var node: Node3D = load("res://assets/models/kenney/%s.glb" % args[0]).instantiate()
		node.position = Vector3(index * 0.9, 0, 0)
		world.add_child(node)
		var player: AnimationPlayer = node.find_children("*", "AnimationPlayer", true, false)[0]
		player.play(anims[index])
		player.seek(0.4, true)
		player.pause()
		var label := Label3D.new()
		label.text = anims[index]
		label.pixel_size = 0.0015
		label.position = Vector3(index * 0.9, 1.0, 0)
		world.add_child(label)
	var camera := Camera3D.new()
	world.add_child(camera)
	var middle := (anims.size() - 1) * 0.45
	for side in ["face", "profil"]:
		if side == "face":
			camera.position = Vector3(middle, 0.55, anims.size() * 0.3 + 0.5)
		else:
			camera.position = Vector3(middle + anims.size() * 0.35 + 0.6, 0.55, anims.size() * 0.12 + 0.5)
		camera.look_at(Vector3(middle, 0.35, 0))
		camera.current = true
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + args[1] + "_" + side + ".png")
	quit()
