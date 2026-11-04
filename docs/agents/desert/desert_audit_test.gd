extends "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/common_test.gd"
## Audit du Désert. Pour chaque interactable (runes, tas de sable, stèles, carnet, inscription, algorithmes,
## table ronde, livre du coffre, trappe, sortie, portail) :
## - son point n'est dans aucune collision, et une rune ou un tas est posé sur son support, rien au-dessus ;
## - un point de sol accessible à pied depuis l'arrivée (grille de 0,5 m parcourue en largeur) existe à portée ;
## - depuis ce point, la vue des yeux du joueur (1,65 m) jusqu'à l'objet n'est coupée ni par une collision ni
##   par un modèle (test sur les triangles des maillages, MultiMesh compris) ;
## - le joueur posé à ce point et tourné vers l'objet reçoit bien l'invite de l'objet ;
## - une capture est prise depuis ce point (sans --headless).
## Vérifie aussi que les lieux du décor sont accessibles et liste les modèles qui semblent flotter.
## Lancer sans --headless avec --resolution 1280x720 pour les captures.

const OUT := "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/audit/"
const CELL := 0.5
## Décalage des points de la grille, pour ne pas tomber pile sur la jointure de deux dalles de collision.
const JITTER := 0.013
const EYE := 1.65
## Nœuds qui ne font que ranger des objets : un interactable sans enfant posé directement dessous est son propre objet.
const CONTAINERS := ["Exterior", "Interior", "Clues", "Runes", "SandPiles", "Desert"]
## Lieux du décor qui doivent rester accessibles : nom, point (x, z), dans la cave.
const PLACES := [
	["arche d'entrée", Vector2(0, 16), false],
	["allée des obélisques", Vector2(0, 32), false],
	["salle des colonnes", Vector2(0, -2), false],
	["chambre du levant", Vector2(-16, -11), false],
	["chambre du zénith", Vector2(16, -11), false],
	["portique du sanctuaire englouti", Vector2(0, -25), false],
	["campement de la caravane", Vector2(-33, -26), false],
	["puits de l'oasis", Vector2(36.2, 0.2), false],
	["bassin asséché", Vector2(41, -3), false],
	["abords de la citerne", Vector2(-30, 3), false],
	["tête colossale", Vector2(-29, 34), false],
	["poste de garde", Vector2(36, 27), false],
	["colonnade engloutie", Vector2(-20, -44), false],
	["porte des vents", Vector2(21, -41), false],
	["tombes des caravaniers", Vector2(-24, 45), false],
	["sous les côtes de la bête des sables", Vector2(26, 50), false],
	["pied de l'escalier de la cave", Vector2(0, -1), true],
	["coin du coffre de pierre", Vector2(6, -8.4), true],
	["pupitre de lecture", Vector2(2.6, -2.8), true],
]

var space: PhysicsDirectSpaceState3D
var camera: Camera3D
var terrain: Node
var shots := false
var capsule := CapsuleShape3D.new()
var tri_cache := {}
var meshes: Array[MeshInstance3D] = []
var multimeshes: Array[MultiMeshInstance3D] = []
## Grille accessible de la zone en cours : case -> hauteur du sol.
var reach := {}
var reach_lo := Vector2.ZERO
var player_rid: RID


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await start_level("res://scenes/levels/desert/desert.tscn")
	shots = DisplayServer.get_name() != "headless"
	if shots:
		DirAccess.make_dir_recursive_absolute(OUT)
	space = player.get_world_3d().direct_space_state
	terrain = level.get_node("Exterior/Terrain")
	player_rid = player.get_rid()
	capsule.radius = 0.36
	capsule.height = 1.7
	camera = Camera3D.new()
	camera.fov = 75.0
	level.add_child(camera)
	camera.current = true
	await wait(5)
	_collect_visuals(level)
	print("AUDIT %d maillages, %d multimaillages" % [meshes.size(), multimeshes.size()])

	# Extérieur.
	set_inside(false)
	await wait(5)
	var start := Time.get_ticks_msec()
	build_reach(Vector3(0, 0, 48), false)
	print("AUDIT grille extérieure : %d cases accessibles (%d ms)" % [reach.size(), Time.get_ticks_msec() - start])
	for place: Array in PLACES:
		if not place[2]:
			check("lieu accessible : " + place[0], nearest_cell(Vector3(place[1].x, 0, place[1].y), 2.0) != null)
	for target in exterior_targets():
		await audit(target[0], target[1])
	report_floating(level.get_node("Exterior/Ruins"), false)

	# Cave.
	set_inside(true)
	await wait(5)
	build_reach(level.get_node("Interior/InsideSpawn").global_position, true)
	print("AUDIT grille de la cave : %d cases accessibles" % reach.size())
	for place: Array in PLACES:
		if place[2]:
			check("lieu accessible : " + place[0], nearest_cell(Vector3(place[1].x, -40, place[1].y), 1.5) != null)
	for target in interior_targets():
		await audit(target[0], target[1])
	report_floating(level.get_node("Interior/Cellar"), true)
	finish()


func set_inside(inside: bool) -> void:
	level.set("_inside", inside)
	level.call("_apply_location")


func exterior_targets() -> Array:
	var list := []
	for child in level.get_node("Exterior/Portal").get_children(true):
		if child is Interactable:
			list.append([child, "portail"])
	for clue: Node in level.get_node("Exterior/Clues").get_children():
		list.append([clue, "indice " + clue.name])
	list.append([level.get_node("Exterior/Trapdoor/Interactable"), "trappe"])
	for pile: Node in level.get_node("SandPiles").get_children():
		if pile.global_position.y > -20:
			list.append([pile, "tas " + pile.name])
	for rune: Node in level.get_node("Runes").get_children():
		if rune.global_position.y > -20:
			list.append([rune, "rune " + rune.name])
	return list


func interior_targets() -> Array:
	var list := []
	list.append([level.get_node("Interior/Exit"), "sortie de la cave"])
	list.append([level.get_node("Interior/RoundTable/Interactable"), "table ronde"])
	for clue: Node in level.get_node("Interior/Clues").get_children():
		list.append([clue, "indice " + clue.name])
	for pile: Node in level.get_node("SandPiles").get_children():
		if pile.global_position.y < -20:
			list.append([pile, "tas " + pile.name])
	for rune: Node in level.get_node("Runes").get_children():
		if rune.global_position.y < -20:
			list.append([rune, "rune " + rune.name])
	list.append([level.get_node("Interior/Book/Interactable"), "livre du coffre"])
	return list


## Vérifie un interactable ; une rune cachée est d'abord dégagée de son tas, le livre sorti du coffre.
func audit(target: Interactable, label: String) -> void:
	var restore := []
	if target is Rune and not target.visible:
		target.reveal()
		restore.append(func() -> void:
			target.visible = false
			target.enabled = false)
	if label == "livre du coffre":
		var book: Node3D = level.get_node("Interior/Book")
		book.show()
		level.get_node("Interior/Chest").show()
		level.get_node("Interior/ChestSand").hide()
		target.enabled = true
		restore.append(func() -> void:
			book.hide()
			target.enabled = false
			level.get_node("Interior/Chest").hide()
			level.get_node("Interior/ChestSand").show())
	await wait(2)
	var root := object_root(target)
	var exclude := bodies_under(root)
	exclude.append(player_rid)
	var look := look_point(target, root)
	var anchor := look
	if target is Rune:
		anchor = target.global_position + Vector3.UP * 0.06
	elif target is SandPile:
		anchor = target.global_position + Vector3.UP * 0.25

	# Dans aucune collision.
	var query := PhysicsPointQueryParameters3D.new()
	query.position = anchor
	query.exclude = exclude
	var inside_hits := space.intersect_point(query, 4)
	check("%s : hors des collisions%s" % [label, describe(inside_hits)], inside_hits.is_empty())
	# Posé sur son support, rien au-dessus.
	if target is Rune or target is SandPile:
		var base: Vector3 = target.global_position
		var down := ray(base + Vector3.UP * 0.3, base + Vector3.DOWN * 0.5, exclude)
		var support := "rien" if down.is_empty() else "%.2f" % (down.position.y - base.y)
		check("%s : posé sur son support (écart %s)" % [label, support], not down.is_empty() and absf(down.position.y - base.y) < 0.1)
		var up := ray(base + Vector3.UP * 0.15, base + Vector3.UP * 2.2, exclude)
		check("%s : rien au-dessus%s" % [label, describe_hit(up)], up.is_empty())
		var above := visual_hit(base + Vector3.UP * 0.2, base + Vector3.UP * 2.2, root)
		check("%s : aucun modèle au-dessus %s" % [label, above], above == "")
	# Point de sol accessible, à portée, vue dégagée et invite.
	var stand: Variant = await find_stand(target, look, exclude, root)
	check("%s : point accessible à portée, vue dégagée, invite « %s »" % [label, target.prompt], stand != null)
	if stand != null and shots:
		await wait(2)
		await RenderingServer.frame_post_draw
		root_viewport_image().save_png(OUT + label.validate_filename().replace(" ", "_") + ".png")
	for undo: Callable in restore:
		undo.call()
	# Un tas audité est dégagé, pour auditer ensuite la rune qu'il cache.
	if target is SandPile and not target.is_cleared:
		target.progress = 1.0
		target.call("_finish")


func root_viewport_image() -> Image:
	return root.get_texture().get_image()


## Objet auquel appartient l'interactable : lui-même s'il a des enfants ou s'il est rangé dans un conteneur,
## sinon son parent (trappe, table, livre, portail).
func object_root(target: Node) -> Node:
	if target.get_child_count(true) > 0 or String(target.get_parent().name) in CONTAINERS:
		return target
	return target.get_parent()


func bodies_under(node: Node) -> Array[RID]:
	var list: Array[RID] = []
	if node is CollisionObject3D:
		list.append(node.get_rid())
	for child in node.get_children(true):
		list.append_array(bodies_under(child))
	return list


func look_point(target: Node3D, root: Node) -> Vector3:
	if target is Rune:
		return target.global_position + Vector3.UP * 0.1
	if target is SandPile:
		return target.global_position + Vector3.UP * 0.35
	var box := visual_box(root)
	return target.global_position if box.size == Vector3.ZERO else box.get_center()


func visual_box(node: Node) -> AABB:
	var box := AABB()
	var first := true
	for child in all_children(node):
		if child is MeshInstance3D and child.is_visible_in_tree() and child.mesh:
			var b: AABB = child.global_transform * child.get_aabb()
			box = b if first else box.merge(b)
			first = false
	return box


func all_children(node: Node) -> Array[Node]:
	var list: Array[Node] = [node]
	for child in node.get_children(true):
		list.append_array(all_children(child))
	return list


func _collect_visuals(node: Node) -> void:
	if node == player:
		return
	if node is MeshInstance3D and node.mesh:
		meshes.append(node)
	elif node is MultiMeshInstance3D and node.multimesh and node.multimesh.mesh:
		multimeshes.append(node)
	for child in node.get_children(true):
		_collect_visuals(child)


func tri(mesh: Mesh) -> TriangleMesh:
	if not tri_cache.has(mesh):
		tri_cache[mesh] = mesh.generate_triangle_mesh()
	return tri_cache[mesh]


## Premier modèle visible (hors de l'objet) qui coupe le segment, ou "".
func visual_hit(from: Vector3, to: Vector3, root: Node) -> String:
	for mesh in meshes:
		if not is_instance_valid(mesh) or not mesh.is_visible_in_tree() or mesh == root or root.is_ancestor_of(mesh):
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		if not box.grow(0.01).intersects_segment(from, to):
			continue
		var shape := tri(mesh.mesh)
		if shape == null:
			continue
		var inverse := mesh.global_transform.affine_inverse()
		if not shape.intersect_segment(inverse * from, inverse * to).is_empty():
			return str(mesh.get_path()).replace("/root/Desert/", "")
	for instance in multimeshes:
		if not instance.is_visible_in_tree():
			continue
		var multimesh := instance.multimesh
		var shape := tri(multimesh.mesh)
		var local_box := multimesh.mesh.get_aabb()
		for index in multimesh.instance_count:
			var xform := instance.global_transform * multimesh.get_instance_transform(index)
			if not (xform * local_box).grow(0.01).intersects_segment(from, to):
				continue
			var inverse := xform.affine_inverse()
			if not shape.intersect_segment(inverse * from, inverse * to).is_empty():
				return "%s[%d]" % [str(instance.get_path()).replace("/root/Desert/", ""), index]
	return ""


func ray(from: Vector3, to: Vector3, exclude: Array[RID]) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = exclude
	return space.intersect_ray(query)


func describe(hits: Array) -> String:
	if hits.is_empty():
		return ""
	var names := []
	for hit: Dictionary in hits:
		names.append(str(hit.collider.get_path()).replace("/root/Desert/", "") + "/" + str(hit.shape))
	return " (dans " + ", ".join(names) + ")"


func describe_hit(hit: Dictionary) -> String:
	if hit.is_empty():
		return ""
	return " (%s à %.2f m)" % [str(hit.collider.get_path()).replace("/root/Desert/", ""), hit.position.y]


func in_quicksand(x: float, z: float) -> bool:
	for sand in DesertTerrain.QUICKSANDS:
		if Vector2(x - sand.x, z - sand.y).length() < sand.z * 0.85 + 0.4:
			return true
	return false


## Hauteur du sol libre en (x, z), ou NAN si le joueur ne peut s'y tenir.
func floor_at(x: float, z: float, inside: bool) -> float:
	if not inside and in_quicksand(x, z):
		return NAN
	var base: float = -40.0 if inside else terrain.surface_height(x, z)
	var hit := ray(Vector3(x, base + 0.45, z), Vector3(x, base - 0.6, z), [player_rid])
	if hit.is_empty() or hit.normal.y < 0.72:
		return NAN
	var y: float = hit.position.y
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis(), Vector3(x, y + 0.18 + 0.85, z))
	query.exclude = [player_rid]
	if not space.intersect_shape(query, 1).is_empty():
		return NAN
	return y


func build_reach(start: Vector3, inside: bool) -> void:
	var lo := Vector2(-11, -13) if inside else Vector2(-66, -66)
	var hi := Vector2(11, 5) if inside else Vector2(66, 66)
	reach_lo = lo
	var floors := {}
	for i in int((hi.x - lo.x) / CELL) + 1:
		for j in int((hi.y - lo.y) / CELL) + 1:
			var y := floor_at(lo.x + i * CELL + JITTER, lo.y + j * CELL + JITTER, inside)
			if not is_nan(y):
				floors[Vector2i(i, j)] = y
	var origin := Vector2i(roundi((start.x - lo.x) / CELL), roundi((start.z - lo.y) / CELL))
	var first: Variant = null
	var best := INF
	for key: Vector2i in floors:
		var d := Vector2(key - origin).length()
		if d < best:
			best = d
			first = key
	reach = {}
	if first == null:
		return
	var queue: Array[Vector2i] = [first]
	reach[first] = floors[first]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next := cell + step
			if reach.has(next) or not floors.has(next):
				continue
			if absf(floors[next] - floors[cell]) > 0.3:
				continue
			reach[next] = floors[next]
			queue.append(next)


func cell_position(key: Vector2i) -> Vector3:
	return Vector3(reach_lo.x + key.x * CELL + JITTER, reach[key], reach_lo.y + key.y * CELL + JITTER)


func nearest_cell(point: Vector3, within: float) -> Variant:
	for key: Vector2i in reach:
		var p := cell_position(key)
		if Vector2(p.x - point.x, p.z - point.z).length() <= within:
			return p
	return null


## Cherche un point accessible d'où l'objet se voit et d'où son invite apparaît.
func find_stand(target: Interactable, look: Vector3, exclude: Array[RID], root: Node) -> Variant:
	var center := target.global_position
	var reach_radius := target.radius * 0.9
	var preferred := minf(1.7, reach_radius * 0.7)
	var candidates := []
	for key: Vector2i in reach:
		var p := cell_position(key)
		var d := Vector2(p.x - center.x, p.z - center.z).length()
		if d > reach_radius or d < 0.45 or absf(center.y - p.y) >= 2.9:
			continue
		candidates.append([absf(d - preferred), p])
	if candidates.is_empty():
		print("    aucune case accessible dans le rayon %.1f m" % reach_radius)
		return null
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var tried := 0
	var blocked := ""
	for candidate: Array in candidates:
		var p: Vector3 = candidate[1]
		var eye := p + Vector3.UP * EYE
		var hit := ray(eye, look, exclude)
		if not hit.is_empty():
			blocked = "collision " + describe_hit(hit)
			continue
		var model := visual_hit(eye, look, root)
		if model != "":
			blocked = "modèle " + model
			continue
		await place_player(p, look)
		if prompt().ends_with(target.prompt):
			return p
		blocked = "invite « %s »" % prompt()
		tried += 1
		if tried >= 30:
			break
	print("    %d cases à portée, dernier obstacle : %s" % [candidates.size(), blocked])
	return null


func place_player(stand: Vector3, look: Vector3) -> void:
	# La fenêtre du test peut perdre le focus : le menu de pause s'ouvrirait et figerait le jeu.
	var pause: Node = root.get_node("PauseMenu")
	if pause.is_open():
		pause.close()
	paused = false
	player.global_position = stand + Vector3.UP * 0.03
	player.velocity = Vector3.ZERO
	var offset := look - stand
	player.get_node("CameraPivot").rotation.y = atan2(-offset.x, -offset.z)
	camera.global_position = stand + Vector3.UP * EYE
	if Vector2(offset.x, offset.z).length() > 0.05:
		camera.look_at(look, Vector3.UP)
	await wait(4)
	player.global_position = stand + Vector3.UP * 0.03
	await wait(2)


## Liste les modèles dont le bas semble flotter au-dessus du sol (avis, sans échec).
func report_floating(scene_root: Node, inside: bool) -> void:
	var models := scene_root.get_node_or_null("Models")
	if not models:
		return
	for model: Node in models.get_children():
		var box := visual_box(model)
		if box.size == Vector3.ZERO:
			continue
		var c := box.get_center()
		var bottom := box.position.y
		var exclude: Array[RID] = [player_rid]
		var hit := ray(Vector3(c.x, bottom + 0.05, c.z), Vector3(c.x, bottom - 1.0, c.z), exclude)
		var ground: float = -40.0 if inside else terrain.surface_height(c.x, c.z)
		if not hit.is_empty():
			ground = maxf(ground, hit.position.y)
		if bottom > ground + 0.15:
			print("AVIS flotte de %.2f m : %s en %s" % [bottom - ground, model.name, c.snappedf(0.1)])
