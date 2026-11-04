extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Grille de marche des marais (avec fenêtre : les MultiMesh des arbres sont lus).
## Toute la surface accessible, dehors (îlots du parcours, pontons, débarcadère, eaux peu profondes) et dans chaque
## pièce de la crypte, par une grille de 0,5 m : sol trouvé par un rayon ; dans 8 directions, un pas d'essai du
## joueur (test_move) relève les blocages ; un blocage sans maillage visible à moins de 0,5 m est un mur invisible ;
## un point bloqué de tous côtés est un piège. Entre deux points voisins, un écart de plus de 0,4 m hors escalier
## est une marche. Sur une grille de 2 m, le joueur marche vraiment 0,5 s dans chaque direction : coincé, glissade,
## chute, trou. Enfin, chaque maillage de plus de 0,3 m posé là où l'on marche doit avoir sa collision.
## Résultat dans agents/marais/walkgrid.txt, une ligne par problème, avec ses coordonnées.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/walkgrid.txt"
const STEP := 0.5
const WALK_STEP := 2.0
const SINK := -0.85
# Zones accessibles du dehors : îlots du parcours (centre, rayon), pontons et débarcadère (segments, demi-largeur).
const ISLANDS := [Vector3(0, 56, 14.5), Vector3(-20, 22, 10.5), Vector3(16, 0, 21.0), Vector3(0, -36, 18.0)]
const WALKS := [Vector4(-3, 48, -18, 27), Vector4(-16, 19, 6, 4), Vector4(8.5, -10, 3, -28), Vector4(7.6, 53.2, 14.2, 51.2)]
# Escalier de la crypte : là, les écarts de hauteur sont attendus.
const STAIRS := Rect2(-1.6, 1.8, 3.2, 8.8)
# Noms de modèles sans collision voulue : végétation souple, décor posé sur un support, petits objets, effets.
const SOFT := ["moss", "hanging", "banner", "flag", "candle", "lily", "flower", "grass", "plant", "bush", "mushroom",
	"path_", "grave_", "debris", "paddle", "ghost", "fish", "reed", "bamboo", "log", "stump_old", "lantern_candle",
	"urn", "skeleton", "shield", "spear", "sword", "chalice", "crop", "stones", "resource", "bedroll", "road",
	"chimney", "roof", "watermill", "wall_wood", "fence_broken", "trunk_long", "campfire", "bucket"]

var _lines: Array[String] = []
var _visuals: Array[AABB] = []
var _cells := {}
var _trees: Array[Vector3] = []
var _space: PhysicsDirectSpaceState3D
var _capsule := CapsuleShape3D.new()
var _counts := {}


func _initialize() -> void:
	_run.call_deferred()


func report(kind: String, at: Vector3, detail := "") -> void:
	_counts[kind] = _counts.get(kind, 0) + 1
	if _counts[kind] <= 40:
		_lines.append("%s (%.1f, %.1f, %.1f) %s" % [kind, at.x, at.y, at.z, detail])


func _run() -> void:
	var mode: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "dehors"
	await start_level("res://scenes/levels/marais/marais.tscn")
	# Avec une fenêtre en arrière-plan, la perte du focus ouvrirait la pause et figerait le joueur.
	root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
	paused = false
	_space = player.get_world_3d().direct_space_state
	_capsule.radius = 0.38
	_capsule.height = 1.7
	# Le niveau ne dessine que le côté où l'on est : pour la grille, la crypte et le dehors sont visibles ensemble.
	level.get_node("Interior").visible = true
	_collect_visuals(level)
	level.set("_inside", true)  # Pas d'enlisement pendant la grille : on veut tout sonder.
	await wait(10)
	var count := 0
	if mode == "dehors":
		var outside := _grid_outside()
		count = outside.size()
		await _probe(outside, "dehors", 4.0)
	elif mode == "crypte":
		var inside := _grid_inside()
		count = inside.size()
		await _probe(inside, "crypte", 2.0)
	else:
		_check_bare_meshes()
	_lines.append("")
	for kind in _counts:
		_lines.append("TOTAL %s : %d" % [kind, _counts[kind]])
	var file := FileAccess.open(OUT.replace(".txt", "_%s.txt" % mode), FileAccess.WRITE)
	file.store_string("\n".join(_lines) + "\n")
	file.close()
	for kind in _counts:
		print("PROBLEME %s : %d" % [kind, _counts[kind]])
	check("grille de marche (%s) : %d points" % [mode, count], true)
	finish()


## Tous les nœuds, enfants internes compris (les planches des SignBoard sont internes).
func _walk_tree(node: Node, into: Array[Node]) -> void:
	into.append(node)
	for child in node.get_children(true):
		_walk_tree(child, into)


func _add_visual(box: AABB) -> void:
	_visuals.append(box)
	var index := _visuals.size() - 1
	var low := Vector3i((box.position / 4.0).floor())
	var high := Vector3i((box.end / 4.0).floor())
	if (high - low).length() > 30:
		return
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				var key := Vector3i(x, y, z)
				if not _cells.has(key):
					_cells[key] = PackedInt32Array()
				_cells[key].append(index)


## Boîtes des maillages visibles (hors sol, eau, brume, ciel), et troncs des arbres dispersés.
func _collect_visuals(root_node: Node) -> void:
	var nodes: Array[Node] = []
	_walk_tree(root_node, nodes)
	for node in nodes:
		var item := node as GeometryInstance3D
		if not item or not item.is_visible_in_tree():
			continue
		var path := String(level.get_path_to(item))
		if path.begins_with("Terrain") or path.begins_with("Water") or path.begins_with("GroundFog") or path.begins_with("MoonDisc"):
			continue
		if item is MultiMeshInstance3D:
			var mm := (item as MultiMeshInstance3D).multimesh
			if not mm or not mm.mesh:
				continue
			var box := mm.mesh.get_aabb()
			for t: Transform3D in _instances(item as MultiMeshInstance3D):
				var world := t * box
				if world.size.y > 2.5 and String(item.get_parent().name) == "Scatter":
					_trees.append(t.origin)
				_add_visual(world)
		elif item is MeshInstance3D and (item as MeshInstance3D).mesh:
			# Décor fondu par matériau (MaraisBatch) : la boîte de chaque modèle, pas celle de toute la case.
			if item.has_meta(&"pieces"):
				for piece: Array in item.get_meta(&"pieces"):
					_add_visual(piece[1])
			else:
				_add_visual(item.global_transform * (item as MeshInstance3D).mesh.get_aabb())
		elif item is Label3D:
			_add_visual(item.global_transform * item.get_aabb())


func _visible_near(point: Vector3, margin: float) -> bool:
	var seen := {}
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var key := Vector3i(((point + Vector3(dx, dy, dz) * margin) / 4.0).floor())
				if seen.has(key) or not _cells.has(key):
					continue
				seen[key] = true
				for index in _cells[key]:
					if _visuals[index].grow(margin).has_point(point):
						return true
	return false


func _in_walks(point: Vector2, margin: float) -> bool:
	for walk in WALKS:
		var a := Vector2(walk.x, walk.y)
		var b := Vector2(walk.z, walk.w)
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b)) < 1.2 + margin:
			return true
	return false


func _grid_outside() -> Array[Vector3]:
	var points: Array[Vector3] = []
	var x := -30.0
	while x <= 40.0:
		var z := -55.0
		while z <= 70.0:
			var spot := Vector2(x, z)
			var wanted := _in_walks(spot, 0.0)
			for island in ISLANDS:
				if spot.distance_to(Vector2(island.x, island.y)) < island.z:
					wanted = true
			if wanted:
				var floor := _floor(Vector3(x, 6.0, z), -3.0)
				if floor != Vector3.INF and floor.y > SINK:
					points.append(floor)
			z += STEP
		x += STEP
	return points


func _grid_inside() -> Array[Vector3]:
	var points: Array[Vector3] = []
	var x := -30.0
	while x <= 30.0:
		var z := -22.0
		while z <= 14.5:
			# Juste sous le plafond (4,15 m), plus haut au-dessus de l'escalier et du palier.
			var top := -40.0 + (8.0 if STAIRS.has_point(Vector2(x, z)) or (absf(x) < 1.6 and z > 10.0) else 3.9)
			var floor := _floor(Vector3(x, top, z), -41.0)
			if floor != Vector3.INF:
				points.append(floor)
			z += STEP
		x += STEP
	return points


func _floor(from: Vector3, bottom: float) -> Vector3:
	var ray := PhysicsRayQueryParameters3D.create(from, Vector3(from.x, bottom, from.z))
	ray.exclude = [player.get_rid()]
	var hit := _space.intersect_ray(ray)
	if hit.is_empty():
		return Vector3.INF
	if (hit.normal as Vector3).y < 0.7:
		return Vector3.INF
	var top: Vector3 = hit.position
	# Le dessus d'un objet (tombeau, coffre, autel, stèle) n'est pas le sol où l'on marche : sous lui, un autre
	# sol praticable, plus bas de 0,45 m. Un ponton, lui, domine l'eau profonde.
	var below := PhysicsRayQueryParameters3D.create(top + Vector3.DOWN * 0.05, top + Vector3.DOWN * 9.0)
	below.exclude = [player.get_rid()]
	var under := _space.intersect_ray(below)
	if not under.is_empty() and top.y - (under.position as Vector3).y > 0.45 and ((under.position as Vector3).y > SINK or top.y < -20.0 or top.y > 0.6):
		return Vector3.INF
	return top


## La capsule du joueur tient-elle debout ici ?
func _fits(feet: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _capsule
	query.transform = Transform3D(Basis(), feet + Vector3.UP * 0.92)
	query.exclude = [player.get_rid()]
	return _space.intersect_shape(query, 1).is_empty()


func _probe(points: Array[Vector3], label: String, walk_step: float) -> void:
	var heights := {}
	var stood := 0
	for feet in points:
		if not _fits(feet):
			continue
		stood += 1
		var key := Vector2i(roundi(feet.x / STEP), roundi(feet.z / STEP))
		heights[key] = feet.y
		var blocked := 0
		for step in 8:
			var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * step / 8.0)
			var collision := KinematicCollision3D.new()
			var start := Transform3D(Basis(), feet + Vector3.UP * 0.06)
			if player.test_move(start, direction * STEP, collision, 0.001, true):
				var normal := collision.get_normal()
				if absf(normal.y) > 0.7:
					continue
				var collider := collision.get_collider() as Node
				var shape_owner := ""
				if collider is CollisionObject3D:
					var owner_id := (collider as CollisionObject3D).shape_find_owner(collision.get_collider_shape_index())
					var shape_node := (collider as CollisionObject3D).shape_owner_get_owner(owner_id)
					shape_owner = String(shape_node.name) if shape_node else ""
				if shape_owner.begins_with("Limit"):
					continue
				blocked += 1
				var contact := collision.get_position()
				var tree: bool = String(level.get_path_to(collider)).begins_with("Scatter/Trees") or _tree_near(contact)
				if not _visible_near(contact, 0.5) and not tree:
					report("mur invisible", contact, "(%s, %s)" % [label, String(level.get_path_to(collider)) + "/" + shape_owner])
		if blocked == 8:
			report("piege", feet, label)
	# Marches : deux points voisins accessibles à plus de 0,4 m l'un de l'autre, hors escalier.
	for key: Vector2i in heights:
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
			var other: Vector2i = key + offset
			if not heights.has(other):
				continue
			var a: float = heights[key]
			var b: float = heights[other]
			var at := Vector3(key.x * STEP, maxf(a, b), key.y * STEP)
			if absf(a - b) > 0.4 and not STAIRS.has_point(Vector2(at.x, at.z)):
				var deck := minf(a, b) < 0.0 and maxf(a, b) > 0.2
				report("bord de ponton (attendu)" if deck and label == "dehors" else "marche", at, "%.2f m (%s)" % [absf(a - b), label])
	print("%s : %d points, %d où le joueur tient" % [label, points.size(), stood])
	# Marche réelle sur une grille de 2 m.
	var tested := 0
	for feet in points:
		if fmod(absf(feet.x), walk_step) > 0.01 or fmod(absf(feet.z), walk_step) > 0.01 or not _fits(feet):
			continue
		tested += 1
		for step in 8:
			player.global_position = feet + Vector3.UP * 0.05
			player.velocity = Vector3.ZERO
			await physics_frame
			var pivot: Node3D = player.get_node("CameraPivot")
			pivot.rotation.y = TAU * step / 8.0
			var free: bool = not player.test_move(Transform3D(Basis(), feet + Vector3.UP * 0.06), Vector3.FORWARD.rotated(Vector3.UP, TAU * step / 8.0) * 1.0)
			Input.action_press("move_forward")
			for i in 24:
				await physics_frame
			Input.action_release("move_forward")
			var moved := Vector2(player.global_position.x - feet.x, player.global_position.z - feet.z).length()
			if free and moved < 0.3:
				report("coince", feet, "direction %d (%s)" % [step, label])
			if player.global_position.y < feet.y - 1.6 and player.global_position.y > -20.0 or (label == "crypte" and player.global_position.y < -40.6):
				report("chute", player.global_position, "depuis (%.1f, %.1f) (%s)" % [feet.x, feet.z, label])
			var before := player.global_position
			for i in 12:
				await physics_frame
			if Vector2(player.global_position.x - before.x, player.global_position.z - before.z).length() > 0.4:
				report("glissade", before, label)
	print("%s : marche réelle en %d points" % [label, tested])


func _tree_near(point: Vector3) -> bool:
	for tree in _trees:
		if Vector2(tree.x - point.x, tree.z - point.z).length() < 1.0:
			return true
	return false


## Transformations (monde) des instances d'un MultiMesh : celles que MaraisBatch garde en métadonnées (lisibles sans
## affichage), sinon celles du serveur de rendu.
func _instances(item: MultiMeshInstance3D) -> Array[Transform3D]:
	var places: Array[Transform3D] = []
	if item.has_meta(&"transforms"):
		places.assign(item.get_meta(&"transforms"))
		return places
	for index in item.multimesh.instance_count:
		places.append(item.global_transform * item.multimesh.get_instance_transform(index))
	return places


## Maillages de plus de 0,3 m, posés là où l'on marche, sans aucune collision dans leur volume. Le décor fixe est
## fondu par matériau (MaraisBatch) : chacun de ses modèles compte comme un maillage, sous son nom et avec sa boîte.
func _check_bare_meshes() -> void:
	var checked := {}
	var pieces: Array = []
	for root: Node in [level.get_node("Props"), level.get_node("Grounded"), level.get_node("Interior"), level.get_node("Scatter")]:
		for node in root.find_children("*", "MeshInstance3D", true, false):
			if String(root.name) != "Scatter" or node.has_meta(&"pieces"):
				var mesh := node as MeshInstance3D
				if not mesh.mesh or not mesh.is_visible_in_tree():
					continue
				if mesh.has_meta(&"pieces"):
					for piece: Array in mesh.get_meta(&"pieces"):
						pieces.append([(String(level.get_path_to(mesh)) + "/" + String(piece[0])).to_lower(), piece[1]])
				else:
					pieces.append([String(level.get_path_to(mesh)).to_lower(), mesh.global_transform * mesh.mesh.get_aabb()])
		for node in root.find_children("Batch_*", "MultiMeshInstance3D", true, false):
			var batch := node as MultiMeshInstance3D
			if not batch.is_visible_in_tree():
				continue
			var name := (String(level.get_path_to(batch)) + "/" + String(batch.get_meta(&"model", ""))).to_lower()
			for place in _instances(batch):
				pieces.append([name, place * batch.multimesh.mesh.get_aabb()])
	for piece: Array in pieces:
		if true:
			var path: String = piece[0]
			var soft := false
			for word in SOFT:
				if path.contains(word):
					soft = true
			if soft:
				continue
			var box: AABB = piece[1]
			if box.size.y < 0.3 or box.size.x * box.size.z < 0.01:
				continue
			# Seulement là où l'on marche : îlots du parcours, pontons, crypte.
			var spot := Vector2(box.get_center().x, box.get_center().z)
			var reachable := box.position.y < -20.0 or _in_walks(spot, 1.0)
			for island in ISLANDS:
				if spot.distance_to(Vector2(island.x, island.y)) < island.z:
					reachable = true
			if not reachable:
				continue
			var key := Vector3i(box.get_center().round())
			if checked.has(key):
				continue
			checked[key] = true
			var query := PhysicsShapeQueryParameters3D.new()
			var shape := BoxShape3D.new()
			shape.size = (box.size * Vector3(0.7, 0.8, 0.7)).max(Vector3.ONE * 0.05)
			query.shape = shape
			query.transform = Transform3D(Basis(), box.get_center())
			query.exclude = [player.get_rid()]
			var solid := false
			for hit in _space.intersect_shape(query, 8):
				var collider: Object = hit.collider
				if collider is StaticBody3D and not String(level.get_path_to(collider as Node)).begins_with("Terrain"):
					solid = true
			if not solid:
				report("sans collision", box.get_center(), path)
