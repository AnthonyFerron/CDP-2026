extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Passe au centimètre du Village : grille de marche. À lancer avec une fenêtre (les MultiMesh y gardent leurs copies).
## Arguments après -- :
##   grille     grille de 0,5 m dehors et dans la mairie : trous, marches, murs invisibles, maillages sans collision ;
##   marche N   le vrai joueur posé tous les 4 m (bande N sur 3 en z) marche 0,5 s dans 8 directions ;
##   dedans     même chose dans la mairie tous les mètres, avec un saut en chaque point (plafonds) ;
##   passages   escaliers montés et descendus de partout, portes et passages dans les deux sens,
##              invites des interactables depuis les quatre côtés.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/village/"
const STEP := 0.5
const CLIMB := 0.36
const RADIUS := 0.38
const HEIGHT := 1.8
const DIRECTIONS := [Vector3(1, 0, 0), Vector3(0.7071, 0, 0.7071), Vector3(0, 0, 1), Vector3(-0.7071, 0, 0.7071),
	Vector3(-1, 0, 0), Vector3(-0.7071, 0, -0.7071), Vector3(0, 0, -1), Vector3(0.7071, 0, -0.7071)]
## Ce qui n'a pas à arrêter le joueur : herbes, fleurs, oiseaux, chats, tissus, braises, petits objets.
const SOFT := ["Crows/", "Cats/", "Dust", "Embers", "Smokes/", "WheelSplash", "Fires/", "banner", "flag", "lantern_candle",
	"linen", "rope", "herb", "parchment", "grass", "flower", "bush", "plant_", "crop", "wheat", "corn", "leafs", "coin",
	"plate", "mug", "books", "potion", "candle", "bucket", "bottle", "tool_", "weapon", "shield", "arrow", "bread", "apple",
	"carrot", "cheese", "pear", "fish", "onion", "leek", "cabbage", "egg", "honey", "loaf", "croissant", "rollingPin",
	"mortar", "soot", "ash", "flour", "water", "ember", "rug", "planks", "dirt", "Stream", "Interior/Railing",
	"Interior/Slabs", "Device/", "SecretShelf/", "Book/", "Signs/", "Lore/", "window_glow", "roof", "plaster",
	"Portal", "Player", "cat_", "crow", "eye", "beak", "burlap", "straw", "leather", "iron", "resource-stone",
	"resource_stone", "debris-wood", "debris_wood", "campfire", "bag_flat", "bag-flat", "statue_columnDamaged", "bedroll",
	"size_0p05_0p6_0p05", "size_0p36_0p04_1p0"]

var space: PhysicsDirectSpaceState3D
var capsule := CapsuleShape3D.new()
var visuals: Array[AABB] = []
var visual_names: Array[String] = []
var visual_hash := {}
var problems: Array[String] = []
var terrain_rid: RID
var debug_scatter := false


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
	capsule.radius = RADIUS
	capsule.height = HEIGHT
	terrain_rid = level.get_node("Terrain").get_rid()
	await wait(10)
	match args[0] if not args.is_empty() else "grille":
		"grille":
			debug_scatter = args.has("debug")
			collect_visuals()
			print("éléments visibles relevés : %d" % visuals.size())
			var outside := flood(Vector3(0, 0.5, 57), Rect2(-75, -75, 150, 150))
			grid(outside, "dehors")
			var hall := flood(level.get_node("Interior/InsideSpawn").global_position, Rect2(-20, -10, 32, 20))
			grid(hall, "mairie")
			missing_collisions()
			# En dernier : les fantômes des maillages ajoutés ici ne doivent pas gêner les autres essais.
			await entered_meshes(outside)
			await entered_meshes(hall)
		"marche":
			await walk_band(int(args[1]), int(args[2]) if args.size() > 2 else 3)
		"dedans":
			await walk_inside()
		"passages":
			await passages()
	for line in problems:
		print("PROBLEME " + line)
	check("%s : %d problème(s)" % [" ".join(args), problems.size()], problems.is_empty())
	finish()


# --- Éléments visibles ----------------------------------------------------------------------------------------

func collect_visuals() -> void:
	_collect(level)
	for index in visuals.size():
		var box := visuals[index]
		for gx in range(floori(box.position.x / 2.0), floori(box.end.x / 2.0) + 1):
			for gz in range(floori(box.position.z / 2.0), floori(box.end.z / 2.0) + 1):
				var key := Vector2i(gx, gz)
				if not visual_hash.has(key):
					visual_hash[key] = []
				visual_hash[key].append(index)


func _collect(node: Node) -> void:
	if node is Label3D or node is CPUParticles3D or node == level.get_node("Terrain"):
		return
	if node is MultiMeshInstance3D:
		var multimesh := (node as MultiMeshInstance3D).multimesh
		if multimesh and multimesh.mesh:
			var local := multimesh.mesh.get_aabb()
			for index in multimesh.instance_count:
				_add_visual((node as Node3D).global_transform * multimesh.get_instance_transform(index) * local, node)
	elif node is MeshInstance3D and (node as MeshInstance3D).mesh:
		_add_visual((node as Node3D).global_transform * (node as MeshInstance3D).get_aabb(), node)
	for child in node.get_children(true):
		_collect(child)


func _add_visual(box: AABB, node: Node) -> void:
	if box.size.length() < 0.01:
		return
	visuals.append(box)
	var path := str(level.get_path_to(node))
	if node is MultiMeshInstance3D and (node as MultiMeshInstance3D).material_override:
		path += ":" + (node as MultiMeshInstance3D).material_override.resource_name
	elif node is MeshInstance3D and (node as MeshInstance3D).material_override:
		path += ":" + (node as MeshInstance3D).material_override.resource_name
	elif node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh.mesh:
		path += ":" + (node as MultiMeshInstance3D).multimesh.mesh.resource_name
	visual_names.append(path)


func visible_near(point: Vector3, margin: float) -> bool:
	var key := Vector2i(floori(point.x / 2.0), floori(point.z / 2.0))
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			for index: int in visual_hash.get(key + Vector2i(dx, dz), []):
				if visuals[index].grow(margin).has_point(point):
					return true
	return false


# --- Grille de 0,5 m -----------------------------------------------------------------------------------------

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


## Parcours en largeur : case (x, z, étage) vers [hauteur, corps du sol]. Note les trous et les marches de plus de
## 0,4 m sur un sol (terrain ou dalle), hors escalier.
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
				_note_hole(Vector3(x, cell.y, z))
				continue
			var y: float = hit.position.y
			if y - cell.y > CLIMB:
				# Une vraie marche est un ressaut : à mi-chemin, le sol est déjà en haut ou encore en bas.
				# Sur une pente raide mais régulière, il est entre les deux.
				if y - cell.y > 0.4 and y - cell.y < 1.2 and _is_floor(hit.collider) and fits(Vector3(x, y, z)):
					var middle := ground_hit((x + cell.x * STEP) / 2.0, (z + cell.z * STEP) / 2.0, y + 0.5)
					if not middle.is_empty():
						var mid_y: float = middle.position.y
						if absf(mid_y - y) < 0.08 or absf(mid_y - cell.y) < 0.08:
							_note("marche de %.2f m sans escalier" % (y - cell.y), Vector3(x, y, z))
				continue
			if cell.y - y > CLIMB:
				continue
			var key := Vector3i(int(nx), int(nz), roundi(y * 2.0))
			if reached.has(key) or not fits(Vector3(x, y, z)):
				continue
			reached[key] = y
			queue.append(Vector3(nx, y, nz))
	return reached


func _is_floor(collider: Object) -> bool:
	return collider == level.get_node("Terrain") or collider == level.get_node("Interior/Slabs")


var _holes := {}


func _note_hole(point: Vector3) -> void:
	# Dans la mairie, seule la cage d'escalier et le vide au-delà des murs sont attendus.
	if point.y < -20.0:
		var local := point - Vector3(0, -40, 0)
		if local.x > 4.4 and local.z > -4.3 and local.z < 2.1 and local.y > 2.0:
			return
		if absf(local.x) > 7.7 or absf(local.z) > 5.7:
			return
	elif Vector2(point.x, point.z).length() > 62.0:
		return
	var key := Vector2i(floori(point.x), floori(point.z))
	if _holes.has(key):
		return
	_holes[key] = true
	# Pente trop raide dehors : seulement si aucun sol n'est trouvé du tout sous le point.
	var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0, point + Vector3.DOWN * 6.0)
	ray.exclude = [player.get_rid()]
	if space.intersect_ray(ray).is_empty():
		_note("trou : aucun sol sous le joueur", point)


func _note(what: String, point: Vector3) -> void:
	var line := "%s en %s" % [what, point.snappedf(0.1)]
	if not problems.has(line):
		problems.append(line)


## Murs invisibles : depuis chaque case au bord de la zone atteignable, la capsule avance de 0,5 m dans 8 directions ;
## un arrêt contre une collision sans maillage visible à moins de 0,5 m est un mur invisible.
func grid(reached: Dictionary, label: String) -> void:
	print("%s : %d cases atteignables" % [label, reached.size()])
	var seen := {}
	for key: Vector3i in reached:
		var y: float = reached[key]
		var edge := false
		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var other := Vector3i(key.x + dir.x, key.y + dir.y, key.z)
			if not (reached.has(other) or reached.has(other + Vector3i(0, 0, 1)) or reached.has(other - Vector3i(0, 0, 1))):
				edge = true
		if not edge:
			continue
		var foot := Vector3(key.x * STEP, y, key.y * STEP)
		for direction: Vector3 in DIRECTIONS:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis.IDENTITY, foot + Vector3.UP * (HEIGHT / 2.0 + 0.2))
			query.motion = direction * 0.5
			query.exclude = [player.get_rid()]
			var fraction := space.cast_motion(query)
			if fraction[0] >= 0.99:
				continue
			query.transform.origin += direction * 0.5 * fraction[1]
			query.motion = Vector3.ZERO
			var rest := space.get_rest_info(query)
			if rest.is_empty():
				continue
			if rest.rid == terrain_rid:
				continue
			var point: Vector3 = rest.point
			if Vector2(point.x, point.z).length() > 70.5:
				continue
			if visible_near(point, 0.5):
				continue
			var cell := Vector3i(floori(point.x), floori(point.y), floori(point.z))
			if seen.has(cell):
				continue
			seen[cell] = true
			var collider: Object = instance_from_id(rest.collider_id)
			_note("mur invisible (%s)" % (collider.name if collider else "?"), point)


## Maillages visibles de plus de 0,3 m, posés au sol, que rien n'arrête.
func missing_collisions() -> void:
	var box_shape := BoxShape3D.new()
	var seen := {}
	for index in visuals.size():
		var name := visual_names[index]
		if name.begins_with("Player") or SOFT.any(func(part: String) -> bool: return name.contains(part)):
			continue
		if debug_scatter and name.begins_with("Scatter"):
			print("SCATTER %s h %.2f bas %.2f" % [name, visuals[index].size.y, visuals[index].position.y])
		var box := visuals[index]
		if box.size.y < 0.3 or maxf(box.size.x, box.size.z) < 0.15 or box.size.x * box.size.z > 400.0:
			continue
		# Seuls comptent les objets posés sur le sol où l'on marche (terrain, planchers de la mairie), pas ceux posés
		# sur un meuble ou en haut d'un mur.
		var floor_y: float
		if box.position.y > -20.0:
			floor_y = level.get_node("Terrain").surface_height(box.get_center().x, box.get_center().z)
		else:
			floor_y = -40.0 if box.position.y < -37.5 else -35.5
		if box.position.y > floor_y + 0.5:
			continue
		var height := minf(box.size.y - 0.15, 1.5)
		if height < 0.15:
			continue
		box_shape.size = Vector3(maxf(box.size.x * 0.6, 0.05), height, maxf(box.size.z * 0.6, 0.05))
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = box_shape
		query.transform = Transform3D(Basis.IDENTITY, Vector3(box.get_center().x, box.position.y + 0.15 + height / 2.0, box.get_center().z))
		query.exclude = [player.get_rid(), terrain_rid]
		if not space.intersect_shape(query, 1).is_empty():
			continue
		var cell := Vector2i(floori(box.get_center().x), floori(box.get_center().z))
		if seen.has(cell):
			continue
		seen[cell] = true
		_note("visible sans collision : %s (%.2f m de haut)" % [name, box.size.y], box.get_center())


## Le joueur entre-t-il dans un maillage visible ? Chaque maillage qui n'est pas « mou » reçoit un fantôme de
## collision à sa forme exacte (ses triangles), sur une couche à part ; en chaque case atteignable, un cylindre un
## peu plus mince que le joueur, de la cheville (0,35 m) au sommet du crâne, ne doit en toucher aucun. Plus fin que
## missing_collisions, qui se contente d'une collision quelque part au milieu de la boîte du maillage : le tronc
## d'un pin suffisait à couvrir ses branches basses.
const GHOST_LAYER := 1 << 19
var _ghosts: StaticBody3D
var _ghost_names := {}


func _build_ghosts() -> void:
	_ghosts = StaticBody3D.new()
	_ghosts.collision_layer = GHOST_LAYER
	_ghosts.collision_mask = 0
	level.add_child(_ghosts)
	_ghost_node(level)


func _ghost_node(node: Node) -> void:
	if node is Label3D or node is CPUParticles3D or node == level.get_node("Terrain") or node == _ghosts:
		return
	var mesh: Mesh = null
	var placements: Array[Transform3D] = []
	if node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh:
		var multimesh := (node as MultiMeshInstance3D).multimesh
		mesh = multimesh.mesh
		for index in multimesh.instance_count:
			placements.append((node as Node3D).global_transform * multimesh.get_instance_transform(index))
	elif node is MeshInstance3D:
		mesh = (node as MeshInstance3D).mesh
		placements.append((node as Node3D).global_transform)
	if mesh and not placements.is_empty():
		var name := str(level.get_path_to(node))
		var material: Material = (node as GeometryInstance3D).material_override
		if material:
			name += ":" + material.resource_name
		elif mesh.resource_name:
			name += ":" + mesh.resource_name
		if not name.begins_with("Player") and not SOFT.any(func(part: String) -> bool: return name.contains(part)):
			var local := mesh.get_faces()
			var faces := PackedVector3Array()
			for placement in placements:
				for vertex in local:
					faces.append(placement * vertex)
			if not faces.is_empty():
				var shape := ConcavePolygonShape3D.new()
				shape.set_faces(faces)
				var collision := CollisionShape3D.new()
				collision.shape = shape
				_ghosts.add_child(collision)
				_ghost_names[collision.get_index()] = name
	for child in node.get_children(true):
		_ghost_node(child)


func entered_meshes(reached: Dictionary) -> void:
	if _ghosts == null:
		_build_ghosts()
		print("fantômes de maillages : %d" % _ghosts.get_child_count())
		await physics_frame
	var body := CylinderShape3D.new()
	body.radius = 0.25
	body.height = 1.4
	var seen := {}
	var count := 0
	for key: Vector3i in reached:
		var foot := Vector3(key.x * STEP, reached[key], key.y * STEP)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = body
		query.transform = Transform3D(Basis.IDENTITY, foot + Vector3.UP * (0.35 + 0.7))
		query.collision_mask = GHOST_LAYER
		for hit in space.intersect_shape(query, 4):
			var name: String = _ghost_names.get(hit.shape, "?")
			# Sur la rampe de l'escalier, le nez des marches dépasse de 0,3 m au plus : les pieds le frôlent.
			if name.contains("Interior/Stairs") and foot.y > -39.9:
				continue
			var cell := Vector3i(floori(foot.x), floori(foot.y), floori(foot.z))
			var tag := "%s %s" % [name, cell]
			if seen.has(tag):
				continue
			seen[tag] = true
			count += 1
			_note("le joueur entre dans %s" % name, foot)
	print("entrées dans les maillages : %d" % count)


# --- Le vrai joueur marche -------------------------------------------------------------------------------------

func walk_band(band: int, parts := 3) -> void:
	var reached := flood(Vector3(0, 0.5, 57), Rect2(-75, -75, 150, 150))
	var width := 141.0 / parts
	var z0 := -70.0 + band * width
	var points := []
	for key: Vector3i in reached:
		if key.x % 8 != 0 or key.y % 8 != 0:
			continue
		var z := key.y * STEP
		if z < z0 or z >= z0 + width:
			continue
		points.append(Vector3(key.x * STEP, reached[key], z))
	print("bande %d : %d points" % [band, points.size()])
	for point: Vector3 in points:
		await walk_point(point, false)


func walk_inside() -> void:
	level.set("_inside", true)
	level.call("_apply_location")
	var reached := flood(level.get_node("Interior/InsideSpawn").global_position, Rect2(-20, -10, 32, 20))
	var points := []
	for key: Vector3i in reached:
		if key.x % 2 == 0 and key.y % 2 == 0:
			points.append(Vector3(key.x * STEP, reached[key], key.y * STEP))
	print("mairie : %d points" % points.size())
	for point: Vector3 in points:
		await walk_point(point, true)


## La fenêtre de test perd le focus : le menu pause s'ouvre et fige la partie. On le referme avant chaque essai.
func unpause() -> void:
	var menu := root.get_node_or_null("PauseMenu")
	if menu and menu.has_method("is_open") and menu.is_open():
		menu.close()
	paused = false


func walk_point(point: Vector3, inside: bool) -> void:
	unpause()
	var pivot: Node3D = player.get_node("CameraPivot")
	var moved := 0.0
	for direction: Vector3 in DIRECTIONS:
		unpause()
		player.global_position = point + Vector3.UP * 0.05
		player.velocity = Vector3.ZERO
		pivot.rotation.y = atan2(-direction.x, -direction.z)
		await physics_frame
		var start := player.global_position
		var previous_y := start.y
		Input.action_press("move_forward")
		for frame in 30:
			await physics_frame
			var y := player.global_position.y
			if y - previous_y > 0.45 and not _on_stairs(player.global_position):
				_note("saut de hauteur de %.2f m en marchant" % (y - previous_y), player.global_position)
			previous_y = y
		Input.action_release("move_forward")
		var after := player.global_position
		moved = maxf(moved, Vector2(after.x - start.x, after.z - start.z).length())
		for frame in 12:
			await physics_frame
		var drift := Vector2(player.global_position.x - after.x, player.global_position.z - after.z).length()
		if drift > 0.6:
			_note("glisse sans fin (%.1f m après l'arrêt)" % drift, after)
		if player.global_position.y < start.y - 2.5 and not _on_stairs(start):
			_note("chute de %.1f m" % (start.y - player.global_position.y), after)
		if Vector2(player.global_position.x, player.global_position.z).length() > 71.0:
			_note("sortie de la carte", player.global_position)
	if moved < 0.15:
		_note("joueur coincé", point)
	if inside:
		# Un saut sur place : la tête ne passe pas le plafond.
		player.global_position = point + Vector3.UP * 0.05
		player.velocity = Vector3.ZERO
		Input.action_press("jump")
		await physics_frame
		Input.action_release("jump")
		var highest := point.y
		for frame in 50:
			await physics_frame
			highest = maxf(highest, player.global_position.y)
		var local := point.y + 40.0
		var ceiling := 4.0 if local < 2.0 else 8.0
		# Au-dessus de la cage d'escalier et dans la salle secrète, le plafond est celui du bureau.
		if point.x < -8.0 or (point.x > 4.5 and point.z > -4.2 and point.z < 2.0):
			ceiling = 8.0
		if highest + 40.0 + HEIGHT > ceiling + 0.02:
			_note("la tête passe le plafond en sautant (%.2f m)" % (highest + 40.0 + HEIGHT), point)


func _on_stairs(point: Vector3) -> bool:
	return point.y < -30.0 and point.x > 4.4 and point.x < 7.8 and point.z > -4.6 and point.z < 5.4


# --- Escaliers, portes, invites ------------------------------------------------------------------------------

func passages() -> void:
	# Portes des maisons, dans les deux sens.
	var doors := [
		["porte maison 0", Vector3(-6, 0, 32), Vector3(1, 0, 0)], ["porte maison 1", Vector3(-6, 0, 22), Vector3(1, 0, 0)],
		["porte maison 2", Vector3(6, 0, 32), Vector3(-1, 0, 0)], ["porte maison 3", Vector3(6, 0, 22), Vector3(-1, 0, 0)],
		["porte maison 4", Vector3(-13, 0, -6), Vector3(1, 0, 0)], ["porte maison 5", Vector3(13, 0, -6), Vector3(-1, 0, 0)],
		["porte maison 6", Vector3(-18, 0, 18), Vector3(0, 0, 1)], ["porte maison 7", Vector3(-26, 0, 2), Vector3(0, 0, 1)],
		["porte maison 8", Vector3(17, 0, 14), Vector3(-1, 0, 0)], ["porte maison 9", Vector3(-10, 0, -14), Vector3(0, 0, 1)],
		["porte maison 10", Vector3(14, 0, -14), Vector3(0, 0, 1), 1.0], ["porte maison 11", Vector3(-27, 0, -12), Vector3(1, 0, 0)],
		["porte du village", Vector3(0, 0, 42), Vector3(0, 0, 1)], ["porte de l'ouest", Vector3(-34.6, 0, 6), Vector3(-1, 0, 0)],
		["pont du ruisseau", Vector3(-38, 0, 6), Vector3(-1, 0, 0), 5.0], ["écuries", Vector3(20, 0, 31.2), Vector3(-1, 0, 0)],
		["enclos", Vector3(24, 0, 17.6), Vector3(0, 0, -1), 0.9]]
	for door: Array in doors:
		var center: Vector3 = door[1]
		var out: Vector3 = door[2]
		var reach: float = door[3] if door.size() > 3 else 3.0
		var outside := center + out * reach
		var inside := center - out * reach
		outside.y = ground_y(outside)
		inside.y = ground_y(inside)
		unpause()
		player.global_position = inside + Vector3.UP * 0.1
		player.velocity = Vector3.ZERO
		await wait(3)
		var there := await walk_to(outside, "%s, vers l'extérieur" % door[0], 400)
		var back := await walk_to(inside, "%s, vers l'intérieur" % door[0], 400)
		if not there or not back:
			_note("%s infranchissable dans un sens" % door[0], center)
	# Escalier de la mairie : monté et descendu en entier, du bas, du haut, du milieu et de chaque côté.
	level.set("_inside", true)
	level.call("_apply_location")
	for x in [4.95, 6.05, 7.15]:
		for trip: Array in [[5.6, -5.0], [-5.0, 5.6], [0.5, -5.0], [0.5, 5.6]]:
			var from := Vector3(x, ramp_y(trip[0]), trip[0])
			var to := Vector3(x, ramp_y(trip[1]), trip[1])
			unpause()
			player.global_position = from + Vector3.UP * 0.1
			player.velocity = Vector3.ZERO
			await wait(3)
			var lowest := INF
			Input.action_press("move_forward")
			var reached := false
			var pivot: Node3D = player.get_node("CameraPivot")
			for frame in 500:
				await physics_frame
				var offset := to - player.global_position
				pivot.rotation.y = atan2(-offset.x, -offset.z)
				var p := player.global_position
				if p.z > -4.0 and p.z < 5.0:
					lowest = minf(lowest, p.y - ramp_y(p.z))
				if Vector2(offset.x, offset.z).length() < 0.4 and absf(offset.y) < 0.6:
					reached = true
					break
			Input.action_release("move_forward")
			await wait(3)
			var label := "escalier x %.2f de z %.1f à %.1f" % [x, trip[0], trip[1]]
			check("%s (%s)" % [label, player.global_position.snappedf(0.1)], reached)
			if not reached:
				_note(label + " : n'arrive pas", player.global_position)
			if lowest < -0.35:
				_note(label + " : une marche ne porte pas le joueur (%.2f m sous la rampe)" % lowest, player.global_position)
	# Passage secret, après l'énigme, dans les deux sens.
	level.call("_on_codes_solved")
	await wait(240)
	player.global_position = Vector3(-5.0, -35.4, 0.0)
	await wait(3)
	if not await walk_to(Vector3(-11.0, -35.5, 0.0), "passage secret, vers la salle", 400) or not await walk_to(Vector3(-5.0, -35.5, 0.0), "passage secret, vers le bureau", 400):
		_note("passage secret infranchissable dans un sens", Vector3(-8, -35.5, 0))
	# Invites des interactables depuis leurs quatre côtés, quand le joueur peut s'y tenir et voir l'objet.
	for node in root.get_tree().get_nodes_in_group(&"interactable"):
		var item := node as Interactable
		if not level.is_ancestor_of(item):
			continue
		var inside_hall := level.get_node("Interior").is_ancestor_of(item)
		level.set("_inside", inside_hall)
		level.call("_apply_location")
		await wait(2)
		if not item.enabled or not item.is_visible_in_tree():
			continue
		var good := 0
		var tried := 0
		var thieves := []
		for direction: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
			var spot := item.global_position + direction * minf(1.3, item.radius * 0.6)
			var down := PhysicsRayQueryParameters3D.create(Vector3(spot.x, item.global_position.y + 1.0, spot.z), Vector3(spot.x, item.global_position.y - 3.5, spot.z))
			down.exclude = [player.get_rid()]
			var hit := space.intersect_ray(down)
			if hit.is_empty():
				continue
			var foot: Vector3 = hit.position
			if absf(foot.y - item.global_position.y) > 2.8 or not fits(foot):
				continue
			var ray := PhysicsRayQueryParameters3D.create(foot + Vector3.UP * 1.65, item.global_position + Vector3.UP * 0.05)
			ray.exclude = [player.get_rid()]
			var blocked := space.intersect_ray(ray)
			if not blocked.is_empty() and (blocked.position as Vector3).distance_to(item.global_position) > 0.6:
				continue
			tried += 1
			unpause()
			player.global_position = foot + Vector3.UP * 0.05
			player.velocity = Vector3.ZERO
			var offset := item.global_position - player.global_position
			player.get_node("CameraPivot").rotation.y = atan2(-offset.x, -offset.z)
			await wait(4)
			if prompt().contains(item.prompt):
				good += 1
			else:
				thieves.append(prompt())
		var label := str(level.get_path_to(item))
		print("invites %s : %d / %d côtés %s" % [label, good, tried, thieves])
		if tried > 0 and good == 0:
			_note("%s : invite absente de tous les côtés accessibles" % label, item.global_position)


func ground_y(point: Vector3) -> float:
	var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 20.0, point + Vector3.DOWN * 20.0)
	ray.exclude = [player.get_rid()]
	var hit := space.intersect_ray(ray)
	return (hit.position as Vector3).y if hit else point.y


## Hauteur de la rampe de l'escalier de la mairie (z = 5 au sol, z = -4 à l'étage), en coordonnées du monde.
func ramp_y(z: float) -> float:
	return -40.0 + clampf((5.0 - z) * 0.5, 0.0, 4.5)
