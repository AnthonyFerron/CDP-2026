extends "res://tests/scenes/common_test.gd"
## Sauts en courant : depuis chaque point accessible à pied d'une zone, le joueur saute en courant dans 16 directions
## (vitesse de sprint, saut du joueur, move_and_slide du vrai corps, mêmes règles que player.gd). Chaque point
## d'arrivée qui n'est pas sur le sol accessible à pied est mis à l'épreuve : on cherche à en sortir en marchant ou en
## sautant (cette fois sans élan, le joueur part arrêté), de proche en proche. Si aucune suite ne ramène au sol
## accessible, le joueur y est coincé : le point est signalé. Un joueur calé en l'air (entre deux collisions, sans
## sol sous les pieds, donc sans pouvoir sauter) est mis à la même épreuve, en marchant seulement.
## Les pièges du lieu (lave de la Plaine, vase du Marais, sables mouvants du Désert) ramènent le joueur à son dernier
## point sûr : ils ne sont une issue que si ce point sûr est le sol accessible (règles copiées des scripts des lieux).
## Le sol accessible est cherché en plusieurs couches (planchers, étages, escaliers, cryptes), sur une grille de 0,5 m.
## Version du Village (adaptée de la sonde du Hub, docs/agents/hub/hub_jump_probe.gd), réglages des autres lieux
## gardés : le lieu se choisit dans PLACE.
## Lancement, depuis frontend :
##   godot --headless --path . --audio-driver Dummy --script <chemin>/village_jump_probe.gd -- <dehors|dedans> x0 z0 x1 z1 pas [resolu|ferme] --api=http://127.0.0.1:9/api/v1
## Dedans, l'énigme est résolue par défaut (passages ouverts). Contrôle : SONDE_TEST_PIEGE=x,z ajoute un piège fait
## exprès, que la sonde doit signaler ; SONDE_DEBUG=x,y,z,direction rejoue un seul saut.
## Le 8 novembre (pas 0,5 m, chaque case accessible, 16 directions) : dehors, maisons comprises, en quatre zones (x et z
## de -71 à 0 et de 0 à 71 ; 42 547 cases accessibles), 680 752 sauts, 46 491 arrivées hors du sol accessible ; avant
## correction, 3 points où l'on restait coincé, tous entre l'ardoise de la boulangère et le mur de la boulangerie
## ((5.35, 1.35, 29.46) calé en l'air, (5.35, 1.34, 28.56) sur le bord de la planche), atteints d'un saut depuis la
## grande rue : fente de 0,62 m, ardoise reculée à 0,97 m du mur (PROBLEMES.md n° 43) ; après, 0. Dans la mairie,
## énigme résolue (salle secrète ouverte ; 1 023 cases, étage et salle secrète compris), 16 368 sauts, 2 668 arrivées
## hors du sol accessible, 0 point coincé ; énigme non résolue (846 cases), 13 536 sauts, 2 617 arrivées, 0 point coincé.

const PLACE := "village"
const CELL := 0.5
const JITTER := 0.013
const DIRS := 16
const SPRINT := 8.0
const JUMP := 5.5
const ACCEL := 40.0
## Contrôle du sol : la place du corps du joueur (capsule de 0,4 m de rayon, 1,8 m de haut), sans ses 0,2 m du bas
## (il franchit un rebord bas). Le haut reste à 1,8 m : une capsule entière levée de 0,2 m butait sous les arches
## basses (passage de la salle secrète du Village) et coupait le sol accessible en deux.
const LIFT := 0.2
## Écart de hauteur entre deux cases voisines encore franchi à pied : la pente la plus raide où le joueur tient
## (45 degrés, sur 0,5 m). Une marche aussi basse se franchit d'un saut : aucun piège n'est caché par là.
const STEP_UP := 0.5
const ESCAPE_STATES := 3000
const JUMP_FRAMES := 240
const WALK_FRAMES := 12
## Le Marais engloutit le joueur sous cette hauteur des pieds (marais.gd, SINK_DEPTH).
const SINK_DEPTH := -0.9

var place := ""
var space: PhysicsDirectSpaceState3D
var terrain: Node
var scatter: Node
var capsule := CapsuleShape3D.new()
var floor_capsule := CapsuleShape3D.new()
var reach := {}
var reach_lo := Vector2.ZERO
var player_rid: RID
var inside := false
var gravity := 9.8
var dt := 1.0 / 60.0
var escape_memo := {}
var traps := {}
var off_reach := 0
var wedged := 0
var scan_top := 0.0
var scan_bottom := 0.0
var hazard_shape := PhysicsShapeQueryParameters3D.new()
var floor_shape := PhysicsShapeQueryParameters3D.new()
var ray := PhysicsRayQueryParameters3D.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: Array = Array(OS.get_cmdline_user_args()).filter(func(a: String) -> bool: return not a.begins_with("--"))
	place = PLACE
	args.push_front(PLACE)
	inside = args[1] == "dedans"
	var x0 := float(args[2])
	var z0 := float(args[3])
	var x1 := float(args[4])
	var z1 := float(args[5])
	var step := float(args[6])
	var solved := inside
	if args.size() > 7:
		solved = args[7] == "resolu"
	var scene: String = {"plaine": "res://scenes/levels/plaine/plaine.tscn", "marais": "res://scenes/levels/marais/marais.tscn",
		"village": "res://scenes/levels/village/village.tscn", "desert": "res://scenes/levels/desert/desert.tscn"}[place]
	var book: StringName = {"plaine": &"projenomicon", "marais": &"logiconomicon", "village": &"codonomicon",
		"desert": &"algonicon"}[place]
	state = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	state.intro_done = true
	if solved:
		state.books.append(book)
	change_scene_to_file(scene)
	await wait(60)
	level = current_scene
	player = level.get_node("Player")
	RenderingServer.render_loop_enabled = false
	space = player.get_world_3d().direct_space_state
	terrain = level.get_node("Exterior/Terrain" if level.has_node("Exterior/Terrain") else "Terrain")
	if place == "plaine":
		scatter = level.get_node("Exterior/Scatter")
	player_rid = player.get_rid()
	capsule.radius = 0.4
	capsule.height = 1.8
	player.set_physics_process(false)
	level.set_physics_process(false)
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	level.set("_inside", inside)
	level.call("_apply_location")
	await wait(5)
	floor_capsule.radius = 0.4
	floor_capsule.height = 1.8 - LIFT
	hazard_shape.shape = capsule
	hazard_shape.collide_with_areas = true
	hazard_shape.collide_with_bodies = false
	floor_shape.shape = floor_capsule
	floor_shape.exclude = [player_rid]
	ray.exclude = [player_rid]
	ray.hit_back_faces = false
	var start: Vector3 = level.get_node("Interior/InsideSpawn" if inside else ("Exterior/OutsideSpawn"
		if level.has_node("Exterior/OutsideSpawn") else "OutsideSpawn")).global_position
	if OS.get_environment("SONDE_TEST_PIEGE") != "":
		_add_test_trap(Vector2(float(OS.get_environment("SONDE_TEST_PIEGE").get_slice(",", 0)),
			float(OS.get_environment("SONDE_TEST_PIEGE").get_slice(",", 1))))
		await wait(3)
	var bounds := _bounds()
	var t0 := Time.get_ticks_msec()
	_build_reach(start, bounds)
	var cells := 0
	for key: Vector2i in reach:
		cells += reach[key].size()
	var shapes := level.find_children("*", "CollisionShape3D", true, false)
	var points := 0
	for shape_node: CollisionShape3D in shapes:
		if shape_node.shape is ConvexPolygonShape3D:
			points += shape_node.shape.points.size()
		elif shape_node.shape is ConcavePolygonShape3D:
			points += shape_node.shape.get_faces().size()
	print("SAUT %d formes de collision (%d sommets de polyèdres)" % [shapes.size(), points])
	print("SAUT %s %s : %d cases accessibles (%d ms), zone x %.1f..%.1f z %.1f..%.1f pas %.2f, énigme %s" % [place,
		"dedans" if inside else "dehors", cells, Time.get_ticks_msec() - t0, x0, x1, z0, z1, step,
		"résolue" if solved else "non résolue"])
	if OS.get_environment("SONDE_CARTE") != "":
		_print_map(x0, z0, x1, z1)
	if OS.get_environment("SONDE_DEBUG") != "":
		# Un seul saut : « x,y,z,direction » (direction sur 16, 0 = +z).
		var parts := OS.get_environment("SONDE_DEBUG").split(",")
		var from := Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
		var heights := _floors_at(from.x, from.z)
		print("DEBUG sols en %s : %s" % [from, heights])
		var nearest := INF
		for h: float in heights:
			if absf(h - from.y) < absf(nearest - from.y):
				nearest = h
		if nearest != INF:
			from.y = nearest
		var angle := TAU * int(parts[3]) / DIRS
		var landing: Variant = _simulate(from, Vector3(sin(angle), 0, cos(angle)), true, JUMP_FRAMES, true)
		print("DEBUG arrivée %s" % [landing])
		if landing != null:
			print("DEBUG sûr %s, issue %s" % [_safe(landing.p), _escapable(landing.p, landing.floor, not _sets_safe(landing.p, landing.floor))])
		finish()
		return
	t0 = Time.get_ticks_msec()
	var jumps := 0
	var x := x0
	while x <= x1:
		var z := z0
		while z <= z1:
			var key := Vector2i(roundi((x - reach_lo.x) / CELL), roundi((z - reach_lo.y) / CELL))
			if reach.has(key):
				for height: float in reach[key]:
					var from := Vector3(reach_lo.x + key.x * CELL + JITTER, height, reach_lo.y + key.y * CELL + JITTER)
					for d in DIRS:
						var angle := TAU * d / DIRS
						var dir := Vector3(sin(angle), 0, cos(angle))
						var landing: Variant = _simulate(from, dir, true, JUMP_FRAMES, true)
						jumps += 1
						if landing == null or landing.hazard:
							continue
						if landing.floor and _safe(landing.p):
							continue
						off_reach += 1
						if not landing.floor:
							wedged += 1
						if OS.get_environment("SONDE_TRACE") != "":
							print("TRACE %s d%d -> %s %s" % [from.snappedf(0.01), d, landing.p.snappedf(0.01), landing.floor])
						if not _escapable(landing.p, landing.floor, not _sets_safe(landing.p, landing.floor)):
							var tag := _tag(landing.p)
							if not traps.has(tag):
								traps[tag] = [from, d, landing.p]
								print("COINCE arrivée %s %s depuis %s direction %d" % [landing.p.snappedf(0.01),
									"au sol" if landing.floor else "calé en l'air", from.snappedf(0.01), d])
			z += step
		x += step
		if Time.get_ticks_msec() - t0 > 60000 and int(x / step) % 10 == 0:
			print("  ... x = %.1f, %d sauts, %d pièges, %d s" % [x, jumps, traps.size(), (Time.get_ticks_msec() - t0) / 1000])
	print("SAUT %d sauts, %d arrivées hors du sol accessible (%d calées en l'air), %d points où l'on reste coincé (%d ms)" % [
		jumps, off_reach, wedged, traps.size(), Time.get_ticks_msec() - t0])
	check("aucun saut en courant ne coince le joueur (%d)" % traps.size(), traps.is_empty())
	finish()


## Étendue où chercher le sol accessible : tout le lieu dehors (jusqu'à sa limite), toutes les collisions de
## l'intérieur dedans.
func _bounds() -> AABB:
	if not inside:
		var radius: float = {"plaine": 67.0, "marais": 69.0, "village": 71.0, "desert": 67.0}[place]
		return AABB(Vector3(-radius, 0, -radius), Vector3(radius * 2, 0, radius * 2))
	var box := AABB()
	var first := true
	for shape_node: CollisionShape3D in level.get_node("Interior").find_children("*", "CollisionShape3D", true, false):
		if shape_node.shape == null or shape_node.disabled:
			continue
		var debug := shape_node.shape.get_debug_mesh()
		var part := shape_node.global_transform * debug.get_aabb()
		box = part if first else box.merge(part)
		first = false
	scan_top = box.end.y
	scan_bottom = box.position.y - 0.2
	print("SAUT intérieur : %s" % box)
	return box


## Hauteur des sols en (x, z), du haut vers le bas : chaque dessus de collision assez plat où le joueur tient debout.
func _floors_at(x: float, z: float) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	var top := scan_top
	var bottom := scan_bottom
	if not inside:
		var base: float = terrain.surface_height(x, z)
		top = base + 6.0
		bottom = base - 0.8
	var from := top
	for i in 10:
		ray.from = Vector3(x, from, z)
		ray.to = Vector3(x, bottom, z)
		var hit := space.intersect_ray(ray)
		if hit.is_empty():
			break
		var y: float = hit.position.y
		if hit.normal.y >= 0.72 and not _excluded(x, y, z):
			floor_shape.transform = Transform3D(Basis(), Vector3(x, y + LIFT + (1.8 - LIFT) * 0.5, z))
			if space.intersect_shape(floor_shape, 1).is_empty():
				result.append(y)
		from = y - 0.02
	return result


## Sol où l'on ne tient pas : lave, eau trop profonde, sables mouvants.
func _excluded(x: float, y: float, z: float) -> bool:
	if inside:
		return false
	match place:
		"plaine":
			return scatter.is_near_lava(Vector3(x, y, z), 0.3)
		"marais":
			return y < SINK_DEPTH
		"desert":
			return _in_quicksand(Vector3(x, y, z))
	return false


func _in_quicksand(point: Vector3) -> bool:
	for sand in DesertTerrain.QUICKSANDS:
		if Vector2(point.x - sand.x, point.z - sand.y).length() < sand.z * 0.85:
			return true
	return false


## Le jeu retient-il ce point comme dernier point sûr (où le ramènent la lave, la vase ou les sables) ?
func _sets_safe(point: Vector3, on_floor: bool) -> bool:
	if inside or not on_floor:
		return false
	match place:
		"plaine":
			return not scatter.is_near_lava(point, 2.5)
		"marais":
			return point.y > 0.1
		"desert":
			return not _in_quicksand(point)
	return true


## Vitesse au sol : le Marais ralentit dans l'eau, le Désert dans les sables mouvants.
func _speed_multiplier(point: Vector3) -> float:
	if inside:
		return 1.0
	if place == "marais" and point.y < -0.15:
		return 0.55
	if place == "desert" and _in_quicksand(point):
		return 0.35
	return 1.0


## Le joueur touche-t-il un piège qui le ramène à son dernier point sûr ?
func _hazard(point: Vector3, on_floor: bool) -> bool:
	if inside:
		return false
	match place:
		"plaine":
			if not scatter.is_near_lava(point, 0.8):
				return false
			hazard_shape.transform = Transform3D(Basis(), point + Vector3(0, 0.9, 0))
			return not space.intersect_shape(hazard_shape, 1).is_empty()
		"marais":
			return point.y < SINK_DEPTH
		"desert":
			return on_floor and _in_quicksand(point)
	return false


## Fait courir (et sauter) le vrai corps du joueur, comme player.gd : rend {p, floor, hazard} à l'arrivée, ou null
## s'il tombe hors du monde ou n'en finit pas de glisser. Avec élan, il part à pleine vitesse ; sans, arrêté.
func _simulate(from: Vector3, dir: Vector3, jump: bool, frames: int, run_up: bool) -> Variant:
	# Le corps garde de son dernier mouvement l'état « au sol », le mur touché, la plateforme : on l'efface d'un
	# pas dans le vide, loin de tout, pour que chaque essai parte du même état (sans quoi le résultat dépend de
	# l'essai précédent).
	player.global_position = Vector3(0, 900, 0)
	player.velocity = Vector3.ZERO
	player.move_and_slide()
	player.global_position = from + Vector3(0, 0.05, 0)
	player.velocity = Vector3(0, -6, 0)
	player.move_and_slide()
	if jump and not player.is_on_floor():
		return null
	var speed := SPRINT * _speed_multiplier(player.global_position)
	player.velocity = dir * speed if run_up else Vector3.ZERO
	var left := not jump
	var still := 0
	var last := player.global_position
	for i in frames + (0 if jump else 90):
		var walking := jump or i < frames
		if not player.is_on_floor():
			player.velocity.y -= gravity * dt
		elif i == 0 and jump:
			player.velocity.y = JUMP
		speed = SPRINT * _speed_multiplier(player.global_position) if walking else 0.0
		player.velocity.x = move_toward(player.velocity.x, dir.x * speed, ACCEL * dt)
		player.velocity.z = move_toward(player.velocity.z, dir.z * speed, ACCEL * dt)
		player.move_and_slide()
		var p := player.global_position
		var on_floor: bool = player.is_on_floor()
		if _hazard(p, on_floor):
			return {"p": p, "floor": on_floor, "hazard": true}
		if p.y < from.y - 30.0:
			return null
		if not on_floor:
			left = true
		elif jump and left and i > 2:
			return {"p": p, "floor": true, "hazard": false}
		elif not jump and not walking and Vector2(player.velocity.x, player.velocity.z).length() < 0.01:
			return {"p": p, "floor": true, "hazard": false}
		still = still + 1 if p.distance_to(last) < 0.002 else 0
		last = p
	var end := player.global_position
	if player.is_on_floor():
		return {"p": end, "floor": true, "hazard": false}
	# Calé en l'air : ni sol ni chute depuis une demi-seconde.
	if still >= 30:
		return {"p": end, "floor": false, "hazard": false}
	return null


func _safe(point: Vector3) -> bool:
	var key := Vector2i(roundi((point.x - reach_lo.x) / CELL), roundi((point.z - reach_lo.y) / CELL))
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var k: Vector2i = key + Vector2i(dx, dz)
			if reach.has(k):
				for height: float in reach[k]:
					if absf(height - point.y) < 0.4:
						return true
	return false


func _tag(p: Vector3) -> Vector3i:
	return Vector3i(roundi(p.x * 2), roundi(p.y * 2), roundi(p.z * 2))


## Cherche une suite de pas (1 m environ, départ arrêté) et de sauts sans élan qui ramène au sol accessible :
## parcours en largeur des points d'arrivée, jusqu'à ESCAPE_STATES états. « rescued » : un piège du lieu ramènerait
## le joueur sur le sol accessible (son dernier point sûr n'a pas changé depuis). Un échec marque tous les états vus
## comme pièges ; une réussite, le chemin suivi.
func _escapable(point: Vector3, on_floor: bool, rescued: bool) -> bool:
	var root_key := _memo_key(point, on_floor, rescued)
	if escape_memo.has(root_key):
		return escape_memo[root_key]
	var queue: Array = [[point, on_floor, rescued]]
	var parent := {root_key: null}
	var head := 0
	while head < queue.size() and head < ESCAPE_STATES:
		var item: Array = queue[head]
		head += 1
		var p: Vector3 = item[0]
		var p_key := _memo_key(p, item[1], item[2])
		for d in 8:
			var angle := TAU * d / 8
			var dir := Vector3(sin(angle), 0, cos(angle))
			for jump: bool in [false, true]:
				if jump and not item[1]:
					continue
				var q: Variant = _simulate(p, dir, jump, JUMP_FRAMES if jump else WALK_FRAMES, false)
				if q == null:
					continue
				var escaped := false
				var q_rescued: bool = item[2] and not _sets_safe(q.p, q.floor)
				if q.hazard:
					escaped = item[2]
				elif q.floor and _safe(q.p):
					escaped = true
				var q_key := _memo_key(q.p, q.floor, q_rescued)
				if not escaped and escape_memo.get(q_key) == true:
					escaped = true
				if escaped and OS.get_environment("SONDE_TRACE") != "":
					print("  issue depuis %s (%s) : %s %d -> %s sol %s, piège %s, sûr %s, mémoire %s" % [p.snappedf(0.01), item[1],
						"saut" if jump else "pas", d, q.p.snappedf(0.01), q.floor, q.hazard, q.floor and _safe(q.p), escape_memo.get(q_key)])
				if escaped:
					var t: Variant = p_key
					while t != null:
						escape_memo[t] = true
						t = parent[t]
					return true
				if q.hazard or parent.has(q_key) or escape_memo.get(q_key) == false:
					continue
				parent[q_key] = p_key
				queue.append([q.p, q.floor, q_rescued])
	if head >= ESCAPE_STATES:
		print("  (recherche d'issue arrêtée à %d états depuis %s)" % [ESCAPE_STATES, point.snappedf(0.01)])
	for t: Vector4i in parent:
		escape_memo[t] = false
	return false


## Clé d'un état de la recherche : position au quart de mètre (au dixième en hauteur), au sol ou calé en l'air, et
## secours possible ou non. Plus grossière, deux états voisins aux issues différentes se confondaient.
func _memo_key(p: Vector3, on_floor: bool, rescued: bool) -> Vector4i:
	return Vector4i(roundi(p.x * 4), roundi(p.y * 10), roundi(p.z * 4), (1 if rescued else 0) + (2 if on_floor else 0))


func _build_reach(start: Vector3, bounds: AABB) -> void:
	var lo := Vector2(bounds.position.x, bounds.position.z)
	var hi := Vector2(bounds.end.x, bounds.end.z)
	reach_lo = lo
	var floors := {}
	for i in int((hi.x - lo.x) / CELL) + 1:
		for j in int((hi.y - lo.y) / CELL) + 1:
			var heights := _floors_at(lo.x + i * CELL + JITTER, lo.y + j * CELL + JITTER)
			if not heights.is_empty():
				floors[Vector2i(i, j)] = heights
	var first: Variant = null
	var best := INF
	for key: Vector2i in floors:
		for layer in floors[key].size():
			var at := Vector3(lo.x + key.x * CELL, floors[key][layer], lo.y + key.y * CELL)
			var d := at.distance_to(start)
			if d < best:
				best = d
				first = Vector3i(key.x, key.y, layer)
	var seen := {first: true}
	var queue: Array[Vector3i] = [first]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		var height: float = floors[Vector2i(cell.x, cell.y)][cell.z]
		for s: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := Vector2i(cell.x, cell.y) + s
			if not floors.has(n):
				continue
			var layers: PackedFloat32Array = floors[n]
			for layer in layers.size():
				var key := Vector3i(n.x, n.y, layer)
				if seen.has(key) or absf(layers[layer] - height) > STEP_UP:
					continue
				seen[key] = true
				queue.append(key)
	reach = {}
	for key: Vector3i in seen:
		var k := Vector2i(key.x, key.y)
		if not reach.has(k):
			reach[k] = PackedFloat32Array()
		reach[k].append(floors[k][key.z])


## Carte de la zone, une ligne par mètre en z : # accessible, . sol hors d'atteinte, espace rien.
func _print_map(x0: float, z0: float, x1: float, z1: float) -> void:
	var zz := z0
	while zz <= z1:
		var line := "%6.1f " % zz
		var xx := x0
		while xx <= x1:
			var k := Vector2i(roundi((xx - reach_lo.x) / CELL), roundi((zz - reach_lo.y) / CELL))
			# Dedans, le chiffre donne le nombre d'étages atteints en ce point.
			if reach.has(k):
				line += str(reach[k].size()) if inside else "#"
			else:
				line += "." if not _floors_at(xx + JITTER, zz + JITTER).is_empty() else " "
			xx += 1.0
		print(line)
		zz += 1.0


## Contrôle de la sonde : un piège fait exprès (plateforme de 2,5 m sur une rampe, percée d'un puits de 2 m de côté où
## l'on tombe sans pouvoir remonter). La sonde doit le signaler.
func _add_test_trap(center: Vector2) -> void:
	var ground: float = terrain.surface_height(center.x, center.y)
	var body := StaticBody3D.new()
	level.add_child(body)
	var height := 2.5
	for part: Rect2 in [Rect2(-3, -3, 6, 2), Rect2(-3, 1, 6, 2), Rect2(-3, -1, 2, 2), Rect2(1, -1, 2, 2)]:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(part.size.x, height + 1.0, part.size.y)
		shape.shape = box
		shape.position = Vector3(center.x + part.get_center().x, ground + height - (height + 1.0) * 0.5, center.y + part.get_center().y)
		body.add_child(shape)
	var angle := atan2(height + 0.5, 9.0)
	var ramp := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(2.0, 0.2, 9.0 / cos(angle))
	ramp.shape = slab
	ramp.rotation.x = angle
	ramp.position = Vector3(center.x, ground + height * 0.5 - 0.1, center.y + 7.5)
	body.add_child(ramp)
