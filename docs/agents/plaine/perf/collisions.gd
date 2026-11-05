extends "res://tests/scenes/common_test.gd"
## Ce qui est sous les pieds, avant et après le regroupement du décor : relevé trié de toutes les formes de
## collision (chemin du corps, place, taille), et grille de marche rapide dehors (0,6 m) et dans les archives
## (0,3 m) par remplissage depuis l'arrivée, comme lore_test.gd. Écrit le relevé dans <dossier>/collisions.txt.
## Usage : -- <dossier> --api=http://127.0.0.1:9/api/v1

const STEP := 0.6
const INSIDE_STEP := 0.3

var space: PhysicsDirectSpaceState3D
var capsule := CapsuleShape3D.new()


func _initialize() -> void:
	capsule.radius = 0.4
	capsule.height = 1.8
	_run.call_deferred()


func _run() -> void:
	var out := ""
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			out = argument
	DirAccess.make_dir_recursive_absolute(out)
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	space = level.get_world_3d().direct_space_state
	var lines: PackedStringArray = []
	for node in level.find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		if not shape.shape or level.get_node("Player").is_ancestor_of(shape):
			continue
		var size := ""
		if shape.shape is BoxShape3D:
			size = str((shape.shape as BoxShape3D).size.snappedf(0.001))
		elif shape.shape is ConvexPolygonShape3D:
			size = "convexe %d" % (shape.shape as ConvexPolygonShape3D).points.size()
		elif shape.shape is ConcavePolygonShape3D:
			size = "maillage %d" % (shape.shape as ConcavePolygonShape3D).get_faces().size()
		else:
			size = shape.shape.get_class()
		var body := shape.get_parent()
		var path := String(level.get_path_to(body)).get_base_dir()
		lines.append("%s | %s | %s | %s" % [path, shape.global_position.snappedf(0.001),
			shape.global_basis.get_euler().snappedf(0.001), size])
	lines.sort()
	var file := FileAccess.open(out + "/collisions.txt", FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()
	print("PIEDS formes de collision %d, empreinte %s" % [lines.size(), "\n".join(lines).md5_text()])
	var outside := _flood(level.get_node("Exterior/OutsideSpawn").global_position, Vector2(-70, -70), Vector2(70, 70),
		STEP, 30.0, -12.0)
	var inside := _flood(level.get_node("Interior/InsideSpawn").global_position, Vector2(-6.5, -44.8), Vector2(6.5, 0.6),
		INSIDE_STEP, -36.2, -42.5)
	var keys := outside.keys() + inside.keys().map(func(k: Vector2i) -> Vector2i: return k + Vector2i(100000, 0))
	keys.sort()
	print("PIEDS grille de marche : dehors %d cases, archives %d cases, empreinte %s" % [outside.size(), inside.size(),
		str(keys).md5_text()])
	finish()


func _ground(x: float, z: float, top: float, bottom: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, bottom, z))
	query.collide_with_areas = false
	return space.intersect_ray(query)


func _walkable(x: float, z: float, top: float, bottom: float) -> float:
	var hit := _ground(x, z, top, bottom)
	if not hit.is_empty() and hit.normal.y < 0.7:
		hit = _ground(x + 0.013, z - 0.017, top, bottom)
	if hit.is_empty() or hit.normal.y < 0.7:
		return NAN
	var ground: float = hit.position.y
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis(), Vector3(x, ground + 1.05, z))
	query.collide_with_areas = false
	query.exclude = [player.get_rid()]
	if not space.intersect_shape(query, 1).is_empty():
		return NAN
	var scatter: PlaineScatter = level.get_node("Exterior/Scatter")
	if ground > -20.0 and scatter.is_near_lava(Vector3(x, ground, z), 0.4):
		return NAN
	return ground


func _flood(start: Vector3, low: Vector2, high: Vector2, step: float, top: float, bottom: float) -> Dictionary:
	var cells := {}
	var seen := {}
	var origin := Vector2i(roundi((start.x - low.x) / step), roundi((start.z - low.y) / step))
	var size := Vector2i(ceili((high.x - low.x) / step), ceili((high.y - low.y) / step))
	var queue: Array[Vector2i] = [origin]
	var first := _walkable(low.x + origin.x * step, low.y + origin.y * step, top, bottom)
	if is_nan(first):
		return cells
	cells[origin] = first
	seen[origin] = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		var height: float = cells[cell]
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + offset
			if seen.has(next) or next.x < 0 or next.y < 0 or next.x > size.x or next.y > size.y:
				continue
			var ground := _walkable(low.x + next.x * step, low.y + next.y * step, minf(top, height + 2.2), bottom)
			if is_nan(ground) or absf(ground - height) > step * 0.75:
				continue
			seen[next] = true
			cells[next] = ground
			queue.append(next)
	return cells
