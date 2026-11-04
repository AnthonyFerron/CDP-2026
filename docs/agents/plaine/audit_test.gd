extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Audit des plaines d'Hexcole (à lancer sans --headless pour les captures) :
## - sol accessible à pied : remplissage depuis les points d'apparition, dehors et dans les archives (cartes PNG) ;
## - chaque interactable : son point hors de toute collision, un point de sol accessible à portée, une ligne de vue
##   libre depuis les yeux (1,65 m), l'invite qui s'affiche depuis là, et une capture ;
## - chaque modèle plus haut que la cheville a une collision dans son volume ; les lanternes arrêtent le joueur.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/plaine/audit/"
const EYE := 1.65
const STEP := 0.6
const INSIDE_STEP := 0.3

var space: PhysicsDirectSpaceState3D
var capsule := CapsuleShape3D.new()
var shots := true
## Cases de sol accessibles : Vector2i vers hauteur du sol, une table dehors et une dans les archives.
var outside := {}
var inside := {}


func _initialize() -> void:
	shots = DisplayServer.get_name() != "headless"
	capsule.radius = 0.4
	capsule.height = 1.8
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	space = level.get_world_3d().direct_space_state
	# On ouvre la dalle et on rend le livre prenable, pour auditer aussi l'escalier et le pupitre.
	var stone: Node3D = level.get_node("Interior/Stone")
	stone.position.x -= level.stone_travel
	level.get_node("Interior/Book/Interactable").enabled = true
	await wait(4)

	outside = _flood(level.get_node("Exterior/OutsideSpawn").global_position, Vector2(-70, -70), Vector2(70, 70), STEP,
		30.0, -12.0, "sol_dehors")
	_flood_from(outside, level.get_node("Player").global_position, Vector2(-70, -70), Vector2(70, 70), STEP, 30.0, -12.0)
	_save_map(outside, Vector2(-70, -70), Vector2(70, 70), STEP, 30.0, -12.0, "sol_dehors")
	inside = _flood(level.get_node("Interior/InsideSpawn").global_position, Vector2(-6.5, -44.8), Vector2(6.5, 0.6),
		INSIDE_STEP, -36.2, -42.5, "sol_archives")
	_save_map(inside, Vector2(-6.5, -44.8), Vector2(6.5, 0.6), INSIDE_STEP, -36.2, -42.5, "sol_archives")
	if OS.get_cmdline_user_args().has("debug"):
		for j in range(int((-36.4 + 44.8) / INSIDE_STEP), int((-34.0 + 44.8) / INSIDE_STEP)):
			var line := "z %.1f :" % (-44.8 + j * INSIDE_STEP)
			for i in range(int((-1.0 + 6.5) / INSIDE_STEP), int((1.2 + 6.5) / INSIDE_STEP)):
				var x := -6.5 + i * INSIDE_STEP
				var z := -44.8 + j * INSIDE_STEP
				line += " %s%.2f" % ["*" if inside.has(Vector2i(i, j)) else " ", _walkable(x, z, -37.8, -42.5)]
			print(line)
		for z in [-36.7, -37.0, -37.3]:
			var hit := _ground(0.1, z, -37.8, -42.5)
			print("  z %.1f : sol %s normale %s" % [z, hit.get("position"), hit.get("normal")])
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis(), Vector3(0.1, hit.position.y + 1.05, z))
			query.collide_with_areas = false
			query.exclude = [player.get_rid()]
			for other in space.intersect_shape(query, 4):
				print("    gêne : %s forme %d" % [other.collider.get_path(), other.shape])
		finish()
		return
	check("sol dehors accessible : %d cases" % outside.size(), outside.size() > 5000)
	check("sol des archives accessible : %d cases" % inside.size(), inside.size() > 1500)

	for node in root.get_tree().get_nodes_in_group(&"interactable"):
		var item := node as Interactable
		if item.enabled:
			await _audit(item)
	_check_models()
	await _check_lanterns()
	finish()


func _is_interior(node: Node) -> bool:
	return level.get_node("Interior").is_ancestor_of(node)


## Hauteur du sol sous un point, ou NAN : premier obstacle rencontré en descendant.
func _ground(x: float, z: float, top: float, bottom: float) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, bottom, z))
	query.collide_with_areas = false
	return space.intersect_ray(query)


func _free_at(x: float, ground: float, z: float) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis(), Vector3(x, ground + 0.9 + 0.15, z))
	query.collide_with_areas = false
	query.exclude = [player.get_rid()]
	return space.intersect_shape(query, 1).is_empty()


func _walkable(x: float, z: float, top: float, bottom: float) -> float:
	var hit := _ground(x, z, top, bottom)
	if not hit.is_empty() and hit.normal.y < 0.7:
		# Le rayon est tombé pile sur l'arête d'une marche ou d'un sol : on le décale d'un cheveu.
		hit = _ground(x + 0.013, z - 0.017, top, bottom)
	if hit.is_empty() or hit.normal.y < 0.7:
		return NAN
	var ground: float = hit.position.y
	if not _free_at(x, ground, z):
		return NAN
	var scatter: PlaineScatter = level.get_node("Exterior/Scatter")
	if ground > -20.0 and scatter.is_near_lava(Vector3(x, ground, z), 0.4):
		return NAN
	return ground


func _flood(start: Vector3, low: Vector2, high: Vector2, step: float, top: float, bottom: float, _name: String) -> Dictionary:
	var cells := {}
	_flood_from(cells, start, low, high, step, top, bottom)
	return cells


func _flood_from(cells: Dictionary, start: Vector3, low: Vector2, high: Vector2, step: float, top: float, bottom: float) -> void:
	var seen := {}
	var origin := Vector2i(roundi((start.x - low.x) / step), roundi((start.z - low.y) / step))
	var size := Vector2i(ceili((high.x - low.x) / step), ceili((high.y - low.y) / step))
	var queue: Array[Vector2i] = [origin]
	var first := _walkable(low.x + origin.x * step, low.y + origin.y * step, top, bottom)
	if is_nan(first):
		print("depart non accessible : ", start)
		return
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


func _save_map(cells: Dictionary, low: Vector2, high: Vector2, step: float, top: float, bottom: float, name: String) -> void:
	if not shots:
		return
	var size := Vector2i(ceili((high.x - low.x) / step) + 1, ceili((high.y - low.y) / step) + 1)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	for x in size.x:
		for y in size.y:
			var color := Color(0.1, 0.1, 0.1)
			if cells.has(Vector2i(x, y)):
				color = Color(0.3, 0.75, 0.35)
			else:
				var hit := _ground(low.x + x * step, low.y + y * step, top, bottom)
				if not hit.is_empty():
					color = Color(0.7, 0.2, 0.2) if hit.normal.y > 0.7 else Color(0.45, 0.3, 0.2)
			image.set_pixel(x, y, color)
	image.resize(size.x * 4, size.y * 4, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + name + ".png")


## Un interactable : point libre, sol accessible à portée, vue dégagée, invite.
func _audit(item: Interactable) -> void:
	var interior := _is_interior(item)
	level.set("_inside", interior)
	level.call("_apply_location")
	var point := item.global_position
	var label := String(level.get_path_to(item))
	# Un point posé au ras du sol (le portail) se contrôle juste au-dessus de lui.
	var floor_hit := _ground(point.x, point.z, point.y + 0.05, point.y - 3.0)
	var probe := point
	if not floor_hit.is_empty() and point.y - floor_hit.position.y < 0.1:
		probe.y = floor_hit.position.y + 0.1
	var point_query := PhysicsPointQueryParameters3D.new()
	point_query.position = probe
	point_query.collide_with_areas = false
	var inside_hits := space.intersect_point(point_query, 4)
	check("%s : point hors des collisions" % label, inside_hits.is_empty())
	# Visée : un point posé au sol se regarde un peu au-dessus.
	var target := point
	if not floor_hit.is_empty() and point.y - floor_hit.position.y < 0.4:
		target.y = floor_hit.position.y + 0.6
	var cells := inside if interior else outside
	var step := INSIDE_STEP if interior else STEP
	var low := Vector2(-6.5, -44.8) if interior else Vector2(-70, -70)
	var candidates: Array = []
	for cell: Vector2i in cells:
		var spot := Vector3(low.x + cell.x * step, cells[cell], low.y + cell.y * step)
		var flat := Vector2(spot.x - point.x, spot.z - point.z).length()
		if flat < 0.6 or flat > item.radius - 0.2 or absf(point.y - spot.y) > 2.8:
			continue
		candidates.append([absf(flat - 1.3), spot])
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	check("%s : sol accessible à portée (%d places)" % [label, candidates.size()], not candidates.is_empty())
	var seen := false
	var shown := false
	var tried := 0
	for entry: Array in candidates:
		var spot: Vector3 = entry[1]
		tried += 1
		if tried > 40:
			break
		var eye := spot + Vector3.UP * EYE
		var ray := PhysicsRayQueryParameters3D.create(eye, target)
		ray.collide_with_areas = false
		ray.exclude = [player.get_rid()]
		var hit := ray_hit(ray)
		if not hit.is_empty() and hit.position.distance_to(target) > 0.12:
			continue
		seen = true
		player.global_position = spot + Vector3.UP * 0.05
		player.velocity = Vector3.ZERO
		var pivot: Node3D = player.get_node("CameraPivot")
		var offset := target - eye
		pivot.rotation.y = atan2(-offset.x, -offset.z)
		pivot.rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())
		# La fenêtre qui perd le focus ouvre le menu pause : on relance la partie pour lire l'invite.
		paused = false
		await wait(3)
		await process_frame
		await process_frame
		if item.focused and prompt().contains(item.prompt):
			shown = true
			if shots:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT + label.replace("/", "_") + ".png")
			print("      vu depuis %s" % spot.snappedf(0.1))
			break
	check("%s : ligne de vue libre depuis les yeux" % label, seen)
	check("%s : invite « %s » affichée" % [label, item.prompt], shown)
	player.get_node("CameraPivot").rotation.x = 0.0


func ray_hit(ray: PhysicsRayQueryParameters3D) -> Dictionary:
	return space.intersect_ray(ray)


## Chaque modèle posé, plus haut que la cheville et à portée du joueur, a une collision dans son volume.
func _check_models() -> void:
	var missing := 0
	var total := 0
	for path in ["Exterior/Ruins/Models", "Exterior/Battlefield/Models", "Exterior/Battlefield/Shapes",
			"Interior/Library/Models", "Interior/Library/Shapes"]:
		for model: Node3D in level.get_node(path).get_children():
			var box := AABB()
			var first := true
			var meshes: Array = model.find_children("*", "MeshInstance3D", true, false)
			if model is MeshInstance3D:
				meshes.append(model)
			for mesh: MeshInstance3D in meshes:
				var part: AABB = mesh.global_transform * mesh.get_aabb()
				box = part if first else box.merge(part)
				first = false
			if first:
				continue
			# Niveau où l'on marche sous l'objet : le terrain dehors, le sol des archives ou de la petite salle dedans.
			var center := box.get_center()
			var floor_y := -40.0 if center.z > -37.5 else -41.0
			if center.y > -20.0:
				floor_y = (level.get_node("Exterior/Terrain") as PlaineTerrain).surface_height(center.x, center.z)
			# Posé sur un autre meuble, accroché au mur ou à l'étage : hors de portée du pas.
			if box.position.y > floor_y + 0.35:
				continue
			var low := maxf(box.position.y, floor_y) + 0.22
			var high := minf(box.end.y, floor_y + 1.8)
			# Trop bas pour gêner le pas.
			if high - low < 0.05 or box.size.x * box.size.z < 0.0004:
				continue
			total += 1
			var shape := BoxShape3D.new()
			shape.size = Vector3(maxf(box.size.x, 0.05), high - low, maxf(box.size.z, 0.05))
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape
			query.transform = Transform3D(Basis(), Vector3(box.get_center().x, (low + high) * 0.5, box.get_center().z))
			query.collide_with_areas = false
			query.exclude = [player.get_rid(), level.get_node("Exterior/Terrain").get_rid()]
			if space.intersect_shape(query, 1).is_empty():
				missing += 1
				print("      sans collision : %s %s" % [model.name, box.get_center().snappedf(0.1)])
	check("modèles plus hauts que la cheville avec une collision (%d sans sur %d)" % [missing, total], missing == 0)


## Les lanternes du chemin, debout ou couchées, arrêtent le joueur qui marche dessus.
func _check_lanterns() -> void:
	level.set("_inside", false)
	level.call("_apply_location")
	# On vise le milieu de chaque poteau, debout ou couché, d'après sa collision.
	for shape: CollisionShape3D in level.get_node("Exterior/Scatter/LanternPosts").get_children():
		var spot := shape.global_position
		var target := Vector3(spot.x, 0.0, spot.z)
		target.y = (level.get_node("Exterior/Terrain") as PlaineTerrain).surface_height(target.x, target.z)
		# Départ à 2,2 m, de biais par rapport au poteau couché.
		var across := shape.global_basis.z.normalized()
		var start := target + Vector3(across.x, 0.0, across.z) * 2.2
		player.global_position = start + Vector3.UP * 0.1
		player.velocity = Vector3.ZERO
		await wait(5)
		var pivot: Node3D = player.get_node("CameraPivot")
		Input.action_press("move_forward")
		for i in 90:
			var offset := target - player.global_position
			pivot.rotation.y = atan2(-offset.x, -offset.z)
			await physics_frame
		Input.action_release("move_forward")
		await wait(3)
		var flat := Vector2(player.global_position.x - target.x, player.global_position.z - target.z).length()
		check("lanterne (%.1f, %.1f) : le joueur s'arrête devant (%.2f m)" % [spot.x, spot.z, flat], flat > 0.45)
