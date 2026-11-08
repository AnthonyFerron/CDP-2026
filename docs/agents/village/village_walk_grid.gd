extends "res://tests/scenes/common_test.gd"
## Passe au centimètre du Village : le joueur marche 1 s dans 8 directions depuis CHAQUE case de 0,5 m atteignable.
## Des copies du corps du joueur (même capsule, mêmes réglages de CharacterBody3D, même accélération et même vitesse
## que player.gd) marchent en parallèle, sur une couche à part qui ne se touche pas elle-même.
##   -- dehors [xmin xmax zmin zmax]   toute la surface atteignable dehors (ou un rectangle)
##   -- dedans                         la mairie, énigme résolue (salle secrète ouverte), avec un saut en chaque case
## Relève : joueur coincé, glissade sans fin, chute à travers le sol, chute libre de plus de 1,2 m, sortie de la carte,
## saut de hauteur de plus de 0,45 m en marchant hors escalier, tête au-dessus du plafond en sautant.
## Version du 8 novembre (verif-marche) : chaque corps se pose d'abord sur sa case (SETTLE_FRAMES images sans avancer),
## puis marche, comme le joueur qui part du sol ; posé 5 cm au-dessus d'une pente de 38 degrés, il partait en vol plané
## en la descendant (chute libre de 1,4 m comptée sur la colline du moulin, sur une pente continue). Au-delà de 64 m,
## sur le talus de bordure plus raide que 45 degrés (voulu, PROBLEMES.md n° 33), une glissade n'est pas une chute.
## Lancement, sans fenêtre (rien n'y lit les MultiMesh), un quart de carte à la fois (5 à 12 minutes chacun) :
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path frontend --script <ce fichier> -- dehors -71 -0.25 -71 -0.25 --api=http://127.0.0.1:9/api/v1
## Le journal des problèmes va dans .claude/captures/verif-marche/logs/ (chemin dans _run) ; la sortie les liste aussi (PROBLEME).

const STEP := 0.5
const CLIMB := 0.36
const RADIUS := 0.38
const HEIGHT := 1.8
const BATCH := 384
const WALK_FRAMES := 60
const STOP_FRAMES := 14
const SETTLE_FRAMES := 10
const LAYER := 1 << 20
const DIRECTIONS := [Vector3(1, 0, 0), Vector3(0.7071, 0, 0.7071), Vector3(0, 0, 1), Vector3(-0.7071, 0, 0.7071),
	Vector3(-1, 0, 0), Vector3(-0.7071, 0, -0.7071), Vector3(0, 0, -1), Vector3(0.7071, 0, -0.7071)]

var space: PhysicsDirectSpaceState3D
var capsule := CapsuleShape3D.new()
var problems: Array[String] = []
var bodies: Array[CharacterBody3D] = []
var terrain: Node
var inside := false
var log_file: FileAccess


class Walker extends CharacterBody3D:
	var direction := Vector3.ZERO
	var speed := 5.0
	var acceleration := 40.0
	var jump := false
	var active := false

	func _physics_process(delta: float) -> void:
		if not active:
			return
		if not is_on_floor():
			velocity += get_gravity() * delta
		elif jump:
			velocity.y = 5.5
			jump = false
		var target := direction * speed
		velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target.z, acceleration * delta)
		move_and_slide()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := Array(OS.get_cmdline_user_args()).filter(func(arg: String) -> bool: return not arg.begins_with("--"))
	await start_level("res://scenes/levels/village/village.tscn")
	for name in ["PauseMenu", "Pause"]:
		if root.has_node(name):
			root.get_node(name).process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("Hud").visible = false
	space = player.get_world_3d().direct_space_state
	terrain = level.get_node("Terrain")
	capsule.radius = RADIUS
	capsule.height = HEIGHT
	await wait(10)
	var mode: String = args[0] if not args.is_empty() else "dehors"
	log_file = FileAccess.open("/home/ubuntu/cdp-dev/.claude/captures/verif-marche/logs/vwalk2_%s.txt" % mode, FileAccess.WRITE)
	var reached: Dictionary
	if mode == "dedans":
		inside = true
		level.set("_inside", true)
		level.call("_apply_location")
		level.call("_on_codes_solved")
		await wait(260)
		reached = flood(level.get_node("Interior/InsideSpawn").global_position, Rect2(-20, -10, 32, 20))
	else:
		reached = flood(Vector3(0, 0.5, 57), Rect2(-75, -75, 150, 150))
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = Vector3(0, 200, 0)
	var cells := []
	var rects: Array[Rect2] = [Rect2(-75, -75, 150, 150)]
	if args.size() >= 5:
		rects.clear()
		var k := 1
		while k + 3 < args.size():
			rects.append(Rect2(float(args[k]), float(args[k + 2]), float(args[k + 1]) - float(args[k]), float(args[k + 3]) - float(args[k + 2])))
			k += 4
	for key: Vector3i in reached:
		var p := Vector3(key.x * STEP, reached[key], key.y * STEP)
		if rects.any(func(r: Rect2) -> bool: return r.has_point(Vector2(p.x, p.z))):
			cells.append(p)
	print("%s : %d cases, %d marches" % [mode, cells.size(), cells.size() * 8])
	for index in BATCH:
		var body := Walker.new()
		var shape := CollisionShape3D.new()
		shape.shape = player.get_node("CollisionShape3D").shape
		shape.position = Vector3(0, 0.9, 0)
		body.add_child(shape)
		body.collision_layer = LAYER
		body.collision_mask = player.collision_mask
		body.position = Vector3(index, 300, 0)
		level.add_child(body)
		bodies.append(body)
	# Une tâche : (case, direction). Les cases coincées se jugent sur leurs 8 directions.
	var moved := {}
	var tasks := []
	for cell_index in cells.size():
		for d in 8:
			tasks.append([cell_index, d])
	var start_time := Time.get_ticks_msec()
	var head := 0
	while head < tasks.size():
		var batch := tasks.slice(head, head + BATCH)
		head += BATCH
		await run_batch(batch, cells, moved)
		if (head / BATCH) % 20 == 0:
			print("  %d / %d marches, %d problèmes, %.0f s" % [mini(head, tasks.size()), tasks.size(), problems.size(), (Time.get_ticks_msec() - start_time) / 1000.0])
	var total := 0.0
	for value: float in moved.values():
		total += value
	print("déplacement moyen sur 1 s (meilleure direction) : %.2f m" % (total / maxf(moved.size(), 1)))
	for cell_index in cells.size():
		if moved.get(cell_index, 0.0) < 0.15:
			_note("joueur coincé", cells[cell_index])
	if inside:
		await jumps(cells)
	for line in problems:
		print("PROBLEME " + line)
		log_file.store_line(line)
	check("%s : %d cases, %d problème(s)" % [mode, cells.size(), problems.size()], problems.is_empty())
	finish()


func run_batch(batch: Array, cells: Array, moved: Dictionary) -> void:
	var starts := []
	for index in bodies.size():
		var body := bodies[index]
		if index >= batch.size():
			body.active = false
			body.global_position = Vector3(index * 1.0, 300, 500)
			continue
		var cell: Vector3 = cells[batch[index][0]]
		body.global_position = cell + Vector3.UP * 0.05
		body.velocity = Vector3.ZERO
		body.direction = Vector3.ZERO
		body.active = true
	# Chaque corps se pose sur sa case avant de marcher.
	for frame in SETTLE_FRAMES:
		await physics_frame
	for index in batch.size():
		var body := bodies[index]
		body.direction = DIRECTIONS[batch[index][1]]
		starts.append(body.global_position)
	var previous := []
	var highest_jump := []
	var lowest := []
	var takeoff := []
	var air_drop := []
	for index in batch.size():
		previous.append(starts[index].y)
		highest_jump.append(0.0)
		lowest.append(starts[index].y)
		takeoff.append(starts[index].y)
		air_drop.append(0.0)
	await physics_frame
	for frame in WALK_FRAMES + STOP_FRAMES:
		if frame == WALK_FRAMES:
			for index in batch.size():
				bodies[index].direction = Vector3.ZERO
		await physics_frame
		for index in batch.size():
			var y := bodies[index].global_position.y
			if y - previous[index] > highest_jump[index]:
				highest_jump[index] = y - previous[index]
			previous[index] = y
			lowest[index] = minf(lowest[index], y)
			# Chute libre : du dernier appui au sol suivant.
			if bodies[index].is_on_floor():
				air_drop[index] = maxf(air_drop[index], takeoff[index] - y)
				takeoff[index] = y
			elif y > takeoff[index]:
				takeoff[index] = y
		if frame == WALK_FRAMES - 1:
			for index in batch.size():
				var p := bodies[index].global_position
				var s: Vector3 = starts[index]
				var cell_index: int = batch[index][0]
				moved[cell_index] = maxf(moved.get(cell_index, 0.0), Vector2(p.x - s.x, p.z - s.z).length())
				bodies[index].set_meta("after", p)
	for index in batch.size():
		var body := bodies[index]
		var p := body.global_position
		var s: Vector3 = starts[index]
		var after: Vector3 = body.get_meta("after")
		var drift := Vector2(p.x - after.x, p.z - after.z).length()
		if drift > (0.6 if Vector2(after.x, after.z).length() < 64.0 else 1.5):
			_note("glisse sans fin (%.1f m après l'arrêt)" % drift, after)
		if highest_jump[index] > 0.45 and not _on_stairs(p):
			_note("saut de hauteur de %.2f m en marchant" % highest_jump[index], p)
		if air_drop[index] > 1.2 and not _on_stairs(s) and Vector2(s.x, s.z).length() <= 64.0:
			_note("chute libre de %.1f m (départ %s, dir %d)" % [air_drop[index], s, batch[index][1]], p)
		if Vector2(p.x, p.z).length() > 71.0:
			_note("sortie de la carte", p)
		# À travers le sol : sous le terrain dehors, sous le plancher du rez-de-chaussée dedans.
		if inside:
			if p.y < -40.4:
				_note("chute à travers le plancher (%.2f)" % p.y, p)
		elif p.y < terrain.surface_height(p.x, p.z) - 0.6 and not _in_stream(p):
			_note("sous le terrain (%.2f m)" % (terrain.surface_height(p.x, p.z) - p.y), p)
		body.active = false


func jumps(cells: Array) -> void:
	# Un saut sur place en chaque case : la tête ne passe pas le plafond.
	var head := 0
	while head < cells.size():
		var batch := cells.slice(head, head + BATCH)
		head += BATCH
		var highest := []
		for index in batch.size():
			var body := bodies[index]
			body.global_position = (batch[index] as Vector3) + Vector3.UP * 0.05
			body.velocity = Vector3.ZERO
			body.direction = Vector3.ZERO
			body.active = true
			highest.append(body.global_position.y)
		await physics_frame
		for index in batch.size():
			bodies[index].jump = true
		for frame in 60:
			await physics_frame
			for index in batch.size():
				highest[index] = maxf(highest[index], bodies[index].global_position.y)
		for index in batch.size():
			var p: Vector3 = batch[index]
			var local := p.y + 40.0
			var ceiling := 4.0 if local < 2.0 else 8.0
			if p.x < -8.0 or (p.x > 4.5 and p.z > -4.2 and p.z < 2.0):
				ceiling = 8.0
			if highest[index] + 40.0 + HEIGHT > ceiling + 0.02:
				_note("la tête passe le plafond en sautant (%.2f m)" % (highest[index] + 40.0 + HEIGHT), p)
			bodies[index].active = false
			bodies[index].jump = false


func _on_stairs(point: Vector3) -> bool:
	return point.y < -30.0 and point.x > 4.4 and point.x < 7.8 and point.z > -4.6 and point.z < 5.4


func _in_stream(point: Vector3) -> bool:
	return absf(point.x + 38.0) < 4.0


func _note(what: String, point: Vector3) -> void:
	var line := "%s en %s" % [what, point.snappedf(0.5)]
	if not problems.has(line):
		problems.append(line)
		print("  ! " + line)


func ground_hit(x: float, z: float, from_y: float) -> Dictionary:
	for offset: Vector2 in [Vector2.ZERO, Vector2(0.06, 0.06), Vector2(-0.06, -0.06)]:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(x + offset.x, from_y, z + offset.y), Vector3(x + offset.x, from_y - 1.6, z + offset.y))
		ray.exclude = [player.get_rid()]
		var hit := space.intersect_ray(ray)
		if not hit.is_empty() and (hit.normal as Vector3).y >= 0.7:
			return hit
	return {}


func fits(foot: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, foot + Vector3.UP * (HEIGHT / 2.0 + 0.12))
	query.exclude = [player.get_rid()]
	return space.intersect_shape(query, 1).is_empty()


func flood(start: Vector3, bounds: Rect2) -> Dictionary:
	var reached := {}
	var first := ground_hit(start.x, start.z, start.y + 1.0)
	if first.is_empty():
		return reached
	var y0: float = first.position.y
	var queue: Array[Vector3] = [Vector3(roundf(start.x / STEP), y0, roundf(start.z / STEP))]
	reached[Vector3i(int(queue[0].x), int(queue[0].z), roundi(y0 * 2.0))] = y0
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx := cell.x + dir.x
			var nz := cell.z + dir.y
			var x := nx * STEP
			var z := nz * STEP
			if not bounds.has_point(Vector2(x, z)) or Vector2(x, z).length() > 71.0:
				continue
			var hit := ground_hit(x, z, cell.y + 1.3)
			if hit.is_empty():
				continue
			var y: float = hit.position.y
			if absf(y - cell.y) > CLIMB:
				continue
			var key := Vector3i(int(nx), int(nz), roundi(y * 2.0))
			if reached.has(key) or not fits(Vector3(x, y, z)):
				continue
			reached[key] = y
			queue.append(Vector3(nx, y, nz))
	return reached
