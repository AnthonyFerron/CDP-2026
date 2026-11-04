extends SceneTree
## Grille de captures des marais, à hauteur d'yeux (1,65 m) : en chaque point, 8 directions et une vue vers le
## haut, réunies en une planche de 3 × 3 (N, NE, E / SE, S, SO / O, NO, haut). Points tous les 6 à 7 m sur les îlots
## du parcours et le long des pontons ; dans chaque pièce de la crypte.
## Usage : -- dehors | crypte [dossier de sortie relatif à agents/marais]

const BASE := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/"
const TILE := Vector2i(426, 240)

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count:
		await process_frame

func points_outside() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for area: Vector4 in [Vector4(0, 56, 11, 7), Vector4(-20, 22, 6, 4), Vector4(16, 0, 13, 6), Vector4(0, -36, 11, 6)]:
		var x := area.x - area.z
		while x <= area.x + area.z + 0.01:
			var z := area.y - area.z
			while z <= area.y + area.z + 0.01:
				if Vector2(x - area.x, z - area.y).length() <= area.z + 0.01:
					points.append(Vector2(x, z))
				z += area.w
			x += area.w
	for walk: Vector4 in [Vector4(-3, 48, -18, 27), Vector4(-16, 19, 6, 4), Vector4(8.5, -10, 3, -28)]:
		for t in [0.25, 0.5, 0.75]:
			points.append(Vector2(walk.x, walk.y).lerp(Vector2(walk.z, walk.w), t))
	points.append(Vector2(13.6, 51.4))
	return points

func points_crypt() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for x in [-6.0, 0.0, 6.0]:
		for z in [-5.0, -12.0, -19.0]:
			points.append(Vector2(x, z))
	for p in [Vector2(-12, -12), Vector2(-16, -12), Vector2(12, -12), Vector2(16, -12), Vector2(-21, -12), Vector2(-27, -12),
			Vector2(-24, -7.8), Vector2(-24, -16.2), Vector2(21, -12), Vector2(27, -12), Vector2(24, -8), Vector2(24, -16),
			Vector2(-12, -4), Vector2(-12, 0), Vector2(-19, 0), Vector2(-17, 4), Vector2(12, -4), Vector2(12, 0), Vector2(18, -0.5),
			Vector2(18, 3.2), Vector2(0, 0), Vector2(0, 6), Vector2(0, 11.5)]:
		points.append(p)
	return points

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var zone: String = args[0]
	var out := BASE + (args[1] if args.size() > 1 else "grid") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var state: Node = root.get_node("GameState")
	state.reset()
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	await frames(40)
	var level: Node = current_scene
	root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("Hud").visible = false
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("Player").visible = false
	var inside := zone == "crypte"
	level.set("_inside", inside)
	level.call("_apply_location")
	var camera := Camera3D.new()
	camera.fov = 75.0
	level.add_child(camera)
	camera.current = true
	await frames(10)
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	var points := points_crypt() if inside else points_outside()
	var index := 0
	for p in points:
		var top := (-40.0 + (8.0 if absf(p.x) < 1.6 and p.y > 2.0 else 3.9)) if inside else 8.0
		var ray := PhysicsRayQueryParameters3D.create(Vector3(p.x, top, p.y), Vector3(p.x, top - 12.0, p.y))
		var hit := space.intersect_ray(ray)
		var floor_y: float = hit.position.y if not hit.is_empty() else (-40.0 if inside else 0.4)
		# Dehors, l'œil reste au-dessus de l'eau même là où le fond est profond.
		if not inside:
			floor_y = maxf(floor_y, 0.0)
		var eye := Vector3(p.x, floor_y + 1.65, p.y)
		var mosaic := Image.create(TILE.x * 3, TILE.y * 3, false, Image.FORMAT_RGB8)
		for view in 9:
			camera.global_position = eye
			if view < 8:
				camera.rotation = Vector3(deg_to_rad(-8.0), -TAU * view / 8.0, 0.0)
			else:
				camera.rotation = Vector3(deg_to_rad(80.0), 0.0, 0.0)
			await frames(3)
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			image.resize(TILE.x, TILE.y)
			image.convert(Image.FORMAT_RGB8)
			mosaic.blit_rect(image, Rect2i(Vector2i.ZERO, TILE), Vector2i((view % 3) * TILE.x, (view / 3) * TILE.y))
		mosaic.save_png(out + "%s_%02d_%d_%d.png" % [zone, index, roundi(p.x), roundi(p.y)])
		index += 1
	print("PLANCHES %d" % index)
	state.reset()
	quit()
