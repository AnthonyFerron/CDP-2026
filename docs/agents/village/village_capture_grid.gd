extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Passe au centimètre : grille de captures à hauteur d'yeux, à regarder sur des planches contact.
## -- dehors <pas> [xmin xmax zmin zmax]  : un point tous les <pas> mètres, 4 directions (champ de 90 degrés) ;
## -- dedans                              : la mairie tous les 2 m sur chaque étage, coins, plafonds, salle secrète.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/village/grid/"

var camera: Camera3D
var space: PhysicsDirectSpaceState3D
var capsule := CapsuleShape3D.new()
var count := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := Array(OS.get_cmdline_user_args()).filter(func(arg: String) -> bool: return not arg.begins_with("--"))
	await start_level("res://scenes/levels/village/village.tscn")
	for name in ["PauseMenu", "Pause"]:
		if root.has_node(name):
			root.get_node(name).process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("Hud").visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	space = player.get_world_3d().direct_space_state
	capsule.radius = 0.38
	capsule.height = 1.8
	camera = Camera3D.new()
	camera.fov = 90.0
	camera.far = 300.0
	level.add_child(camera)
	camera.current = true
	DirAccess.make_dir_recursive_absolute(OUT)
	if args[0] == "vues":
		# -- vues <dossier> nom ex ey ez cx cy cz [nom ...] : vues précises (gros plans des jointures, avant/après).
		var folder: String = args[1]
		DirAccess.make_dir_recursive_absolute(folder)
		var index := 2
		while index + 6 < args.size():
			var eye := Vector3(float(args[index + 1]), float(args[index + 2]), float(args[index + 3]))
			var target := Vector3(float(args[index + 4]), float(args[index + 5]), float(args[index + 6]))
			await shot(args[index], eye, target, folder)
			index += 7
	elif args[0] == "dehors":
		var step := float(args[1])
		var bounds := Rect2(-36, -38, 72, 88) if args.size() < 6 else Rect2(float(args[2]), float(args[4]), float(args[3]) - float(args[2]), float(args[5]) - float(args[4]))
		var z := bounds.position.y
		while z <= bounds.end.y:
			var x := bounds.position.x
			while x <= bounds.end.x:
				var foot := ground(Vector3(x, 30, z))
				if not is_nan(foot.y) and fits_here(foot):
					await four("d_%+04d_%+04d" % [int(x), int(z)], foot + Vector3.UP * 1.65)
				x += step
			z += step
	else:
		level.set("_inside", true)
		level.call("_apply_location")
		for floor_y in [-40.0, -35.5]:
			var z := -5.0
			while z <= 5.0:
				var x := -7.0
				while x <= 7.0:
					var foot := ground(Vector3(x, floor_y + 1.0, z))
					if not is_nan(foot.y) and absf(foot.y - floor_y) < 0.3 and fits_here(foot):
						await four("i%d_%+03d_%+03d" % [int(floor_y + 40.0), int(x), int(z)], foot + Vector3.UP * 1.65)
					x += 2.0
				z += 2.0
			# Coins de la pièce et plafond vu d'en dessous.
			for corner: Vector2 in [Vector2(-7, -5), Vector2(7, -5), Vector2(7, 5), Vector2(-7, 5)]:
				await shot("coin%d_%+d_%+d" % [int(floor_y + 40.0), int(corner.x), int(corner.y)],
					Vector3(-corner.x * 0.6, floor_y + 1.65, -corner.y * 0.6), Vector3(corner.x, floor_y + 0.8, corner.y))
			await shot("plafond%d" % int(floor_y + 40.0), Vector3(0, floor_y + 1.65, 0.5), Vector3(0.5, floor_y + 6.0, 0))
		level.call("_on_codes_solved")
		for i in 240:
			await physics_frame
		for spot: Vector2 in [Vector2(-10, -2), Vector2(-14, 2), Vector2(-12, 0)]:
			await four("secret_%+d_%+d" % [int(spot.x), int(spot.y)], Vector3(spot.x, -35.5 + 1.65, spot.y))
		await shot("plafond_secret", Vector3(-12, -33.85, 0.5), Vector3(-11.5, -30, 0))
	print("%d captures" % count)
	finish()


func ground(point: Vector3) -> Vector3:
	var ray := PhysicsRayQueryParameters3D.create(point, point + Vector3.DOWN * 60.0)
	ray.exclude = [player.get_rid()]
	var hit := space.intersect_ray(ray)
	return hit.position if hit else Vector3(point.x, NAN, point.z)


func fits_here(foot: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, foot + Vector3.UP * 1.05)
	query.exclude = [player.get_rid()]
	return space.intersect_shape(query, 1).is_empty()


func four(name: String, eye: Vector3) -> void:
	for index in 4:
		var angle := index * PI / 2.0
		await shot("%s_%d" % [name, index], eye, eye + Vector3(sin(angle), -0.12, cos(angle)))


func shot(name: String, eye: Vector3, target: Vector3, folder := "") -> void:
	var menu := root.get_node_or_null("PauseMenu")
	if menu and menu.has_method("is_open") and menu.is_open():
		menu.close()
	paused = false
	camera.global_position = eye
	camera.look_at(target, Vector3.UP if absf((target - eye).normalized().y) < 0.98 else Vector3.FORWARD)
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png((folder.path_join(name) if folder else OUT + name) + ".png")
	count += 1
