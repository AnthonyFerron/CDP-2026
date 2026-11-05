extends "res://tests/scenes/common_test.gd"
## Textes à lire du récit environnemental des marais (avec fenêtre, sous Xvfb, pour les captures) :
## - chaque texte : le joueur y marche depuis le chemin, l'invite s'affiche face au panneau, le lecteur s'ouvre avec le
##   bon titre ; captures de la vue de lecture (avec l'invite), du lecteur ouvert, du panneau de près et de son dos ;
## - chaque panneau : texte entier dans la planche, poteaux posés au sol ou planche contre son mur, collision qui ne
##   pénètre aucun autre objet ;
## - autour de chaque panneau, une grille de 0,25 m : là où le joueur tenait debout sans le panneau, il tient encore,
##   sauf sur l'emprise du panneau lui-même.
## Usage : -- <dossier de sortie> --api=http://127.0.0.1:9/api/v1

## Texte, départ sur le chemin, point de lecture, invite, titre ; dedans : vrai pour la crypte.
const TEXTS := [
	["Clues/Notice", Vector3(0.0, 0.6, 57.0), Vector3(2.35, 0.4, 54.4), "Lire l'avis", "Avis de la capitainerie, an 5807", false],
	["Clues/AdaSlate", Vector3(8.6, 0.5, 1.8), Vector3(11.9, 0.4, 2.3), "Lire l'ardoise", "L'ardoise d'Ada", false],
	["Clues/RoyalOrder", Vector3(3.0, 0.6, -28.6), Vector3(3.95, 0.4, -30.8), "Lire l'ordre du roi", "Ordre du roi Codeon V, an 5812", false],
	["Interior/OssuaryRegister", Vector3(-12.0, -39.9, 0.0), Vector3(-16.6, -40.0, 2.2), "Lire le registre", "Registre de l'ossuaire", true],
	["Interior/GuardsOath", Vector3(12.0, -39.9, 0.0), Vector3(17.0, -40.0, 2.2), "Lire le serment", "Le serment des gardiens", true],
]
## Détours sûrs vers le point de lecture.
const VIA := {
	"Interior/OssuaryRegister": [Vector3(-15.5, -40.0, 1.0)],
	"Interior/GuardsOath": [Vector3(14.8, -40.0, 1.6)],
}

var out := ""
var space: PhysicsDirectSpaceState3D
var capsule := CapsuleShape3D.new()


func _initialize() -> void:
	capsule.radius = 0.38
	capsule.height = 1.7
	_run.call_deferred()


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + name + ".png")


func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	out = args[0] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	await start_level("res://scenes/levels/marais/marais.tscn")
	root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
	paused = false
	space = level.get_world_3d().direct_space_state
	for entry: Array in TEXTS:
		var path: String = entry[0]
		var item: Readable = level.get_node(path)
		var inside: bool = entry[5]
		if inside != bool(level.get("_inside")):
			level.set("_inside", inside)
			level.call("_apply_location")
			await wait(5)
		_check_board(item)
		_check_room(item)
		player.global_position = entry[1]
		player.velocity = Vector3.ZERO
		await wait(10)
		for point: Vector3 in VIA.get(path, []):
			await walk_to(point, "%s : détour" % path)
		await walk_to(entry[2], "%s : marche jusqu'au point de lecture" % path)
		await face(item.global_position)
		await wait(10)
		var name := path.get_file()
		check("%s : invite « %s »" % [path, prompt()], prompt() == "[E] " + entry[3] or prompt().ends_with(entry[3]))
		await shot(name + "_1_lecture")
		await press("interact")
		await wait(5)
		var reader: Control = hud().get_node("%Reader")
		var title: Label = hud().get_node("%ReaderTitle")
		var body: Label = hud().get_node("%ReaderBody")
		check("%s : lecteur ouvert, titre « %s »" % [path, title.text], reader.visible and title.text == entry[4])
		# Le texte tient dans l'écran : le bas du corps du texte reste au-dessus du bord de la fenêtre.
		var rect := body.get_global_rect()
		check("%s : texte entier à l'écran (%.0f à %.0f px)" % [path, rect.position.y, rect.end.y],
			rect.position.y >= 0.0 and rect.end.y <= root.get_visible_rect().size.y)
		check("%s : aucun symbole hors de l'alphabet latin" % path, _latin(title.text + body.text + _board_text(item)))
		await shot(name + "_2_lecteur")
		await press("interact")
		await wait(5)
		check("%s : lecteur refermé" % path, not reader.visible)
		await _closeups(item, name)
	# Les deux anciens panneaux sur poteaux, lisibles maintenant des deux côtés.
	level.set("_inside", false)
	level.call("_apply_location")
	await wait(5)
	for path in ["Clues/Welcome", "Clues/Plaque"]:
		await _closeups(level.get_node(path), path.get_file())
	finish()


func _board(item: Readable) -> SignBoard:
	return item.get_node("Board") as SignBoard


func _board_text(item: Readable) -> String:
	return _board(item).text


## Lettres latines (accents compris), chiffres et ponctuation simple : la version web n'a pas de police de secours.
func _latin(text: String) -> bool:
	for index in text.length():
		var code := text.unicode_at(index)
		if code > 0x17F and code != 0x2019:
			print("      symbole : %s (%X)" % [text[index], code])
			return false
	return true


func _check_board(item: Readable) -> void:
	var path := String(level.get_path_to(item))
	var board := _board(item)
	var label: Label3D
	var body: StaticBody3D
	for child in board.get_children(true):
		if child is Label3D and not label:
			label = child
		if child is StaticBody3D:
			body = child
	var wanted: float = board.line_height / (SignBoard.FONT_SIZE * 1.25)
	var size := label.font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, label.width,
		SignBoard.FONT_SIZE) * label.pixel_size
	var margin := 0.1 + (0.04 if board.style == SignBoard.Style.PARCHMENT else 0.0)
	var inner := board.board_size - Vector2(2, 2) * margin
	check("%s : texte du panneau dans la planche (%.2f x %.2f dans %.2f x %.2f, taille %.0f %%)" % [path, size.x, size.y,
		inner.x, inner.y, 100.0 * label.pixel_size / wanted], size.x <= inner.x + 0.002 and size.y <= inner.y + 0.002)
	var exclude: Array[RID] = [player.get_rid(), body.get_rid()]
	if board.mount == SignBoard.Mount.POSTS:
		for side in [-1.0, 1.0]:
			var foot: Vector3 = board.global_transform * Vector3(side * (board.board_size.x / 2.0 + 0.03), 0.0, -0.1)
			var ray := PhysicsRayQueryParameters3D.create(foot + Vector3.UP, foot + Vector3.DOWN * 2.0)
			ray.exclude = exclude
			var hit := space.intersect_ray(ray)
			var gap: float = foot.y - hit.position.y if not hit.is_empty() else INF
			check("%s : poteau %s au sol (écart %.3f m)" % [path, "gauche" if side < 0 else "droit", gap], absf(gap) < 0.03)
	else:
		var normal := board.global_basis.z.normalized()
		for offset in [Vector2.ZERO, Vector2(-0.45, -0.25), Vector2(0.45, 0.25), Vector2(-0.45, 0.25), Vector2(0.45, -0.25)]:
			var point: Vector3 = board.global_transform * Vector3(offset.x * board.board_size.x, board.board_height + offset.y * board.board_size.y, 0.0)
			var ray := PhysicsRayQueryParameters3D.create(point + normal * 0.02, point - normal * 0.4)
			ray.exclude = exclude
			var hit := space.intersect_ray(ray)
			var gap: float = (point - hit.position).dot(normal) if not hit.is_empty() else INF
			check("%s : planche contre le mur en %s (écart %.3f m)" % [path, offset, gap], gap > -0.03 and gap < 0.05)
	# Les formes du panneau ne pénètrent aucun autre objet (le sol et le mur qui le portent mis à part).
	for shape: CollisionShape3D in body.get_children():
		var query := PhysicsShapeQueryParameters3D.new()
		var reduced := BoxShape3D.new()
		reduced.size = (shape.shape as BoxShape3D).size - Vector3(0.04, 0.06, 0.04)
		query.shape = reduced
		query.transform = shape.global_transform
		query.exclude = exclude
		var names: PackedStringArray = []
		for hit in space.intersect_shape(query, 8):
			var other := hit.collider as Node
			var other_path := String(level.get_path_to(other))
			if other_path == "Terrain" or other_path.begins_with("Interior/Crypt"):
				continue
			names.append(other_path)
		check("%s : forme %s sans autre objet dedans %s" % [path, shape.name, names], names.is_empty())


## Autour du panneau : chaque point où le joueur tient debout en l'absence du panneau tient encore, hors de son emprise.
func _check_room(item: Readable) -> void:
	var path := String(level.get_path_to(item))
	var board := _board(item)
	var body: StaticBody3D
	for child in board.get_children(true):
		if child is StaticBody3D:
			body = child
	var center := board.global_position
	var lost := 0
	var tested := 0
	var x := -2.5
	while x <= 2.5:
		var z := -2.5
		while z <= 2.5:
			var top := center + Vector3(x, 2.5, z)
			var ray := PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 5.0)
			ray.exclude = [player.get_rid(), body.get_rid()]
			var hit := space.intersect_ray(ray)
			if not hit.is_empty() and (hit.normal as Vector3).y > 0.7:
				var feet: Vector3 = hit.position
				var without := _fits(feet, [player.get_rid(), body.get_rid()])
				var with := _fits(feet, [player.get_rid()])
				if without:
					tested += 1
					var local := board.global_transform.affine_inverse() * feet
					var footprint := absf(local.x) < board.board_size.x / 2.0 + 0.55 and local.z > -0.75 and local.z < 0.65
					var lantern := Vector2(feet.x - 12.75, feet.z - 3.75).length() < 0.75
					if not with and not footprint and not lantern:
						lost += 1
						print("      place perdue en %s" % feet.snappedf(0.01))
			z += 0.25
		x += 0.25
	check("%s : %d places autour du panneau, %d perdues hors de son emprise" % [path, tested, lost], lost == 0)


func _fits(feet: Vector3, exclude: Array[RID]) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis(), feet + Vector3.UP * 0.95)
	query.exclude = exclude
	return space.intersect_shape(query, 1).is_empty()


## Le panneau de près, face et dos, depuis une caméra libre (l'interface cachée).
func _closeups(item: Readable, name: String) -> void:
	var board := _board(item)
	var camera := Camera3D.new()
	camera.fov = 60.0
	level.add_child(camera)
	var normal := board.global_basis.z.normalized()
	var center: Vector3 = board.global_transform * Vector3(0.0, board.board_height, 0.0)
	hud().visible = false
	camera.current = true
	camera.global_position = center + normal * 1.6 + Vector3.UP * 0.1
	camera.look_at(center, Vector3.UP)
	await wait(4)
	await shot(name + "_3_face")
	if board.mount == SignBoard.Mount.POSTS:
		camera.global_position = center - normal * 1.6 + Vector3.UP * 0.1
		camera.look_at(center, Vector3.UP)
		await wait(4)
		await shot(name + "_4_dos")
	# Vue d'ensemble, de plus loin et de biais : le panneau dans son décor.
	camera.global_position = center + normal * 4.5 + normal.cross(Vector3.UP) * 2.0 + Vector3.UP * 0.6
	camera.look_at(center + Vector3.DOWN * 0.6, Vector3.UP)
	await wait(4)
	await shot(name + "_5_ensemble")
	hud().visible = true
	camera.queue_free()
	await wait(2)
	(player.get_node("CameraPivot/SpringArm3D/Camera3D") as Camera3D).current = true
