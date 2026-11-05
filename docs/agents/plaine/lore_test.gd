extends "res://tests/scenes/common_test.gd"
## Contrôle des textes à lire du récit environnemental (à lancer avec fenêtre, sous Xvfb, pour les captures) :
## - chaque texte : point hors des collisions, sol accessible à pied à portée (remplissage depuis l'arrivée), ligne
##   de vue libre depuis les yeux, invite affichée, lecteur ouvert avec le bon titre, texte entier dans l'écran ;
## - chaque panneau : poteaux posés au sol, planche contre son mur, collision sans chevauchement, texte à sa taille ;
## - chaque parchemin : posé sur son meuble ;
## - les autres interactables du lieu gardent leur invite (aucun texte ne la leur vole).
## Usage : -- <dossier de sortie> [all] --api=http://127.0.0.1:9/api/v1

const EYE := 1.65
const STEP := 0.6
const INSIDE_STEP := 0.3
const NEW := ["Exterior/Lore/Fete", "Exterior/Lore/Arpenteur", "Exterior/Lore/Proclamation",
	"Interior/Lore/Lettre", "Interior/Lore/Greffier", "Interior/Lore/Reglement"]

var out := ""
var space: PhysicsDirectSpaceState3D
var capsule := CapsuleShape3D.new()
var outside := {}
var inside := {}


func _initialize() -> void:
	capsule.radius = 0.4
	capsule.height = 1.8
	_run.call_deferred()


func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	out = args[0] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	space = level.get_world_3d().direct_space_state
	outside = _flood(level.get_node("Exterior/OutsideSpawn").global_position, Vector2(-70, -70), Vector2(70, 70), STEP,
		30.0, -12.0)
	_flood_from(outside, player.global_position, Vector2(-70, -70), Vector2(70, 70), STEP, 30.0, -12.0)
	inside = _flood(level.get_node("Interior/InsideSpawn").global_position, Vector2(-6.5, -44.8), Vector2(6.5, 0.6),
		INSIDE_STEP, -36.2, -42.5)
	check("sol dehors accessible : %d cases" % outside.size(), outside.size() > 5000)
	check("sol des archives accessible : %d cases" % inside.size(), inside.size() > 1500)

	for path: String in NEW:
		var item: Readable = level.get_node(path)
		_check_placement(item)
		await _audit(item, true)
	if args.has("all"):
		for node in root.get_tree().get_nodes_in_group(&"interactable"):
			var item := node as Interactable
			if item.enabled and not NEW.has(String(level.get_path_to(item))):
				await _audit(item, false)
	finish()


func _is_interior(node: Node) -> bool:
	return level.get_node("Interior").is_ancestor_of(node)


func _ground(x: float, z: float, top: float, bottom: float, exclude: Array[RID] = []) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, bottom, z))
	query.collide_with_areas = false
	query.exclude = exclude
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


func _flood(start: Vector3, low: Vector2, high: Vector2, step: float, top: float, bottom: float) -> Dictionary:
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


## Pose du panneau ou du parchemin : au sol, contre son mur, sur son meuble ; collisions sans chevauchement.
func _check_placement(item: Readable) -> void:
	var label := String(level.get_path_to(item))
	var board := item.get_node_or_null("Sign")
	var terrain: Node3D = level.get_node("Exterior/Terrain")
	if board == null:
		# Parchemin : le dessus visible du meuble (sommet de la boîte de son maillage) est juste sous la feuille, aux
		# quatre coins et au centre, et aucun autre maillage n'en traverse le dessous.
		var sheet: MeshInstance3D = item.get_node("Sheet")
		var bottom := sheet.global_position.y - 0.0015
		for corner in [Vector3.ZERO, Vector3(-0.13, 0, -0.17), Vector3(0.13, 0, -0.17), Vector3(-0.13, 0, 0.17), Vector3(0.13, 0, 0.17)]:
			var point: Vector3 = sheet.global_transform * corner
			var support := -INF
			var support_name := "rien"
			for mesh: MeshInstance3D in level.get_node("Interior/Library").find_children("*", "MeshInstance3D", true, false):
				var box: AABB = mesh.global_transform * mesh.get_aabb()
				if point.x < box.position.x or point.x > box.end.x or point.z < box.position.z or point.z > box.end.z:
					continue
				if box.end.y > bottom + 0.05 or box.end.y < bottom - 0.3:
					continue
				if box.end.y > support:
					support = box.end.y
					support_name = String(mesh.get_parent().name) + "/" + String(mesh.name)
			var gap := bottom - support
			check("%s : coin %s posé sur %s (écart %.4f m)" % [label, corner, support_name, gap], gap >= -0.0005 and gap < 0.004)
		return
	var sign_board: SignBoard = board
	var body: StaticBody3D
	for child in sign_board.get_children(true):
		if child is StaticBody3D:
			body = child
	var labels: Array = sign_board.find_children("*", "Label3D", true, false)
	for child in sign_board.get_children(true):
		if child is Label3D:
			labels.append(child)
	if not labels.is_empty():
		var text_label: Label3D = labels[0]
		var wanted: float = sign_board.line_height / (SignBoard.FONT_SIZE * 1.25)
		var font: Font = text_label.font
		var size := font.get_multiline_string_size(text_label.text, HORIZONTAL_ALIGNMENT_CENTER, text_label.width,
			SignBoard.FONT_SIZE) * text_label.pixel_size
		var margin := 0.1 + (0.04 if sign_board.style == SignBoard.Style.PARCHMENT else 0.0)
		var inner := sign_board.board_size - Vector2(2, 2) * margin
		check("%s : texte « %s » dans la planche (%.2f x %.2f dans %.2f x %.2f, taille %.0f %%)" % [label,
			text_label.text, size.x, size.y, inner.x, inner.y, 100.0 * text_label.pixel_size / wanted],
			size.x <= inner.x + 0.002 and size.y <= inner.y + 0.002)
	var exclude: Array[RID] = [player.get_rid()]
	if body:
		exclude.append(body.get_rid())
	if sign_board.mount == SignBoard.Mount.POSTS:
		for side in [-1.0, 1.0]:
			var foot: Vector3 = sign_board.global_transform * Vector3(side * (sign_board.board_size.x / 2.0 + 0.03), 0.0,
				-0.05 - 0.05)
			var hit := _ground(foot.x, foot.z, foot.y + 1.0, foot.y - 2.0, exclude)
			var gap: float = foot.y - hit.position.y if not hit.is_empty() else INF
			check("%s : poteau %s au sol (écart %.3f m)" % [label, "gauche" if side < 0 else "droit", gap], absf(gap) < 0.03)
	elif sign_board.mount == SignBoard.Mount.WALL:
		var back: Vector3 = sign_board.global_transform * Vector3(0.0, sign_board.board_height, 0.0)
		var normal := sign_board.global_basis.z.normalized()
		for offset in [Vector3.ZERO, Vector3(-0.4, -0.25, 0), Vector3(0.4, 0.25, 0), Vector3(-0.4, 0.25, 0), Vector3(0.4, -0.25, 0)]:
			var point: Vector3 = sign_board.global_transform * (Vector3(0.0, sign_board.board_height, 0.0) + offset * Vector3(sign_board.board_size.x, sign_board.board_size.y, 1) / Vector3(1.1, 0.7, 1))
			var ray := PhysicsRayQueryParameters3D.create(point + normal * 0.02, point - normal * 0.3)
			ray.exclude = exclude
			var hit := space.intersect_ray(ray)
			var gap: float = (point - hit.position).dot(normal) if not hit.is_empty() else INF
			check("%s : planche contre le mur en %s (écart %.3f m)" % [label, offset, gap], gap > -0.02 and gap < 0.04)
		var foot_hit := _ground(back.x + normal.x * 0.5, back.z + normal.z * 0.5, back.y, back.y - 4.0, exclude)
		print("      sol devant le mur : %.3f, bas de la planche à %.2f m" % [foot_hit.position.y if not foot_hit.is_empty() else NAN,
			back.y - sign_board.board_size.y / 2.0 - (foot_hit.position.y if not foot_hit.is_empty() else 0.0)])
	# Les formes de collision du panneau ne pénètrent rien d'autre que le sol ou le mur qui le porte.
	if body:
		for shape: CollisionShape3D in body.get_children():
			var query := PhysicsShapeQueryParameters3D.new()
			var box: BoxShape3D = shape.shape
			var reduced := BoxShape3D.new()
			reduced.size = box.size - Vector3(0.02, 0.06, 0.02)
			query.shape = reduced
			query.transform = shape.global_transform.translated(Vector3.UP * 0.03)
			query.collide_with_areas = false
			query.exclude = exclude + ([terrain.get_rid()] if not _is_interior(item) else [])
			var hits := space.intersect_shape(query, 4)
			var names: Array[String] = []
			for other in hits:
				names.append(String(level.get_path_to(other.collider)) + "#" + str(other.shape))
			var allowed := sign_board.mount == SignBoard.Mount.WALL
			check("%s : collision %s sans chevauchement %s" % [label, shape.position.snappedf(0.01), names],
				hits.is_empty() or allowed)


## Un interactable : point libre, sol accessible à portée, vue dégagée, invite, et pour un texte neuf, son lecteur.
func _audit(item: Interactable, capture: bool) -> void:
	var interior := _is_interior(item)
	level.set("_inside", interior)
	level.call("_apply_location")
	var point := item.global_position
	var label := String(level.get_path_to(item))
	var floor_hit := _ground(point.x, point.z, point.y + 0.05, point.y - 3.0)
	var probe := point
	if not floor_hit.is_empty() and point.y - floor_hit.position.y < 0.1:
		probe.y = floor_hit.position.y + 0.1
	var point_query := PhysicsPointQueryParameters3D.new()
	point_query.position = probe + Vector3.UP * 0.01
	point_query.collide_with_areas = false
	var inside_hits := space.intersect_point(point_query, 4)
	check("%s : point hors des collisions" % label, inside_hits.is_empty())
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
	var shown := 0
	var tried := 0
	var first_spot := Vector3.INF
	for entry: Array in candidates:
		var spot: Vector3 = entry[1]
		tried += 1
		if tried > 60:
			break
		var eye := spot + Vector3.UP * EYE
		var ray := PhysicsRayQueryParameters3D.create(eye, target)
		ray.collide_with_areas = false
		ray.exclude = [player.get_rid()]
		var hit := space.intersect_ray(ray)
		if not hit.is_empty() and hit.position.distance_to(target) > 0.12:
			continue
		seen = true
		player.global_position = spot + Vector3.UP * 0.05
		player.velocity = Vector3.ZERO
		var pivot: Node3D = player.get_node("CameraPivot")
		var offset := target - eye
		pivot.rotation.y = atan2(-offset.x, -offset.z)
		pivot.rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())
		paused = false
		await wait(3)
		await process_frame
		await process_frame
		if item.focused and prompt().contains(item.prompt):
			shown += 1
			if first_spot == Vector3.INF:
				first_spot = spot
				if capture:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(out + label.get_file() + "_invite.png")
			if not capture or shown >= 3:
				break
	check("%s : ligne de vue libre depuis les yeux" % label, seen)
	check("%s : invite « %s » affichée (%d places essayées, vue depuis %s)" % [label, item.prompt, tried,
		first_spot.snappedf(0.1)], shown > 0)
	if capture and shown > 0:
		player.global_position = first_spot + Vector3.UP * 0.05
		var offset := target - (first_spot + Vector3.UP * EYE)
		player.get_node("CameraPivot").rotation.y = atan2(-offset.x, -offset.z)
		player.get_node("CameraPivot").rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())
		paused = false
		await wait(4)
		await press("interact")
		await wait(4)
		var reader: Control = hud().get_node("%Reader")
		var title: Label = hud().get_node("%ReaderTitle")
		var body: Label = hud().get_node("%ReaderBody")
		check("%s : lecteur ouvert, titre « %s »" % [label, title.text], reader.visible and title.text == (item as Readable).title)
		var panel: Control = reader.get_node("Panel")
		var screen := hud().get_viewport().get_visible_rect()
		var rect := panel.get_global_rect()
		check("%s : texte entier dans l'écran (%d lignes, cadre %s dans %s)" % [label, body.get_line_count(),
			rect, screen.size], screen.encloses(rect) and body.get_visible_line_count() == body.get_line_count())
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + label.get_file() + "_lecteur.png")
		await press("interact")
		await wait(3)
		check("%s : lecteur refermé" % label, not reader.visible)
	player.get_node("CameraPivot").rotation.x = 0.0
