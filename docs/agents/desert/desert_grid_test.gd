extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_audit_test.gd"
## Grille de marche du désert, dehors et dans la cave, au pas de 0,5 m sur toute la surface accessible depuis l'arrivée :
## - trous (aucun sol sous un point de la zone de jeu), pentes où l'on glisse (plus de 40 degrés) ;
## - marches de plus de 0,4 m entre deux points voisins où l'on tient debout (hors escalier) ;
## - points où le joueur est coincé (les 8 directions bloquées à 0,5 m) ;
## - murs invisibles : un blocage dont le point de contact n'a aucun triangle visible à moins de 0,5 m
##   (la limite de la carte, voulue invisible, est mise à part).
## Les blocages se testent par le moteur physique (body_test_motion) avec le corps du joueur.

const DIRECTIONS := 8
const STEP := 0.5
const HASH := 4.0

var _mesh_hash := {}
var _reports := {}
var _seen := {}


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	space = player.get_world_3d().direct_space_state
	terrain = level.get_node("Exterior/Terrain")
	player_rid = player.get_rid()
	capsule.radius = 0.36
	capsule.height = 1.7
	# Le corps du joueur reste dans l'espace physique (un nœud désactivé en sortirait) : il ne bouge simplement plus.
	player.set_physics_process(false)
	await wait(5)
	_collect_visuals(level)
	_build_hash()
	for inside in [false, true]:
		set_inside(inside)
		await wait(5)
		var start: Vector3 = Vector3(0, 0, 48) if not inside else level.get_node("Interior/InsideSpawn").global_position
		build_reach(start, inside)
		var label := "cave" if inside else "surface"
		print("GRILLE %s : %d points accessibles" % [label, reach.size()])
		_scan(inside, label)
		await wait(2)
	var total := 0
	for kind: String in _reports:
		var list: Array = _reports[kind]
		total += list.size()
		print("GRILLE %s : %d" % [kind, list.size()])
		# D'abord les contacts sans rien de visible à moins d'un mètre, tous ; puis les 40 premiers des autres.
		var far := list.filter(func(entry: String) -> bool: return "à 2 m" in entry)
		print("GRILLE   dont rien de visible à moins d'1 m : %d" % far.size())
		for entry in far:
			print("    " + entry)
		for entry in list.filter(func(entry: String) -> bool: return not "à 2 m" in entry).slice(0, 40):
			print("    " + entry)
	check("grille de marche sans problème (%d)" % total, total == 0)
	finish()


func _report(kind: String, where: Vector3, detail := "") -> void:
	if not _reports.has(kind):
		_reports[kind] = []
	var key := "%s %s" % [Vector3(roundf(where.x), roundf(where.y * 2.0) / 2.0, roundf(where.z)), detail]
	if not key in _reports[kind]:
		_reports[kind].append(key)


func _scan(inside: bool, label: String) -> void:
	var params := PhysicsTestMotionParameters3D.new()
	var result := PhysicsTestMotionResult3D.new()
	for key: Vector2i in reach:
		var p := cell_position(key)
		# Pente du sol sous le point.
		# Les crêtes du bord de la carte, au-delà de 60 m, sont raides à dessein.
		var border := Vector2(p.x, p.z).length() > 60.0 and not inside
		var floor_hit := ray(p + Vector3.UP * 0.4, p + Vector3.DOWN * 0.4, [player_rid])
		if not border and not floor_hit.is_empty() and floor_hit.normal.y < cos(deg_to_rad(44.0)):
			_report("pente glissante (%s)" % label, p)
		# Marches entre voisins.
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
			var other: Variant = reach.get(key + offset)
			if other != null and not border and absf(float(other) - p.y) > 0.4:
				_report("marche de plus de 0,4 m (%s)" % label, p, "%.2f m" % absf(float(other) - p.y))
		# Blocages dans 8 directions, seulement au bord de la zone accessible : ailleurs, tout est libre autour.
		var inner := true
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			if not reach.has(key + offset):
				inner = false
				break
		if inner:
			continue
		var blocked := 0
		for index in DIRECTIONS:
			var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * index / DIRECTIONS)
			params.from = Transform3D(Basis(), p + Vector3.UP * 0.12)
			params.motion = direction * STEP
			params.margin = 0.001
			if not PhysicsServer3D.body_test_motion(player_rid, params, result):
				continue
			var normal := result.get_collision_normal()
			# Une pente qu'on gravit n'est pas un blocage.
			if normal.y > 0.7:
				continue
			blocked += 1
			var contact := result.get_collision_point()
			var collider := result.get_collider() as Node
			if collider == terrain and result.get_collider_shape() > 0:
				continue
			var cache_key := Vector3i(roundi(contact.x * 2.0), roundi(contact.y * 2.0), roundi(contact.z * 2.0))
			if _seen.has(cache_key):
				continue
			_seen[cache_key] = true
			if not _visible_near(contact, 0.5):
				var near := "rien à 2 m"
				for radius: float in [1.0, 2.0]:
					if _visible_near(contact, radius):
						near = "visible à %.0f m" % radius
						break
				_report("mur invisible (%s)" % label, contact, "%s forme %d, %s, contact %s" % [
					str(collider.get_path()).replace("/root/Desert/", "") if collider else "?", result.get_collider_shape(), near, contact.snappedf(0.05)])
		if blocked == DIRECTIONS:
			_report("joueur coincé (%s)" % label, p)
	# Trous : points de la zone de jeu sans aucun sol (hors sables mouvants).
	if not inside:
		for i in 133:
			for j in 133:
				var x := -66.0 + i + JITTER
				var z := -66.0 + j + JITTER
				if Vector2(x, z).length() > DesertTerrain.LIMIT_RADIUS - 1.0 or in_quicksand(x, z):
					continue
				var top: float = terrain.surface_height(x, z)
				if ray(Vector3(x, top + 3.0, z), Vector3(x, top - 1.0, z), [player_rid]).is_empty():
					_report("trou dans le sol (surface)", Vector3(x, top, z))


func _build_hash() -> void:
	for mesh in meshes:
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		_hash_box(box, [mesh, -1])
	for instance in multimeshes:
		var local_box := instance.multimesh.mesh.get_aabb()
		for index in instance.multimesh.instance_count:
			var xform := instance.global_transform * instance.multimesh.get_instance_transform(index)
			_hash_box(xform * local_box, [instance, index])


func _hash_box(box: AABB, entry: Array) -> void:
	if box.size.length() > 200.0:
		return
	for i in range(floori(box.position.x / HASH), floori(box.end.x / HASH) + 1):
		for j in range(floori(box.position.z / HASH), floori(box.end.z / HASH) + 1):
			var key := Vector2i(i, j)
			if not _mesh_hash.has(key):
				_mesh_hash[key] = []
			_mesh_hash[key].append(entry)


## Un triangle visible à moins de r du point : six petits segments autour de lui contre les maillages proches.
func _visible_near(point: Vector3, r: float) -> bool:
	var segments: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.UP, Vector3.DOWN]
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				segments.append(Vector3(sx, sy, sz).normalized())
	# Le terrain est trop grand pour la table : il se teste à part, par sa hauteur.
	var ground: float = terrain.surface_height(point.x, point.z)
	if point.y > -20.0 and absf(ground - point.y) < r:
		return true
	# Toutes les cases de la table que touche la sphère de rayon r : un mur dont la face tombe pile sur le bord
	# d'une case (x = 12 avec des cases de 4 m) n'est rangé que dans la case voisine.
	var entries := {}
	for i in range(floori((point.x - r) / HASH), floori((point.x + r) / HASH) + 1):
		for j in range(floori((point.z - r) / HASH), floori((point.z + r) / HASH) + 1):
			for entry: Array in _mesh_hash.get(Vector2i(i, j), []):
				entries[entry] = true
	for entry: Array in entries.keys():
		var node: GeometryInstance3D = entry[0]
		if not is_instance_valid(node) or not node.is_visible_in_tree():
			continue
		var xform: Transform3D
		var shape: TriangleMesh
		var local_box: AABB
		if entry[1] < 0:
			var mesh := node as MeshInstance3D
			xform = mesh.global_transform
			shape = tri(mesh.mesh)
			local_box = mesh.get_aabb()
		else:
			var instance := node as MultiMeshInstance3D
			xform = instance.global_transform * instance.multimesh.get_instance_transform(entry[1])
			shape = tri(instance.multimesh.mesh)
			local_box = instance.multimesh.mesh.get_aabb()
		if not (xform * local_box).grow(r).has_point(point):
			continue
		var inverse := xform.affine_inverse()
		for direction in segments:
			if not shape.intersect_segment(inverse * (point - direction * r), inverse * (point + direction * r)).is_empty():
				return true
	return false
