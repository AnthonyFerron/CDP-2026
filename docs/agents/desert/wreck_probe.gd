extends "res://tests/scenes/common_test.gd"
## Épaves de siège : pour plusieurs décalages verticaux de chaque épave (ses collisions déplacées ensemble), grille
## de marche locale au pas de 0,5 m (même règle que desert_grid_test : on passe d'une case à sa voisine si le sol
## change de 0,3 m au plus), puis marches de plus de 0,4 m et points où le joueur est coincé.

const WRECKS: Array[Vector2] = [Vector2(26, 32), Vector2(-46, 14), Vector2(30, -18), Vector2(-14, -38), Vector2(44, -40), Vector2(-52, -6)]
const OFFSETS: Array[float] = [-0.2, -0.12, -0.06, 0.0, 0.06, 0.12, 0.2, 0.3]
const CELL := 0.5
const HALF := 8.0
const JITTER := 0.013

var space: PhysicsDirectSpaceState3D
var terrain: Node
var capsule := CapsuleShape3D.new()
## Hauteur au-dessus du sable où l'on cherche un sol : 0,45 m comme desert_grid_test, ou 3 m.
var top := 0.45


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	if "haut" in OS.get_cmdline_user_args():
		top = 3.0
	await wait(5)
	space = player.get_world_3d().direct_space_state
	terrain = level.get_node("Exterior/Terrain")
	capsule.radius = 0.36
	capsule.height = 1.7
	player.global_position = Vector3(0, 0, 48)
	player.set_physics_process(false)
	# Les formes concaves des épaves, rangées par épave la plus proche du centre de leurs faces.
	var groups := {}
	for shape_node: CollisionShape3D in level.get_node("Exterior/Scatter").find_children("*", "CollisionShape3D", true, false):
		if not shape_node.shape is ConcavePolygonShape3D:
			continue
		var faces: PackedVector3Array = (shape_node.shape as ConcavePolygonShape3D).get_faces()
		if faces.is_empty():
			continue
		var center := Vector3.ZERO
		for f in faces:
			center += f
		center /= faces.size()
		var best := -1
		for k in WRECKS.size():
			if Vector2(center.x, center.z).distance_to(WRECKS[k]) < 6.0:
				best = k
		if best >= 0:
			if not groups.has(best):
				groups[best] = []
			groups[best].append(shape_node)
	for k in WRECKS.size():
		var shapes: Array = groups.get(k, [])
		var line := "EPAVE %d %s (%d formes) :" % [k, WRECKS[k], shapes.size()]
		for dy in OFFSETS:
			for shape_node: CollisionShape3D in shapes:
				shape_node.position.y = dy
			await wait(2)
			var result := _scan(WRECKS[k])
			line += "  %+.2f -> %d marches (max %.2f), %d coincé(s)" % [dy, result[0], result[1], result[2]]
		for shape_node: CollisionShape3D in shapes:
			shape_node.position.y = 0.0
		print(line)
	finish()


func _floor(x: float, z: float) -> float:
	var base: float = terrain.surface_height(x, z)
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, base + top, z), Vector3(x, base - 0.6, z))
	query.exclude = [player.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty() or hit.normal.y < 0.72:
		return NAN
	var y: float = hit.position.y
	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = capsule
	shape_query.transform = Transform3D(Basis(), Vector3(x, y + 0.18 + 0.85, z))
	shape_query.exclude = [player.get_rid()]
	if not space.intersect_shape(shape_query, 1).is_empty():
		return NAN
	return y


## [nombre de marches de plus de 0,4 m, la plus haute, cases coincées] autour du point.
func _scan(center: Vector2) -> Array:
	var count := int(2.0 * HALF / CELL) + 1
	var floors := {}
	for i in count:
		for j in count:
			var y := _floor(center.x - HALF + i * CELL + JITTER, center.y - HALF + j * CELL + JITTER)
			if not is_nan(y):
				floors[Vector2i(i, j)] = y
	# Départ : un coin de la zone, sur le sable libre.
	var reach := {}
	var queue: Array[Vector2i] = []
	for start: Vector2i in [Vector2i(0, 0), Vector2i(count - 1, 0), Vector2i(0, count - 1), Vector2i(count - 1, count - 1)]:
		if floors.has(start) and not reach.has(start):
			reach[start] = true
			queue.append(start)
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next := cell + step
			if reach.has(next) or not floors.has(next):
				continue
			if absf(float(floors[next]) - float(floors[cell])) > 0.3:
				continue
			reach[next] = true
			queue.append(next)
	var steps := 0
	var highest := 0.0
	var stuck := 0
	for key: Vector2i in reach:
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
			if reach.has(key + offset):
				var d := absf(float(floors[key + offset]) - float(floors[key]))
				if d > 0.4:
					steps += 1
					highest = maxf(highest, d)
		var free := 0
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if reach.has(key + offset):
				free += 1
		if free == 0 and reach.size() > 1:
			stuck += 1
	return [steps, highest, stuck]
