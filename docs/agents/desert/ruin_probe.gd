extends "res://tests/scenes/common_test.gd"
## Ruines éparses (colonnes couchées, tas de briques) : leurs enveloppes déplacées ensemble de plusieurs décalages
## verticaux ; autour de chacune, grille locale au pas de 0,5 m (règle de desert_grid_test : sol cherché à 0,45 m
## au plus au-dessus du sable, passage si le sol change de 0,3 m au plus), et marches de plus de 0,4 m.

const OFFSETS: Array[float] = [0.0, -0.05, -0.1, -0.15, -0.2, 0.05, 0.1]
const CELL := 0.5
const HALF := 3.5
const JITTER := 0.013

var space: PhysicsDirectSpaceState3D
var terrain: Node
var capsule := CapsuleShape3D.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	await wait(5)
	space = player.get_world_3d().direct_space_state
	terrain = level.get_node("Exterior/Terrain")
	capsule.radius = 0.36
	capsule.height = 1.7
	player.global_position = Vector3(0, 0, 48)
	player.set_physics_process(false)
	# Le corps des ruines : celui qui porte une enveloppe près du tas de briques de (30.4, 14.5).
	var ruins: Array[CollisionShape3D] = []
	for body: StaticBody3D in level.get_node("Exterior/Scatter").find_children("*", "StaticBody3D", true, false):
		var shapes: Array[CollisionShape3D] = []
		var hit := false
		for child in body.get_children():
			if child is CollisionShape3D and child.shape is ConvexPolygonShape3D:
				shapes.append(child)
				if Vector2(child.global_position.x, child.global_position.z).distance_to(Vector2(30.42, 14.45)) < 0.5:
					hit = true
		if hit:
			ruins = shapes
	print("RUINES %d enveloppes" % ruins.size())
	var rests: Array[float] = []
	for shape_node in ruins:
		rests.append(shape_node.position.y)
	for dy in OFFSETS:
		for index in ruins.size():
			ruins[index].position.y = rests[index] + dy
		await wait(2)
		var total := 0
		var spots := ""
		for shape_node in ruins:
			var p := shape_node.global_position
			var result := _scan(Vector2(p.x, p.z))
			total += result
			if result > 0:
				spots += " %s" % Vector2(p.x, p.z).snappedf(0.1)
		print("RUINES %+.2f -> %d marche(s)%s" % [dy, total, spots])
	for index in ruins.size():
		ruins[index].position.y = rests[index]
	finish()


func _floor(x: float, z: float) -> float:
	var base: float = terrain.surface_height(x, z)
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, base + 0.45, z), Vector3(x, base - 0.6, z))
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


func _scan(center: Vector2) -> int:
	var count := int(2.0 * HALF / CELL) + 1
	var floors := {}
	for i in count:
		for j in count:
			var y := _floor(center.x - HALF + i * CELL + JITTER, center.y - HALF + j * CELL + JITTER)
			if not is_nan(y):
				floors[Vector2i(i, j)] = y
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
	for key: Vector2i in reach:
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
			if reach.has(key + offset) and absf(float(floors[key + offset]) - float(floors[key])) > 0.4:
				steps += 1
	return steps
