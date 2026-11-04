extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Audit du Village : pour chaque interactable (panneaux, porte, portail, meubles, fragments, dispositif, livre),
## vérifie que son point n'est pas dans une collision, qu'un point de sol libre et atteignable à pied existe à
## portée, que rien ne coupe la vue entre les yeux du joueur (1,65 m) et l'objet, et que l'invite apparaît bien
## depuis ce point. Vérifie aussi que les lieux clés du village sont atteignables à pied et que les modèles du
## décor ne flottent pas. Sans --headless, photographie chaque interactable depuis le point trouvé.
## Arguments facultatifs après -- : « noshots » pour ne pas photographier.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/village/audit/"
const EYE := 1.65
const STEP := 0.5
const CLIMB := 0.36
const RADIUS := 0.38
const HEIGHT := 1.8
## Ce qui pend d'un mur ou d'une potence n'a pas à toucher le sol.
const HANGING := ["banner", "flag", "windmill", "watermill", "lantern_candle", "lampWall", "chimney", "tower_square_mid",
		"tower_square_top", "tower_square_roof", "bridge", "weapon_arrow", "door"]

var space: PhysicsDirectSpaceState3D
var shots := true
var camera: Camera3D
var capsule := CapsuleShape3D.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	shots = DisplayServer.get_name() != "headless" and not OS.get_cmdline_user_args().has("noshots")
	DirAccess.make_dir_recursive_absolute(OUT)
	await start_level("res://scenes/levels/village/village.tscn")
	space = player.get_world_3d().direct_space_state
	capsule.radius = RADIUS
	capsule.height = HEIGHT
	camera = Camera3D.new()
	camera.fov = 70.0
	level.add_child(camera)
	level.get_node("Hud").visible = false

	# Dehors : tout ce qui est atteignable depuis l'arrivée.
	var outside := flood(level.get_node("Player").global_position + Vector3.UP * 0.2, Rect2(-75, -75, 150, 150))
	print("cases atteignables dehors : %d" % outside.size())
	for spot: Vector3 in [Vector3(0, 0, -19), Vector3(-38, 0, 6), Vector3(-25.5, 0, -14), Vector3(30, 4, -26),
			Vector3(-20, 0, 30), Vector3(24, 0, 30), Vector3(0, 0, 36), Vector3(-30, 0, 6), Vector3(-44, 0, 6), Vector3(24, 0, -2)]:
		check("lieu atteignable %s" % spot, near_reachable(outside, spot, 1.5))
	for node in interactables(false):
		await audit(node, outside)
	check_floating(level.get_node("Props"))

	# Dedans : la mairie, sous la carte.
	level.set("_inside", true)
	level.call("_apply_location")
	var spawn: Vector3 = level.get_node("Interior/InsideSpawn").global_position
	player.global_position = spawn
	await wait(5)
	var inside := flood(spawn, Rect2(-20, -10, 32, 20))
	print("cases atteignables dans la mairie : %d" % inside.size())
	var levels := {}
	for key: Vector3i in inside:
		var floor_name := "%.1f" % inside[key]
		if not levels.has(floor_name):
			levels[floor_name] = [0, Vector2(INF, INF), Vector2(-INF, -INF)]
		levels[floor_name][0] += 1
		levels[floor_name][1] = Vector2(minf(levels[floor_name][1].x, key.x * STEP), minf(levels[floor_name][1].y, key.y * STEP))
		levels[floor_name][2] = Vector2(maxf(levels[floor_name][2].x, key.x * STEP), maxf(levels[floor_name][2].y, key.y * STEP))
	for floor_name in levels:
		print("   sol %s : %s" % [floor_name, levels[floor_name]])
	check("escalier praticable (étage atteint)", inside.values().any(func(y: float) -> bool: return y > -36.0))
	var storages := level.get_node("Interior/Storages")
	for node in interactables(true):
		if node is PaperFragment and not node.visible:
			continue
		if node == level.get_node("Interior/Book/Interactable"):
			continue
		await audit(node, inside)
		if node.get_parent() == storages:
			node.interact()
			await wait(3)
			var paper := node.get_node_or_null(node.fragment) as PaperFragment
			if paper:
				await audit(paper, inside)
	check_floating(level.get_node("Interior/Hall"))

	# Le livre : la bibliothèque glisse, puis la salle secrète doit être atteignable.
	level.call("_on_codes_solved")
	await wait(240)
	var opened := flood(spawn, Rect2(-20, -10, 32, 20))
	var book: Interactable = level.get_node("Interior/Book/Interactable")
	check("le livre est activé", book.enabled)
	await audit(book, opened)
	finish()


func interactables(interior: bool) -> Array:
	var list := []
	for node in root.get_tree().get_nodes_in_group(&"interactable"):
		if not level.is_ancestor_of(node):
			continue
		var is_inside := level.get_node("Interior").is_ancestor_of(node)
		if is_inside == interior:
			list.append(node)
	return list


## Point visé : le centre de la planche d'un panneau, sinon la position de l'interactable.
func look_point(node: Node3D) -> Vector3:
	for child in node.get_children():
		if child is SignBoard:
			return (child as Node3D).global_transform * Vector3(0, child.board_height, 0.06)
	if node is PaperFragment:
		return node.global_position + Vector3.UP * 0.03
	if node.get_parent().has_method("set_open"):
		return node.global_position + Vector3.UP * 1.5
	return node.global_position


## Corps qui appartiennent à l'interactable (le panneau, son poteau, son support), enfants internes compris.
func own_bodies(node: Node) -> Array[RID]:
	var rids: Array[RID] = [player.get_rid()]
	_collect_internal(node, rids)
	return rids


func _collect_internal(node: Node, rids: Array[RID]) -> void:
	for child in node.get_children(true):
		if child is CollisionObject3D:
			rids.append(child.get_rid())
		_collect_internal(child, rids)


func audit(node: Interactable, reachable: Dictionary) -> void:
	var label: String = str(level.get_path_to(node))
	var target := look_point(node)
	var exclude := own_bodies(node)
	# 1. Le point visé n'est pas dans une collision.
	var point := PhysicsPointQueryParameters3D.new()
	point.position = target
	point.exclude = exclude
	var inside_hits := space.intersect_point(point)
	var names := inside_hits.map(func(hit: Dictionary) -> String: return str(hit.collider.name))
	check("%s : point hors collision %s" % [label, names], inside_hits.is_empty())
	# 2. Des points de sol atteignables, à portée, d'où l'on voit l'objet : les plus proches de 1,4 m d'abord.
	var origin := node.global_position
	var candidates := []
	for key: Vector3i in reachable:
		var floor := Vector3(key.x * STEP, reachable[key], key.y * STEP)
		var flat := Vector2(floor.x - origin.x, floor.z - origin.z).length()
		if flat < 0.5 or flat > node.radius - 0.25 or absf(origin.y - floor.y) > 2.8:
			continue
		candidates.append([absf(flat - minf(1.4, node.radius * 0.6)), floor])
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var visible := candidates.filter(func(entry: Array) -> bool: return sees(entry[1] + Vector3.UP * EYE, target, exclude))
	var found := not visible.is_empty()
	check("%s : %d points de sol libres à portée, vue dégagée depuis %d" % [label, candidates.size(), visible.size()], found)
	if not found:
		return
	# 3. L'invite apparaît depuis l'un de ces points, en regardant l'objet (un voisin plus proche peut la prendre
	# ailleurs : on essaie les meilleurs points, jusqu'à 48).
	var best: Vector3 = visible[0][1]
	var text := ""
	var pivot: Node3D = player.get_node("CameraPivot")
	for entry: Array in visible.slice(0, 48):
		player.global_position = (entry[1] as Vector3) + Vector3.UP * 0.05
		player.velocity = Vector3.ZERO
		var offset := target - player.global_position
		pivot.rotation.y = atan2(-offset.x, -offset.z)
		await wait(4)
		text = prompt()
		if text.contains(node.prompt):
			best = entry[1]
			break
	check("%s : invite « %s » depuis %s (attendue « %s »)" % [label, text, best.snappedf(0.1), node.prompt], text.contains(node.prompt))
	# 4. Photographie depuis les yeux du joueur.
	if shots:
		var previous := root.get_viewport().get_camera_3d()
		camera.global_position = best + Vector3.UP * EYE
		camera.look_at(target, Vector3.UP)
		camera.current = true
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + label.replace("/", "_") + ".png")
		if previous:
			previous.current = true


func sees(eye: Vector3, target: Vector3, exclude: Array[RID]) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(eye, target)
	ray.exclude = exclude
	var hit := space.intersect_ray(ray)
	return hit.is_empty() or (hit.position as Vector3).distance_to(target) < 0.3


## Parcours en largeur des cases de sol où tient la capsule du joueur, de proche en proche (marches et rampes
## comprises). Renvoie case (x, z, étage) vers hauteur du sol.
func flood(start: Vector3, bounds: Rect2) -> Dictionary:
	var reached := {}
	var first := ground(start.x, start.z, start.y + 1.0)
	if is_nan(first):
		return reached
	var queue: Array[Vector3] = [Vector3(roundf(start.x / STEP), first, roundf(start.z / STEP))]
	reached[Vector3i(int(queue[0].x), int(queue[0].z), roundi(first * 2.0))] = first
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx := cell.x + dir.x
			var nz := cell.z + dir.y
			var x := nx * STEP
			var z := nz * STEP
			if not bounds.has_point(Vector2(x, z)):
				continue
			var y := ground(x, z, cell.y + CLIMB + 0.2)
			if is_nan(y) or absf(y - cell.y) > CLIMB:
				continue
			var key := Vector3i(int(nx), int(nz), roundi(y * 2.0))
			if reached.has(key):
				continue
			if not fits(Vector3(x, y, z)):
				continue
			reached[key] = y
			queue.append(Vector3(nx, y, nz))
	return reached


## Hauteur du sol sous un point : un rayon qui tombe pile sur l'arête d'une marche est refait un peu à côté.
func ground(x: float, z: float, from_y: float) -> float:
	var best := NAN
	for offset: Vector2 in [Vector2.ZERO, Vector2(0.06, 0.06), Vector2(-0.06, -0.06)]:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(x + offset.x, from_y, z + offset.y), Vector3(x + offset.x, from_y - 1.6, z + offset.y))
		ray.exclude = [player.get_rid()]
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or (hit.normal as Vector3).y < 0.7:
			continue
		best = (hit.position as Vector3).y if is_nan(best) else maxf(best, (hit.position as Vector3).y)
		if offset == Vector2.ZERO:
			break
	return best


func fits(foot: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, foot + Vector3.UP * (HEIGHT / 2.0 + 0.12))
	query.exclude = [player.get_rid()]
	return space.intersect_shape(query, 1).is_empty()


func near_reachable(reachable: Dictionary, spot: Vector3, tolerance: float) -> bool:
	for key: Vector3i in reachable:
		if Vector2(key.x * STEP - spot.x, key.y * STEP - spot.z).length() < tolerance and absf(reachable[key] - spot.y) < 1.5:
			return true
	return false


## Modèles posés : ni flottants (rien sous leur pied), ni entièrement enterrés. Les modèles répétés, dessinés en
## une fois par VillageInstances, sont contrôlés copie par copie.
func check_floating(root_node: Node) -> void:
	var boxes := []
	for model: Node3D in root_node.get_node("Models").get_children():
		boxes.append([String(model.name), world_box(model)])
	if root_node.has_node("Instances"):
		for group: Node3D in root_node.get_node("Instances").get_children():
			var sample: Node3D = group.model.instantiate()
			level.add_child(sample)
			sample.global_transform = Transform3D.IDENTITY
			var local := world_box(sample)
			sample.free()
			for index in group.transforms.size():
				boxes.append(["%s#%d" % [group.name, index], group.global_transform * group.transforms[index] * local])
	var floating := []
	var terrain: Node = level.get_node("Terrain")
	for entry: Array in boxes:
		var name: String = entry[0]
		var box: AABB = entry[1]
		if box.size == Vector3.ZERO or HANGING.any(func(part: String) -> bool: return name.contains(part)):
			continue
		var bottom := box.position.y
		var center := box.get_center()
		# Le rayon part juste au-dessus du pied : la collision du modèle lui-même, qui contient ce point, est ignorée.
		# Un pied enfoui sous le sol (plancher affleurant) compte pour un écart négatif.
		var gap := 99.0
		# Posé sur une étagère, une charrette ou un meuble plein : son pied est dans la collision de son support.
		var support := PhysicsPointQueryParameters3D.new()
		support.position = Vector3(center.x, bottom - 0.03, center.z)
		support.exclude = [player.get_rid()]
		if not space.intersect_point(support, 1).is_empty():
			gap = 0.0
		for probe: Vector3 in [center, Vector3(box.position.x + box.size.x * 0.25, 0, center.z), Vector3(box.end.x - box.size.x * 0.25, 0, center.z),
				Vector3(center.x, 0, box.position.z + box.size.z * 0.25), Vector3(center.x, 0, box.end.z - box.size.z * 0.25)]:
			var ray := PhysicsRayQueryParameters3D.create(Vector3(probe.x, bottom + 0.05, probe.z), Vector3(probe.x, bottom - 3.0, probe.z))
			ray.exclude = [player.get_rid()]
			var hit := space.intersect_ray(ray)
			if hit.is_empty():
				ray = PhysicsRayQueryParameters3D.create(Vector3(probe.x, box.end.y + 0.5, probe.z), Vector3(probe.x, bottom - 3.0, probe.z))
				ray.exclude = [player.get_rid()]
				hit = space.intersect_ray(ray)
			if not hit.is_empty():
				gap = minf(gap, bottom - (hit.position as Vector3).y)
		if gap > 0.15:
			floating.append("%s (%s, écart %.2f)" % [name, center.snappedf(0.1), gap])
		if root_node.name != "Hall" and terrain.has_method("surface_height"):
			var floor_y: float = terrain.surface_height(center.x, center.z)
			# Un modèle plat (sillons, planches) affleure le sol sans être enterré.
			if box.size.y > 0.1 and box.end.y < floor_y + 0.005:
				floating.append("%s enterré (%s, haut %.3f, sol %.3f)" % [name, center.snappedf(0.1), box.end.y, floor_y])
	for line in floating:
		print("       flottant : " + line)
	check("%s : %d modèles, aucun flottant ni enterré (%d)" % [root_node.name, boxes.size(), floating.size()], floating.is_empty())


func world_box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var part: AABB = mesh.global_transform * mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box
