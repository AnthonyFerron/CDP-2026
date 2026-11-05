extends SceneTree
## Captures du Marais à comparer : -- <dossier> [freeze] [noshadow] [nom=x,y,z:tx,ty,tz | nom=in:x,y,z:tx,ty,tz] ...
## freeze : fige ce qui bouge au hasard (particules, feux follets, bêtes, scintillement des lumières, eau), pour
## comparer pixel à pixel le décor fixe avant et après.

func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func vec(text: String) -> Vector3:
	var p := text.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	var out: String = args[0] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	await frames(40)
	var level: Node = current_scene
	root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
	paused = false
	level.get_node("Hud").visible = false
	var player: Node3D = level.get_node("Player")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.visible = false
	var camera := Camera3D.new()
	camera.fov = 75.0
	level.add_child(camera)
	camera.current = true
	var inside := false
	for entry: String in args.slice(1):
		if entry == "freeze":
			for node in level.find_children("*", "GeometryInstance3D", true, false):
				if node is CPUParticles3D or node is GPUParticles3D:
					node.visible = false
			for node in level.find_children("*", "Light3D", true, false):
				if "flicker" in node:
					node.set("flicker", 0.0)
			level.get_node("Wisps").visible = false
			level.get_node("Life").visible = false
			level.get_node("Life").process_mode = Node.PROCESS_MODE_DISABLED
			level.get_node("Ghost").process_mode = Node.PROCESS_MODE_DISABLED
			level.set_process(false)
			Engine.time_scale = 0.0
			continue
		if entry == "noshadow":
			level.get_node("Moon").shadow_enabled = false
			continue
		var name := entry.split("=")[0]
		var spec := entry.split("=")[1]
		var want_inside := spec.begins_with("in:")
		if want_inside:
			spec = spec.substr(3)
		if want_inside != inside:
			inside = want_inside
			level.set("_inside", inside)
			level.call("_apply_location")
			await frames(4)
		var parts := spec.split(":")
		camera.global_position = vec(parts[0])
		camera.look_at(vec(parts[1]), Vector3.UP)
		player.global_position = camera.global_position - Vector3.UP * 1.65
		await frames(6)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + name + ".png")
	Engine.time_scale = 1.0
	state.reset()
	quit()
