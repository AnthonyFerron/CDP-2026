extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Limite des plaines d'Hexcole : dans 24 directions, le joueur part de l'intérieur de la zone, court vers le bord en
## sautant sans cesse, puis longe le bord ; il ne doit jamais dépasser la limite ni tomber hors du monde.

const DIRECTIONS := 24
const FRAMES := 600


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	var terrain: PlaineTerrain = level.get_node("Exterior/Terrain")
	var scatter: PlaineScatter = level.get_node("Exterior/Scatter")
	var pivot: Node3D = player.get_node("CameraPivot")
	var limit := PlaineTerrain.LIMIT_RADIUS
	# « ++ sans_limite » retire le mur invisible, pour voir par où l'on sortait avant lui.
	if OS.get_cmdline_user_args().has("sans_limite"):
		for shape in terrain.get_children():
			if shape.name.begins_with("Limit"):
				shape.free()
		limit = PlaineTerrain.PLAY_RADIUS + PlaineTerrain.BORDER_WIDTH
		await wait(2)
	for index in DIRECTIONS:
		var angle := TAU * index / DIRECTIONS
		var direction := Vector2.from_angle(angle)
		# Départ à 56 m du centre, déplacé s'il tombe dans la lave ou dans un rocher.
		var start := direction * 56.0
		var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.45
		capsule.height = 1.9
		for attempt in 16:
			var ground := terrain.surface_height(start.x, start.y)
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis(), Vector3(start.x, ground + 1.1, start.y))
			query.exclude = [player.get_rid()]
			if not scatter.is_near_lava(Vector3(start.x, 0.0, start.y), 1.5) and space.intersect_shape(query, 1).is_empty():
				break
			start = direction.rotated(0.04 * (attempt + 1) * (1 if attempt % 2 else -1)) * (56.0 - attempt * 0.5)
		player.global_position = Vector3(start.x, terrain.surface_height(start.x, start.y) + 0.3, start.y)
		player.velocity = Vector3.ZERO
		player.process_mode = Node.PROCESS_MODE_INHERIT
		await wait(5)
		var farthest := 0.0
		var lowest := INF
		Input.action_press("move_forward")
		Input.action_press("sprint")
		for frame in FRAMES:
			# D'abord droit vers le bord, puis en biais le long du bord, dans les deux sens.
			var heading := angle
			if frame > FRAMES * 0.5:
				heading += 0.9 if frame < FRAMES * 0.75 else -0.9
			var aim := Vector2.from_angle(heading)
			pivot.rotation.y = atan2(-aim.x, -aim.y)
			if frame % 24 == 0:
				Input.action_press("jump")
			elif frame % 24 == 2:
				Input.action_release("jump")
			await physics_frame
			if player.process_mode == Node.PROCESS_MODE_DISABLED:
				# La lave l'a renvoyé en arrière : on le relâche aussitôt.
				await wait(80)
				player.process_mode = Node.PROCESS_MODE_INHERIT
			farthest = maxf(farthest, Vector2(player.global_position.x, player.global_position.z).length())
			lowest = minf(lowest, player.global_position.y)
		Input.action_release("move_forward")
		Input.action_release("sprint")
		Input.action_release("jump")
		await wait(3)
		check("direction %d° : au plus loin %.1f m (limite %.1f), plus bas %.1f m" % [
			roundi(rad_to_deg(angle)), farthest, limit, lowest], farthest < limit and lowest > -20.0)
	finish()
