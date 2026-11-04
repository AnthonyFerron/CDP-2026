extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/sheets.gd"
## Sonde : la boule sombre autour du trébuchet, au bout de 8 s, avec et sans sa fumée, son feu, la lumière du feu.


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	space = level.get_world_3d().direct_space_state
	player.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("Hud").visible = false
	camera = Camera3D.new()
	level.add_child(camera)
	camera.current = true
	var eye: Vector3 = _eye(-22.0, 39.0, 30.0, -15.0, true)
	for i in 480:
		paused = false
		await process_frame
	var smoke: CPUParticles3D = level.get_node("Exterior/Ambience/TrebuchetSmoke")
	var fire: Node3D = level.get_node("Exterior/Ambience/BurningTrebuchet")
	print("fumée : particules dans ", smoke.capture_aabb(), " ; enfants du feu : ", fire.get_children())
	var out := OUT + "fumee_"
	(await _shoot(eye, -90.0, -6.0, 62.0)).save_png(out + "a_tout.png")
	smoke.visible = false
	(await _shoot(eye, -90.0, -6.0, 62.0)).save_png(out + "b_sans_fumee.png")
	smoke.visible = true
	for child in fire.get_children():
		if child is Light3D:
			(child as Light3D).visible = false
	(await _shoot(eye, -90.0, -6.0, 62.0)).save_png(out + "c_sans_lumiere.png")
	fire.visible = false
	(await _shoot(eye, -90.0, -6.0, 62.0)).save_png(out + "d_sans_feu.png")
	finish()
