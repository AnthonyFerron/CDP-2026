extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Diagnostic de la sortie de carte vers 15° : trajectoire du joueur, image par image autour de la chute.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	var terrain: PlaineTerrain = level.get_node("Exterior/Terrain")
	var pivot: Node3D = player.get_node("CameraPivot")
	var angle := TAU * 1 / 24
	var direction := Vector2.from_angle(angle)
	var start := direction * 56.0
	player.global_position = Vector3(start.x, terrain.surface_height(start.x, start.y) + 0.3, start.y)
	player.velocity = Vector3.ZERO
	await wait(5)
	Input.action_press("move_forward")
	Input.action_press("sprint")
	var trail: Array[String] = []
	for frame in 600:
		var heading := angle
		if frame > 300:
			heading += 0.9 if frame < 450 else -0.9
		var aim := Vector2.from_angle(heading)
		pivot.rotation.y = atan2(-aim.x, -aim.y)
		if frame % 24 == 0:
			Input.action_press("jump")
		elif frame % 24 == 2:
			Input.action_release("jump")
		await physics_frame
		var p := player.global_position
		var ground := terrain.surface_height(p.x, p.z)
		trail.append("%d : %s r=%.2f sol %.2f sol? %s mode %d" % [frame, p.snappedf(0.01), Vector2(p.x, p.z).length(), ground,
			player.is_on_floor(), player.process_mode])
		if p.y < ground - 1.0:
			print("SOUS LE SOL à l'image %d" % frame)
			for line in trail.slice(maxi(0, trail.size() - 25)):
				print("  " + line)
			break
	Input.action_release("move_forward")
	Input.action_release("sprint")
	finish()
