extends "res://tests/scenes/common_test.gd"
## Sauts en courant : depuis chaque point accessible à pied d'une zone, le joueur saute en courant dans 16 directions
## (vitesse de sprint, saut du joueur, move_and_slide du vrai corps). Chaque point d'arrivée qui n'est pas sur le sol
## accessible à pied est mis à l'épreuve : on cherche à en sortir en marchant ou en sautant en courant, sur trois
## coups. Si aucune suite ne ramène au sol accessible, le joueur y est coincé : le point est signalé.
## Version du Hub (adaptée de la sonde du Désert) : les points de départ peuvent être limités aux abords de l'eau.
## Lancement, depuis frontend : godot --headless --path . --script <chemin>/hub_jump_probe.gd -- x0 z0 x1 z1 pas [distance] [livres] --api=http://127.0.0.1:9/api/v1
## Le 8 novembre : rivière et berges (pas 1, distance 12) 93 points coincés avant, 0 après ; tout le hub (pas 1,5) 0.
## Arguments : x0 z0 x1 z1 pas [distance max au bord de l'eau, ou -1 pour tout] [livres posés]

const CELL := 0.5
const JITTER := 0.013
const DIRS := 16
const SPRINT := 8.0
const JUMP := 5.5

var space: PhysicsDirectSpaceState3D
var terrain: Node
var capsule := CapsuleShape3D.new()
var reach := {}
var reach_lo := Vector2.ZERO
var player_rid: RID
var inside := false
var shore_max := -1.0
var gravity := 9.8
var dt := 1.0 / 60.0
var escape_memo := {}
var traps := {}
var floor_base := NAN


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: Array = Array(OS.get_cmdline_user_args()).filter(func(a: String) -> bool: return not a.begins_with("--"))
	var x0 := float(args[0])
	var z0 := float(args[1])
	var x1 := float(args[2])
	var z1 := float(args[3])
	var step := float(args[4])
	shore_max = float(args[5]) if args.size() > 5 else -1.0
	var books := int(args[6]) if args.size() > 6 else 0
	state = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	state.intro_done = true
	var all: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]
	for index in books:
		state.books.append(all[index])
		state.placed_books.append(all[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await wait(60)
	level = current_scene
	player = level.get_node("Player")
	RenderingServer.render_loop_enabled = false
	space = player.get_world_3d().direct_space_state
	terrain = level.get_node("Terrain")
	player_rid = player.get_rid()
	capsule.radius = 0.4
	capsule.height = 1.8
	player.set_physics_process(false)
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	level.call("_set_location", false)
	await wait(5)
	var start: Vector3 = level.get_node("DefaultSpawn").global_position
	# Départ et sol imposés (abri souterrain, salle de l'observatoire) : SONDE_DEPART="x,y,z", SONDE_SOL=<y du sol>.
	if OS.get_environment("SONDE_DEPART") != "":
		var p := OS.get_environment("SONDE_DEPART").split(",")
		start = Vector3(float(p[0]), float(p[1]), float(p[2]))
	if OS.get_environment("SONDE_SOL") != "":
		floor_base = float(OS.get_environment("SONDE_SOL"))
		if floor_base < -20.0:
			level.call("_set_location", true)
	level.get_node("Props").finish_all()
	_build_reach(start)
	print("SAUT %d cases accessibles" % reach.size())
	if OS.get_environment("SONDE_CARTE") != "":
		# Carte de la zone, une ligne par mètre en z : # accessible, . sol hors d'atteinte, espace rien.
		var floors_count := 0
		var zz := z0
		while zz <= z1:
			var line := "%6.1f " % zz
			var xx := x0
			while xx <= x1:
				var k := Vector2i(roundi((xx - reach_lo.x) / CELL), roundi((zz - reach_lo.y) / CELL))
				line += "#" if reach.has(k) else ("." if not is_nan(_floor_at(xx + JITTER, zz + JITTER)) else " ")
				xx += 1.0
			print(line)
			zz += 1.0
	var t0 := Time.get_ticks_msec()
	var jumps := 0
	var x := x0
	while x <= x1:
		var z := z0
		while z <= z1:
			var key := Vector2i(roundi((x - reach_lo.x) / CELL), roundi((z - reach_lo.y) / CELL))
			if reach.has(key) and (shore_max < 0.0 or terrain.shore_distance(x, z) <= shore_max):
				var from := _cell_position(key)
				for d in DIRS:
					var angle := TAU * d / DIRS
					var dir := Vector3(sin(angle), 0, cos(angle))
					var landing: Variant = _simulate(from, dir, true, 150)
					jumps += 1
					if landing == null:
						continue
					if _safe(landing):
						continue
					if not _escapable(landing, 3):
						var tag := Vector3i(roundi(landing.x * 2), roundi(landing.y * 2), roundi(landing.z * 2))
						if not traps.has(tag):
							traps[tag] = [from, dir, landing]
							print("COINCE arrivée %s depuis %s direction %d" % [landing.snappedf(0.01), from.snappedf(0.01), d])
			z += step
		x += step
	print("SAUT %d sauts, %d points où l'on reste coincé (%d ms)" % [jumps, traps.size(), Time.get_ticks_msec() - t0])
	check("aucun saut en courant ne coince le joueur (%d)" % traps.size(), traps.is_empty())
	finish()


## Fait courir (et sauter) le vrai corps du joueur ; rend son point d'arrivée au sol, ou null s'il n'atterrit pas.
func _simulate(from: Vector3, dir: Vector3, jump: bool, frames: int) -> Variant:
	player.global_position = from + Vector3(0, 0.05, 0)
	player.velocity = Vector3(0, -1, 0)
	player.move_and_slide()
	player.velocity = dir * SPRINT + Vector3(0, JUMP if jump else 0.0, 0)
	var left := not jump
	for i in frames:
		if not player.is_on_floor() or (i == 0 and jump):
			if i > 0 or not jump:
				player.velocity.y -= gravity * dt
		player.velocity.x = dir.x * SPRINT
		player.velocity.z = dir.z * SPRINT
		player.move_and_slide()
		if player.global_position.y < from.y - 30.0:
			return null
		if not player.is_on_floor():
			left = true
		elif left and i > 2:
			if jump:
				return player.global_position
		if not jump and i >= frames - 1:
			break
	if not jump:
		# Marche : quelques images de plus pour retomber.
		for i in 60:
			if player.is_on_floor():
				break
			player.velocity = Vector3(0, player.velocity.y - gravity * dt, 0)
			player.move_and_slide()
		return player.global_position if player.is_on_floor() else null
	return player.global_position if player.is_on_floor() else null


func _safe(point: Vector3) -> bool:
	var key := Vector2i(roundi((point.x - reach_lo.x) / CELL), roundi((point.z - reach_lo.y) / CELL))
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var k: Vector2i = key + Vector2i(dx, dz)
			if reach.has(k) and absf(reach[k] - point.y) < 0.4:
				return true
	# Sables mouvants et chute sous la carte ramènent le joueur : pas un piège.
	return false


## Cherche une suite de pas (1 m) et de sauts en courant qui ramène au sol accessible : parcours en largeur des
## points d'arrivée, jusqu'à 3000 états. Un échec marque tous les états vus comme pièges ; une réussite, le chemin.
func _tag(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x * 2), roundi(p.y * 2), roundi(p.z * 2))


func _escapable(point: Vector3, _depth: int) -> bool:
	var tag := _tag(point)
	if escape_memo.has(tag):
		return escape_memo[tag]
	var queue: Array[Vector3] = [point]
	var parent := {tag: null}
	var head := 0
	while head < queue.size() and head < 3000:
		var p := queue[head]
		head += 1
		for d in 8:
			var angle := TAU * d / 8
			var dir := Vector3(sin(angle), 0, cos(angle))
			for jump in [false, true]:
				var q: Variant = _simulate(p, dir, jump, 150 if jump else 8)
				if q == null:
					continue
				var qt := _tag(q)
				var known: Variant = escape_memo.get(qt)
				if _safe(q) or known == true:
					var t: Variant = _tag(p)
					while t != null:
						escape_memo[t] = true
						t = parent[t]
					return true
				if parent.has(qt) or known == false:
					continue
				parent[qt] = _tag(p)
				queue.append(q)
	for t: Vector3i in parent:
		escape_memo[t] = false
	return false


func _floor_at(x: float, z: float) -> float:
	var base: float = terrain.surface_height(x, z) if is_nan(floor_base) else floor_base
	# Tablier des ponts (DECK_TOP = 0,1 dans tools/build_hub.py), au-dessus du lit creusé.
	for bridge: Array in HubTerrain.BRIDGES:
		if is_nan(floor_base) and HubTerrain.bridge_contains(bridge, Vector2(x, z), 0.3):
			base = maxf(base, 0.1)
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, base + 0.45, z), Vector3(x, base - 0.6, z))
	query.exclude = [player_rid]
	var hit := space.intersect_ray(query)
	if hit.is_empty() or hit.normal.y < 0.72:
		return NAN
	var y: float = hit.position.y
	var shape := PhysicsShapeQueryParameters3D.new()
	shape.shape = capsule
	# Capsule levée de 0,2 m : le joueur franchit le rebord d'un tablier ou d'une marche basse.
	shape.transform = Transform3D(Basis(), Vector3(x, y + 1.12, z))
	shape.exclude = [player_rid]
	if not space.intersect_shape(shape, 1).is_empty():
		return NAN
	return y


func _build_reach(start: Vector3) -> void:
	var lo := Vector2(-112, -116)
	var hi := Vector2(132, 130)
	if not is_nan(floor_base):
		lo = Vector2(start.x - 16.0, start.z - 16.0)
		hi = Vector2(start.x + 16.0, start.z + 16.0)
	reach_lo = lo
	var floors := {}
	for i in int((hi.x - lo.x) / CELL) + 1:
		for j in int((hi.y - lo.y) / CELL) + 1:
			var y := _floor_at(lo.x + i * CELL + JITTER, lo.y + j * CELL + JITTER)
			if not is_nan(y):
				floors[Vector2i(i, j)] = y
	var origin := Vector2i(roundi((start.x - lo.x) / CELL), roundi((start.z - lo.y) / CELL))
	var first: Variant = null
	var best := INF
	for key: Vector2i in floors:
		var d := Vector2(key - origin).length()
		if d < best:
			best = d
			first = key
	reach = {}
	var queue: Array[Vector2i] = [first]
	reach[first] = floors[first]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for s: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := cell + s
			if reach.has(n) or not floors.has(n):
				continue
			if absf(floors[n] - floors[cell]) > 0.3:
				continue
			reach[n] = floors[n]
			queue.append(n)


func _cell_position(key: Vector2i) -> Vector3:
	return Vector3(reach_lo.x + key.x * CELL + JITTER, reach[key], reach_lo.y + key.y * CELL + JITTER)
