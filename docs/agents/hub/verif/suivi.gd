extends SceneTree
## Captures des villageois pendant leur tournée, après la cinématique (départ du feu) : toutes les <pas> secondes de
## jeu, chacun vu de 3,5 m, de trois quarts arrière, à hauteur d'yeux. Les tournées avancent par appels de leur
## _process (1/60 s), sans rien d'autre : le joueur est loin, aucun ne s'arrête pour lui.
## Arguments : -- <dossier> <pas en secondes> <nombre de moments>
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			args.append(a)
	var out := args[0] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var step := float(args[1])
	var moments := int(args[2])
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	state.intro_done = true
	for index in 4:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	for i in 40:
		await process_frame
	var level: Node3D = current_scene
	level.get_node("Props").finish_all()
	level.get_node("Hud").visible = false
	var player: Node3D = level.get_node("Player")
	player.set_physics_process(false)
	player.set_process(false)
	player.set_process_unhandled_input(false)
	player.visible = false
	player.global_position = Vector3(0, 400, 0)
	var villagers: Node = level.get_node("Villagers")
	villagers.stop()
	level.call("_release_survivors")
	villagers.start(true)
	villagers.set_process(false)
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.near = 0.05
	level.add_child(camera)
	camera.current = true
	var walkers: Array = villagers.get("_walkers")
	for moment in moments:
		for walker in walkers:
			var node: Node3D = walker.node
			var back := -node.global_basis.z.normalized()
			var side := node.global_basis.x.normalized()
			camera.global_position = node.global_position + back * 2.8 + side * 2.0 + Vector3(0, 1.7, 0)
			camera.look_at(node.global_position + Vector3(0, 0.9, 0))
			for i in 3:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out + "%s_%03ds.png" % [node.name, roundi(moment * step)])
		print("MOMENT %d : %s" % [moment, " ; ".join(villagers.describe())])
		for i in roundi(step * 60.0):
			villagers._process(1.0 / 60.0)
	state.reset()
	quit()
