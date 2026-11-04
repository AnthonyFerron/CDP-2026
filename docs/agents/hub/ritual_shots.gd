extends SceneTree
## Captures du rituel : trois livres posés, le quatrième en main ; on le pose et on photographie la scène
## à intervalles réguliers, depuis la caméra courante (rituel, puis cinématique).
const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/hub/ritual/"


func _initialize() -> void:
	_run.call_deferred()


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	state.books.assign([&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"])
	state.placed_books.assign([&"projenomicon", &"algonicon", &"logiconomicon"])
	state.last_zone = &"village"
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	for i in 40:
		await process_frame
	var level: Node = current_scene
	var player: Node3D = level.get_node("Player")
	player.global_position = Vector3(5.0, 0.4, -79.0)
	await process_frame
	await shot("0_avant")
	level.get_node("Castle/Pedestals/Village").interact()
	var times := [1.5, 3.0, 4.5, 5.5, 6.5, 7.5, 9.0, 11.0]
	var close := Camera3D.new()
	close.fov = 60.0
	level.add_child(close)
	var elapsed := 0.0
	for index in times.size():
		await create_timer(times[index] - elapsed).timeout
		elapsed = times[index]
		await shot("%d_%.1fs" % [index + 1, elapsed])
		if elapsed < 7.0:
			var merlon: Node3D = level.get_node("Characters/Merlon")
			var previous := level.get_viewport().get_camera_3d()
			close.global_position = merlon.global_position + merlon.global_basis.z * 3.2 + Vector3.UP * 1.6
			close.look_at(merlon.global_position + Vector3.UP * 1.3)
			close.current = true
			await process_frame
			await process_frame
			await shot("merlon_%.1fs" % elapsed)
			if previous:
				previous.current = true
	quit()
