extends "res://tests/scenes/common_test.gd"
## Bords des plaines d'Hexcole, dehors et dans les archives : le joueur longe chaque bord en marchant puis en
## courant et en sautant sans cesse, appuyé contre lui (25° vers l'extérieur), dans les deux sens. Il ne doit jamais
## passer la limite, sortir des murs des archives, ni tomber hors du monde.
## « ++ dehors » : tous les 7,5° du cercle de la limite. « ++ dedans » : le long de chaque mur des salles, du
## passage et de la petite salle (dalle ouverte).

const STEP_FRAMES := 260

var pivot: Node3D
var escapes: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	pivot = player.get_node("CameraPivot")
	if OS.get_cmdline_user_args().has("dedans"):
		await _inside()
	else:
		await _outside()
	for line in escapes:
		print("SORTIE " + line)
	check("aucune sortie (%d)" % escapes.size(), escapes.is_empty())
	finish()


func _drive(start: Vector3, heading_of: Callable, jump: bool, frames: int, inside_check: Callable, label: String) -> void:
	player.global_position = start
	player.velocity = Vector3.ZERO
	player.process_mode = Node.PROCESS_MODE_INHERIT
	await wait(3)
	Input.action_press("move_forward")
	if jump:
		Input.action_press("sprint")
	var worst := ""
	for frame in frames:
		var aim: Vector2 = heading_of.call(Vector2(player.global_position.x, player.global_position.z))
		pivot.rotation.y = atan2(-aim.x, -aim.y)
		if jump and frame % 20 == 0:
			Input.action_press("jump")
		elif jump and frame % 20 == 2:
			Input.action_release("jump")
		await physics_frame
		if player.process_mode == Node.PROCESS_MODE_DISABLED:
			await wait(80)
			player.process_mode = Node.PROCESS_MODE_INHERIT
		var problem: String = inside_check.call(player.global_position)
		if problem != "" and worst == "":
			worst = problem
	Input.action_release("move_forward")
	Input.action_release("sprint")
	Input.action_release("jump")
	await wait(2)
	if worst != "":
		escapes.append("%s : %s" % [label, worst])
		print("  ! %s : %s" % [label, worst])


func _outside() -> void:
	var terrain: PlaineTerrain = level.get_node("Exterior/Terrain")
	var limit := PlaineTerrain.LIMIT_RADIUS
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.9
	var check_out := func(p: Vector3) -> String:
		var r := Vector2(p.x, p.z).length()
		if r > limit - 0.4:
			return "à %.1f m du centre en (%.1f ; %.1f ; %.1f)" % [r, p.x, p.y, p.z]
		if p.y < terrain.surface_height(p.x, p.z) - 1.5:
			return "sous le sol en (%.1f ; %.1f ; %.1f)" % [p.x, p.y, p.z]
		return ""
	var runs := 0
	for index in 48:
		var angle := TAU * index / 48.0
		for sense: float in [1.0, -1.0]:
			for jump: bool in [false, true]:
				var start := Vector2.from_angle(angle) * 64.6
				for attempt in 12:
					var query := PhysicsShapeQueryParameters3D.new()
					query.shape = capsule
					query.transform = Transform3D(Basis(), Vector3(start.x, terrain.surface_height(start.x, start.y) + 1.1, start.y))
					query.exclude = [player.get_rid()]
					if space.intersect_shape(query, 1).is_empty():
						break
					start = Vector2.from_angle(angle + 0.01 * (attempt + 1) * sense) * (64.6 - attempt * 0.6)
				var heading := func(p: Vector2) -> Vector2:
					var radial: Vector2 = p.normalized()
					var tangent: Vector2 = Vector2(-radial.y, radial.x) * float(sense)
					return (tangent * cos(deg_to_rad(25.0)) + radial * sin(deg_to_rad(25.0))).normalized()
				var label := "dehors %.1f° %s %s" % [rad_to_deg(angle), "+" if sense > 0 else "-", "course et saut" if jump else "marche"]
				await _drive(Vector3(start.x, terrain.surface_height(start.x, start.y) + 0.3, start.y), heading, jump,
					STEP_FRAMES if jump else STEP_FRAMES / 2 * 3, check_out, label)
				runs += 1
	print("dehors : %d parcours" % runs)


func _inside() -> void:
	var stone: Node3D = level.get_node("Interior/Stone")
	stone.position.x -= level.stone_travel
	await wait(2)
	var base := -40.0
	var check_in := func(p: Vector3) -> String:
		var crypt := p.z < -36.3
		var half := 2.0 if crypt else 6.0
		if absf(p.x) > half + 0.2 or p.z > 0.2 or p.z < -44.2 or p.y < base - 1.6 or p.y > base + 4.2:
			return "en (%.2f ; %.2f ; %.2f)" % [p.x, p.y - base, p.z]
		return ""
	# Segments le long des murs : départ, direction de marche, normale vers le mur.
	var segments := [
		[Vector2(-5.4, -0.8), Vector2(0, -1), Vector2(-1, 0)], [Vector2(-5.4, -35.4), Vector2(0, 1), Vector2(-1, 0)],
		[Vector2(5.4, -0.8), Vector2(0, -1), Vector2(1, 0)], [Vector2(5.4, -35.4), Vector2(0, 1), Vector2(1, 0)],
		[Vector2(-5.4, -0.7), Vector2(1, 0), Vector2(0, 1)], [Vector2(5.4, -0.7), Vector2(-1, 0), Vector2(0, 1)],
		[Vector2(-5.4, -11.4), Vector2(1, 0), Vector2(0, -1)], [Vector2(5.4, -12.6), Vector2(-1, 0), Vector2(0, 1)],
		[Vector2(-5.4, -23.4), Vector2(1, 0), Vector2(0, -1)], [Vector2(5.4, -24.6), Vector2(-1, 0), Vector2(0, 1)],
		[Vector2(-5.4, -35.4), Vector2(1, 0), Vector2(0, -1)], [Vector2(5.4, -35.4), Vector2(-1, 0), Vector2(0, -1)],
		[Vector2(-1.4, -39.0), Vector2(0, -1), Vector2(-1, 0)], [Vector2(1.4, -39.0), Vector2(0, -1), Vector2(1, 0)],
		[Vector2(-1.4, -43.4), Vector2(1, 0), Vector2(0, -1)], [Vector2(1.4, -43.4), Vector2(0, 1), Vector2(1, 0)],
		[Vector2(0.0, -34.0), Vector2(0, -1), Vector2(0, 0)],
	]
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	for segment in segments:
		for jump: bool in [false, true]:
			var start: Vector2 = segment[0]
			var along: Vector2 = segment[1]
			var normal: Vector2 = segment[2]
			var aim := (along * cos(deg_to_rad(25.0)) + normal * sin(deg_to_rad(25.0))).normalized()
			# Derrière la dalle, le plafond du passage est à 3 m : le rayon qui cherche le sol part dessous.
			var top := base + (2.6 if start.y < -36.3 else 3.5)
			var ray := PhysicsRayQueryParameters3D.create(Vector3(start.x, top, start.y), Vector3(start.x, base - 3.0, start.y))
			ray.exclude = [player.get_rid()]
			var hit := space.intersect_ray(ray)
			var y: float = hit.position.y + 0.2 if hit else base + 0.2
			var label := "dedans (%.1f ; %.1f) vers (%.0f ; %.0f) %s" % [start.x, start.y, along.x, along.y, "course et saut" if jump else "marche"]
			await _drive(Vector3(start.x, y, start.y), func(_p: Vector2) -> Vector2: return aim, jump, 300, check_in, label)
