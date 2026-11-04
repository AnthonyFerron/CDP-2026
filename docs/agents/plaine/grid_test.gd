extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Grille de marche des plaines (« ++ dehors » ou « ++ dedans ») : en chaque case, sol, marches, pentes où l'on
## glisse, zones fermées, plafonds ; et, en comparant les collisions à une couche « visuelle » faite des maillages
## affichés : maillages visibles traversables, et blocages sans rien de visible à moins de 0,5 m (murs invisibles).
## À lancer avec fenêtre : les MultiMesh ne gardent leurs instances qu'avec un vrai rendu.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/grille/"
const VISUAL_LAYER := 1 << 19
const SOLID := 1

var space: PhysicsDirectSpaceState3D
var problems := {}
var samples := {}
var visual_body: StaticBody3D
var shape_cache := {}
var floor_bodies: Array[RID] = []


func _initialize() -> void:
	_run.call_deferred()


var by_source := {}


func report(kind: String, where: Vector3, detail := "") -> void:
	problems[kind] = problems.get(kind, 0) + 1
	var key := kind + " : " + detail.get_slice(" en ", 0) + " en " + detail.get_slice(" en ", 1) if " en " in detail else kind + " : " + detail
	by_source[key] = by_source.get(key, 0) + 1
	if not samples.has(kind):
		samples[kind] = []
	if samples[kind].size() < 12:
		samples[kind].append("(%.2f, %.2f, %.2f) %s" % [where.x, where.y, where.z, detail])


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var inside := OS.get_cmdline_user_args().has("dedans")
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	space = level.get_world_3d().direct_space_state
	var stone: Node3D = level.get_node("Interior/Stone")
	stone.position.x -= level.stone_travel
	# Les deux moitiés du lieu sont prises dans la couche visuelle, quelle que soit celle qui est affichée.
	level.get_node("Interior").visible = true
	level.get_node("Exterior").visible = true
	_build_visual_layer()
	floor_bodies.append(level.get_node("Exterior/Terrain").get_rid())
	await wait(4)
	if inside:
		await _scan(Vector2(-6.5, -44.6), Vector2(6.5, 0.6), 0.25, -36.3, -42.5, level.get_node("Interior/InsideSpawn").global_position, "dedans")
	else:
		await _scan(Vector2(-67.0, -67.0), Vector2(67.0, 67.0), 0.5, 26.0, -12.0, player.global_position, "dehors")
	for kind in problems:
		print("PROBLÈME %s : %d" % [kind, problems[kind]])
		for line in samples[kind]:
			print("    " + line)
	var keys := by_source.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return by_source[a] > by_source[b])
	for key in keys.slice(0, 40):
		print("  %4d  %s" % [by_source[key], key])
	check("grille %s sans problème (%d types)" % ["dedans" if inside else "dehors", problems.size()], problems.is_empty())
	finish()


## Couche visuelle : une forme de collision par maillage affiché, sur une couche que le joueur ignore.
func _build_visual_layer() -> void:
	visual_body = StaticBody3D.new()
	visual_body.collision_layer = VISUAL_LAYER
	visual_body.collision_mask = 0
	level.add_child(visual_body)
	_collect(level)


func _collect(node: Node) -> void:
	for child in node.get_children(true):
		if child is Node3D and not (child as Node3D).visible:
			continue
		var name := String(child.name)
		# Ni les corbeaux, ni la lave (elle brûle), ni l'herbe et les cailloux qu'on traverse, ni le joueur.
		if name in ["Life", "Player", "Hud", "TabletPuzzle"] or name.begins_with("GrassDetail") or name.begins_with("LavaFlow"):
			continue
		if child is MeshInstance3D and not (child is Label3D):
			var mesh_instance := child as MeshInstance3D
			if mesh_instance.mesh and not (mesh_instance.mesh is PlaneMesh) and not (mesh_instance.mesh is QuadMesh):
				_add_visual(mesh_instance.mesh, mesh_instance.global_transform, child)
		elif child is MultiMeshInstance3D:
			var multi := (child as MultiMeshInstance3D).multimesh
			if multi and multi.mesh and multi.visible_instance_count != 0:
				for index in multi.instance_count:
					_add_visual(multi.mesh, child.global_transform * multi.get_instance_transform(index), child)
		_collect(child)


func _add_visual(mesh: Mesh, at: Transform3D, owner_node: Node) -> void:
	# Le terrain n'y est pas : ses triangles, un résultat chacun, rempliraient les requêtes.
	if "Terrain" in String(level.get_path_to(owner_node)):
		return
	var box := mesh.get_aabb()
	# Les feuillets et les plaques très plates ne gênent pas le pas.
	if (at.basis * Vector3(0, box.size.y, 0)).length() < 0.06 and box.size.x * box.size.z < 0.25:
		return
	if not shape_cache.has(mesh):
		shape_cache[mesh] = mesh.create_trimesh_shape()
	var shape := CollisionShape3D.new()
	shape.shape = shape_cache[mesh]
	shape.transform = at
	shape.set_meta("source", String(level.get_path_to(owner_node)))
	visual_body.add_child(shape)


func _ground(x: float, z: float, top: float, bottom: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, bottom, z), SOLID)
	query.exclude = [player.get_rid()]
	return space.intersect_ray(query)


func _capsule(x: float, y: float, z: float, radius: float, height: float, mask: int) -> Array:
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), Vector3(x, y + height * 0.5, z))
	query.collision_mask = mask
	query.exclude = [player.get_rid()]
	return space.intersect_shape(query, 32)


func _scan(low: Vector2, high: Vector2, step: float, top: float, bottom: float, start: Vector3, label: String) -> void:
	var scatter: PlaineScatter = level.get_node("Exterior/Scatter")
	var size := Vector2i(ceili((high.x - low.x) / step), ceili((high.y - low.y) / step))
	var ground := {}
	var normal := {}
	var walkable := {}
	var floor_hit := {}
	for i in size.x + 1:
		for j in size.y + 1:
			var x := low.x + i * step
			var z := low.y + j * step
			if label == "dehors" and Vector2(x, z).length() > PlaineTerrain.LIMIT_RADIUS - 0.6:
				continue
			# Derrière la dalle, le plafond du passage est plus bas que celui des salles : le rayon part dessous.
			var hit := _ground(x, z, top if label == "dehors" or z > -36.3 else -37.1, bottom)
			if hit.is_empty():
				if (label == "dedans" and _in_rooms(x, z)) or (label == "dehors" and Vector2(x, z).length() < PlaineTerrain.LIMIT_RADIUS - 1.0):
					ground[Vector2i(i, j)] = NAN
				continue
			var cell := Vector2i(i, j)
			ground[cell] = hit.position.y
			normal[cell] = hit.normal.y
			floor_hit[cell] = _is_floor(x, hit.position.y, z, label)
			var lava := label == "dehors" and scatter.is_near_lava(Vector3(x, 0, z), 0.3)
			walkable[cell] = not lava and hit.normal.y > 0.7 and _capsule(x, hit.position.y + 0.15, z, 0.4, 1.8, SOLID).is_empty()
	# Zone accessible depuis la case marchable la plus proche du point de départ, pas à pas.
	var origin := Vector2i(roundi((start.x - low.x) / step), roundi((start.z - low.y) / step))
	var best := origin
	var nearest := INF
	for cell: Vector2i in walkable:
		if walkable[cell] and Vector2(cell - origin).length() < nearest:
			nearest = Vector2(cell - origin).length()
			best = cell
	var reached := {best: true}
	var queue: Array[Vector2i] = [best]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + offset
			if reached.has(next) or not walkable.get(next, false):
				continue
			if absf(ground[next] - ground[cell]) > maxf(0.4, step * 0.75):
				continue
			reached[next] = true
			queue.append(next)
	print("%s : %d cases accessibles sur %d marchables" % [label, reached.size(), walkable.values().count(true)])
	var pockets := {}
	for cell: Vector2i in ground:
		var x := low.x + cell.x * step
		var z := low.y + cell.y * step
		var y: float = ground[cell]
		if is_nan(y):
			report("trou (aucun sol)", Vector3(x, 0, z))
			continue
		if walkable.get(cell, false) and not reached.has(cell) and floor_hit.get(cell, false) \
				and (label == "dehors" or _in_rooms(x, z)):
			pockets[cell] = y
		if not reached.has(cell):
			continue
		if normal.get(cell, 1.0) < 0.707:
			report("pente où l'on glisse", Vector3(x, y, z), "normale %.2f" % normal[cell])
		for offset in [Vector2i(1, 0), Vector2i(0, 1)]:
			var next: Vector2i = cell + offset
			if ground.has(next) and not is_nan(ground[next]) and floor_hit.get(cell, false) and floor_hit.get(next, false):
				var drop := absf(ground[next] - y)
				# Une vraie marche, pas une pente : le milieu n'est pas entre les deux hauteurs.
				var middle := _ground(x + offset.x * step * 0.5, z + offset.y * step * 0.5, maxf(y, ground[next]) + 1.0, minf(y, ground[next]) - 1.0)
				var smooth := not middle.is_empty() and absf(middle.position.y - (y + ground[next]) * 0.5) < 0.12
				if drop > 0.4 and walkable.get(next, false) and not smooth:
					report("marche de plus de 0,4 m", Vector3(x, y, z), "%.2f m" % drop)
		# Maillage visible que l'on traverse, du genou à la tête.
		var seen := _capsule(x, y + 0.3, z, 0.33, 1.5, VISUAL_LAYER)
		for hit in seen:
			var source: String = hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape)).get_meta("source", "?")
			if "Terrain" in source:
				continue
			report("maillage visible sans collision", Vector3(x, y, z), source)
			break
		if label == "dedans":
			var up := PhysicsRayQueryParameters3D.create(Vector3(x, y + 1.0, z), Vector3(x, y + 6.0, z), SOLID)
			if space.intersect_ray(up).is_empty():
				report("plafond absent", Vector3(x, y, z))
	# Zones fermées : sol marchable qu'on n'atteint pas, en régions d'au moins 1 m² (pas les recoins d'une case).
	var visited := {}
	for cell: Vector2i in pockets:
		if visited.has(cell):
			continue
		var region: Array[Vector2i] = [cell]
		visited[cell] = true
		var index := 0
		while index < region.size():
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var next: Vector2i = region[index] + offset
				if pockets.has(next) and not visited.has(next):
					visited[next] = true
					region.append(next)
			index += 1
		if region.size() * step * step >= 1.0:
			var first := region[0]
			report("sol marchable inaccessible (zone fermée)", Vector3(low.x + first.x * step, pockets[first], low.y + first.y * step), "%.1f m²" % (region.size() * step * step))
	# Murs invisibles : bloqué sans rien de visible à moins de 0,5 m, au bord de la zone accessible.
	for cell: Vector2i in reached:
		var y: float = ground[cell]
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + offset
			if reached.has(next) or not ground.has(next) or is_nan(ground[next]):
				continue
			var x := low.x + next.x * step
			var z := low.y + next.y * step
			var ny: float = ground[next]
			if absf(ny - y) > 0.4 or normal.get(next, 1.0) < 0.707:
				continue
			if label == "dehors" and scatter.is_near_lava(Vector3(x, 0, z), 0.3):
				continue
			var blockers := _capsule(x, ny + 0.15, z, 0.4, 1.8, SOLID)
			if blockers.is_empty():
				continue
			if _visible_near(x, ny, z):
				continue
			var culprit := {}
			for blocker in blockers:
				var body: CollisionObject3D = blocker.collider
				var owner_part: Node3D = body.shape_owner_get_owner(body.shape_find_owner(blocker.shape))
				if not owner_part.name.begins_with("Limit") and not String(body.get_path()).contains("Terrain"):
					culprit = blocker
					break
			if culprit.is_empty():
				continue
			var what: CollisionObject3D = culprit.collider
			var part: Node3D = what.shape_owner_get_owner(what.shape_find_owner(culprit.shape))
			report("mur invisible", Vector3(x, ny, z), "%s/%s en %s" % [level.get_path_to(what), part.name, part.global_position.snappedf(0.01)])
	_save_map(low, size, step, ground, reached, label)


## Emprise des salles, de l'escalier et de la petite salle, où il doit y avoir un sol partout.
func _in_rooms(x: float, z: float) -> bool:
	if absf(x) < 5.7 and z < -0.3 and z > -35.7:
		return true
	return absf(x) < 1.7 and z < -36.3 and z > -43.7


## Un maillage visible (autre que le terrain) à moins de 0,5 m d'un joueur posé là.
func _visible_near(x: float, y: float, z: float) -> bool:
	# Un cylindre à fond plat : il voit aussi les bords bas d'un rocher, qu'une capsule laisse passer dessous.
	var shape := CylinderShape3D.new()
	shape.radius = 0.9
	shape.height = 1.9
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), Vector3(x, y + 0.03 + 0.95, z))
	query.collision_mask = VISUAL_LAYER
	for hit in space.intersect_shape(query, 32):
		var source: String = hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape)).get_meta("source", "?")
		if not ("Terrain" in source):
			return true
	return false


## Sol où l'on marche : le terrain et le tablier du pont dehors, les dalles des salles et de l'escalier dedans,
## pas le dessus d'un meuble ou d'un rocher.
func _is_floor(x: float, y: float, z: float, label: String) -> bool:
	if label == "dehors":
		return absf(y - (level.get_node("Exterior/Terrain") as PlaineTerrain).surface_height(x, z)) < 0.12
	if absf(y + 40.0) < 0.03 or absf(y + 41.0) < 0.03:
		return true
	return z < -36.6 and z > -38.6 and absf(x) < 1.75


func _save_map(low: Vector2, size: Vector2i, step: float, ground: Dictionary, reached: Dictionary, label: String) -> void:
	var image := Image.create(size.x + 1, size.y + 1, false, Image.FORMAT_RGB8)
	image.fill(Color(0.1, 0.1, 0.12))
	for cell: Vector2i in ground:
		var color := Color(0.6, 0.15, 0.15) if is_nan(ground[cell]) else Color(0.3, 0.3, 0.32)
		if reached.has(cell):
			color = Color(0.3, 0.7, 0.35)
		image.set_pixelv(cell, color)
	image.resize((size.x + 1) * 3, (size.y + 1) * 3, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + label + ".png")
