extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Audit du hub, pour un nombre de livres posés (argument 0 à 4) :
## - chaque interactable : son point n'est pas dans une collision étrangère, un point de sol libre existe à sa portée,
##   et rien ne coupe la vue entre les yeux du joueur (1,65 m) et l'objet ; l'invite apparaît quand on le regarde ;
## - les nouveaux bâtiments par leur porte, les ruelles et les ponts à pied ;
## - le plafond et les murs du bunker ; les personnages animés, leurs accessoires accrochés.
## Écrit dans audit_<n>.json les points de vue trouvés, pour les captures.
const AGENT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/hub/"
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]

var space: PhysicsDirectSpaceState3D
var views := []


func _initialize() -> void:
	_run.call_deferred()


func solid_hits(point: Vector3, radius: float, exclude: Array[RID] = []) -> Array:
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	query.shape = sphere
	query.transform = Transform3D(Basis(), point)
	query.exclude = exclude
	query.collide_with_areas = false
	return space.intersect_shape(query, 8)


func ground_at(point: Vector3, top: float) -> Variant:
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(point.x, top, point.z), Vector3(point.x, top - 8.0, point.z)))
	return hit.position.y if hit else null


func own_rids(node: Node) -> Array[RID]:
	var rids: Array[RID] = []
	for body in node.find_children("*", "CollisionObject3D", true, false):
		rids.append((body as CollisionObject3D).get_rid())
	for child in node.get_children(true):
		for body in child.find_children("*", "CollisionObject3D", true, false):
			rids.append((body as CollisionObject3D).get_rid())
		if child is CollisionObject3D:
			rids.append(child.get_rid())
	return rids


func audit_interactable(item: Interactable) -> void:
	var label := "%s" % level.get_path_to(item)
	var origin := item.global_position
	var base: Variant = ground_at(origin, origin.y + 1.0)
	var floor_y: float = base if base != null else origin.y
	var signs := item.get_children().filter(func(child: Node) -> bool: return child is SignBoard)
	var on_sign := not signs.is_empty()
	var height: float = (signs[0] as SignBoard).board_height if on_sign else (1.2 if origin.y - floor_y < 0.5 else 0.0)
	var target := origin + Vector3.UP * height + (item.global_basis.z * 0.25 if on_sign else Vector3.ZERO)
	var own := own_rids(item)
	var inside := solid_hits(target, 0.05, own)
	check("%s : point hors collision (%s)" % [label, target.snappedf(0.1)], inside.is_empty())
	var best: Variant = null
	# Points de vue d'abord devant l'objet (sa face +Z), puis de plus en plus sur les côtés.
	var facing := Vector3(item.global_basis.z.x, 0.0, item.global_basis.z.z).normalized()
	for distance: float in [2.0, 1.6, 2.5, 1.2, 3.0]:
		if distance > item.radius - 0.2:
			continue
		for step in 16:
			var turn := (step + 1) / 2 * (1 if step % 2 else -1)
			var direction := facing.rotated(Vector3.UP, TAU * turn / 16.0)
			var spot := origin + direction * distance
			var ground: Variant = ground_at(spot, origin.y + 2.5)
			if ground == null or absf(ground - floor_y) > 1.2:
				continue
			if not solid_hits(Vector3(spot.x, ground + 0.6, spot.z), 0.38).is_empty() or not solid_hits(Vector3(spot.x, ground + 1.4, spot.z), 0.38).is_empty():
				continue
			var eye := Vector3(spot.x, ground + 1.65, spot.z)
			var ray := PhysicsRayQueryParameters3D.create(eye, target)
			ray.exclude = own
			var hit := space.intersect_ray(ray)
			if hit and hit.position.distance_to(target) > 0.6:
				continue
			best = eye
			break
		if best != null:
			break
	check("%s : point de vue libre à portée" % label, best != null)
	if best == null:
		return
	# L'invite apparaît quand on le regarde depuis ce point.
	player.global_position = Vector3(best.x, best.y - 1.6, best.z)
	player.velocity = Vector3.ZERO
	await face(target)
	await wait(4)
	check("%s : invite « %s » (%s)" % [label, item.prompt, prompt()], prompt().contains(item.prompt))
	views.append({"name": label.replace("/", "_"), "eye": [best.x, best.y, best.z], "target": [target.x, target.y, target.z]})


func walk_in(name: String, door: Array, inside: Array) -> void:
	var start := Vector3(door[0], level.get_node("Terrain").surface_height(door[0], door[1]) + 0.4, door[1])
	player.global_position = start
	player.velocity = Vector3.ZERO
	await wait(5)
	await walk_to(Vector3(inside[0], 0, inside[1]), "%s : entree" % name, 300)
	await walk_to(Vector3(door[0], 0, door[1]), "%s : sortie" % name, 300)


func _run() -> void:
	var books := int(OS.get_cmdline_user_args()[0])
	state = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	for index in books:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await wait(60)
	level = current_scene
	player = level.get_node("Player")
	space = level.get_world_3d().direct_space_state

	# Personnages : pose animée et accessoires accrochés aux os.
	for character: Node3D in level.get_node("Characters").get_children():
		var animation: AnimationPlayer = character.get_node("Model/AnimationPlayer")
		check("%s anime (%s)" % [character.name, animation.current_animation], animation.is_playing())
	for path in ["Merlon/Model/character-human/Skeleton3D/Head/Gear/BeardChin", "Merlon/Model/character-human/Skeleton3D/Head/Gear/Hat",
			"Merlon/Model/character-human/Skeleton3D/Hand/Gear/Staff", "Codeon/Model/character-human/Skeleton3D/Head/Gear/Crown",
			"Codeon/Model/character-human/Skeleton3D/Torso/Gear/Cape", "Codeon/Model/character-human/Skeleton3D/Hand/Gear/Scepter"]:
		check("accessoire %s" % path.get_file(), level.get_node("Characters").has_node(path))

	# Bunker : plafond et murs pleins, au-dessus des lits superposés compris.
	for point in [Vector3(-8.2, 4.3, -3.9), Vector3(0, 4.3, 0), Vector3(8, 4.3, 3), Vector3(-9, 4.3, 5)]:
		var world: Vector3 = level.get_node("BunkerInterior").global_transform * point
		check("plafond du bunker en %s" % point, not solid_hits(world, 0.1).is_empty())
	for side in [Vector3(-10.0, 1.5, 0), Vector3(10.0, 1.5, 0), Vector3(0, 1.5, -6.0), Vector3(0, 1.5, 6.0)]:
		var world: Vector3 = level.get_node("BunkerInterior").global_transform * side
		check("mur du bunker en %s" % side, not solid_hits(world, 0.15).is_empty())

	# Interactables.
	for node in get_nodes_in_group(&"interactable"):
		var item := node as Interactable
		if not item.is_visible_in_tree():
			continue
		await audit_interactable(item)

	# Nouveaux bâtiments par leur porte.
	var doors: Array = JSON.parse_string(FileAccess.get_file_as_string(AGENT + "hub_doors.json"))
	for entry: Dictionary in doors:
		await walk_in(entry.name, entry.door, entry.inside)

	# Ruelles et ponts, de bout en bout.
	var terrain: HubTerrain = level.get_node("Terrain")
	for alley: Array in HubTerrain.ALLEYS:
		var first: Vector2 = alley[0]
		player.global_position = Vector3(first.x, terrain.surface_height(first.x, first.y) + 0.4, first.y)
		player.velocity = Vector3.ZERO
		await wait(5)
		for point: Vector2 in alley.slice(1):
			await walk_to(Vector3(point.x, 0, point.y), "ruelle vers %s" % point, 600)
	for alley: Array in HubTerrain.PARK_ALLEYS:
		var first: Vector2 = alley[0]
		player.global_position = Vector3(first.x, terrain.surface_height(first.x, first.y) + 0.4, first.y)
		await wait(5)
		for point: Vector2 in alley.slice(1):
			await walk_to(Vector3(point.x, 0, point.y), "allee du jardin vers %s" % point, 600)
	for bridge: Array in HubTerrain.BRIDGES:
		var axis := Vector2.from_angle(-deg_to_rad(float(bridge[2])))
		var a: Vector2 = Vector2(bridge[0], bridge[1]) - axis * (float(bridge[3]) * 0.5 + 2.0)
		var b: Vector2 = Vector2(bridge[0], bridge[1]) + axis * (float(bridge[3]) * 0.5 + 2.0)
		player.global_position = Vector3(a.x, terrain.surface_height(a.x, a.y) + 0.4, a.y)
		await wait(5)
		await walk_to(Vector3(b.x, 0, b.y), "pont en %s" % Vector2(bridge[0], bridge[1]), 600)
		check("pont en %s : on reste sur le tablier (y %.2f)" % [Vector2(bridge[0], bridge[1]), player.global_position.y], player.global_position.y > -0.3)
	# La rivière ne se traverse pas hors des ponts : on bute sur la berge.
	for crossing in [[Vector2(50, -40), Vector2(75, -40)], [Vector2(55, 30), Vector2(85, 30)]]:
		var a: Vector2 = crossing[0]
		player.global_position = Vector3(a.x, terrain.surface_height(a.x, a.y) + 0.4, a.y)
		await wait(5)
		var b: Vector2 = crossing[1]
		await walk_to(Vector3(b.x, 0, b.y), "traverser la riviere a gue (doit echouer)", 400)
		check("la berge arrete le joueur (x %.1f)" % player.global_position.x, player.global_position.x < 62.0 if a.y < 0 else player.global_position.x < 70.0)
	var file := FileAccess.open(AGENT + "audit_%d.json" % books, FileAccess.WRITE)
	file.store_string(JSON.stringify(views, " "))
	file.close()
	finish()
