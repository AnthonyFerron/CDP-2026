extends "res://tests/scenes/common_test.gd"
## Panneaux du désert (SignBoard), un par un :
## - plus aucun PostsBody ajouté à la main ; collision du SignBoard : 3 formes sur poteaux, 1 au mur ou suspendu ;
## - rayons sous la planche, entre les poteaux : rien ne bloque ; rayons sur la planche et sur chaque poteau : bloqués ;
## - grille de 0,5 m autour du panneau (1,5 m au-delà de ses bords) : en chaque point libre, le joueur marche 1 s
##   dans 8 directions ; chaque contact non vertical doit avoir un triangle visible à moins de 0,5 m (sinon mur
##   invisible), le joueur ne reste coincé nulle part et ne tombe pas ;
## - sur poteaux, chacun des deux poteaux et la planche arrêtent le joueur au moins une fois ;
## - captures de face et de dos (sans --headless) dans --out=<dossier>.
## Lancer avec « sans_regroupement » pour que le test des triangles voie chaque modèle.

const SIGN_SCRIPT := "res://scripts/sign_board.gd"
const STEP := 0.5
const MARGIN := 1.5
const JITTER := 0.013
const WALK_FRAMES := 60

var out_dir := ""
var space: PhysicsDirectSpaceState3D
var meshes: Array[MeshInstance3D] = []
var multimeshes: Array[MultiMeshInstance3D] = []
var tri_cache := {}
var capsule := CapsuleShape3D.new()
var only := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out_dir = argument.substr(6) + "/"
		elif argument.begins_with("--only="):
			only = argument.substr(7)
	var shots := DisplayServer.get_name() != "headless" and out_dir != ""
	if shots:
		DirAccess.make_dir_recursive_absolute(out_dir)
	await start_level("res://scenes/levels/desert/desert.tscn")
	space = player.get_world_3d().direct_space_state
	capsule.radius = 0.4
	capsule.height = 1.8
	await wait(5)
	_collect(level)
	var signs: Array[Node3D] = []
	_find_signs(level, signs)
	print("PANNEAUX %d SignBoard, %d maillages, %d multimaillages" % [signs.size(), meshes.size(), multimeshes.size()])
	var extra := level.find_children("PostsBody", "", true, false)
	check("aucun PostsBody ajouté à la main (%d)" % extra.size(), extra.is_empty())
	for sign in signs:
		if only != "" and not only in str(sign.get_path()):
			continue
		var inside: bool = sign.global_position.y < -20.0
		level.set("_inside", inside)
		level.call("_apply_location")
		await wait(5)
		# Sans dessin pendant la marche : sous Xvfb, le rendu logiciel de chaque image prendrait des heures.
		RenderingServer.render_loop_enabled = false
		await _audit(sign)
		RenderingServer.render_loop_enabled = true
		if shots:
			await _shots(sign)
	finish()


func _find_signs(node: Node, list: Array[Node3D]) -> void:
	var script: Script = node.get_script()
	if script and script.resource_path == SIGN_SCRIPT:
		list.append(node)
	for child in node.get_children():
		_find_signs(child, list)


func _collect(node: Node) -> void:
	if node == player:
		return
	if node is MeshInstance3D and node.mesh:
		meshes.append(node)
	elif node is MultiMeshInstance3D and node.multimesh and node.multimesh.mesh:
		multimeshes.append(node)
	for child in node.get_children(true):
		_collect(child)


func tri(mesh: Mesh) -> TriangleMesh:
	if not tri_cache.has(mesh):
		tri_cache[mesh] = mesh.generate_triangle_mesh()
	return tri_cache[mesh]


## Repère horizontal du panneau : origine à son pied, x le long de la planche, z vers sa face.
func frame_of(sign: Node3D) -> Transform3D:
	var basis := sign.global_basis.orthonormalized()
	var forward := basis.z
	if absf(forward.y) > 0.7:
		# Panneau couché (journal posé à plat) : le repère de son Readable.
		basis = (sign.get_parent() as Node3D).global_basis.orthonormalized()
		forward = basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := Vector3.UP.cross(forward).normalized()
	return Transform3D(Basis(right, Vector3.UP, forward), sign.global_position)


func label_of(sign: Node3D) -> String:
	return str(sign.get_path()).replace("/root/Desert/", "")


func sign_body(sign: Node3D) -> StaticBody3D:
	for child in sign.get_children(true):
		if child is StaticBody3D:
			return child
	return null


func is_sign(collider: Object, sign: Node3D) -> bool:
	return collider is Node and (collider == sign or sign.is_ancestor_of(collider))


func ray_hits_sign(from: Vector3, to: Vector3, sign: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player.get_rid()]
	var hit := space.intersect_ray(query)
	return not hit.is_empty() and is_sign(hit.collider, sign)


func _audit(sign: Node3D) -> void:
	var name := label_of(sign)
	var mount: int = sign.mount
	var size: Vector2 = sign.board_size
	var height: float = sign.board_height
	var shapes := sign.find_children("*", "CollisionShape3D", true, false)
	var expected := 3 if mount == 0 else 1
	check("%s : %d forme(s) de collision du SignBoard (%d)" % [name, expected, shapes.size()], shapes.size() == expected)
	check("%s : collision du SignBoard active" % name, sign.collision)
	var frame := frame_of(sign)
	var tilted := absf(sign.global_basis.z.normalized().y) > 0.7
	# Rayons dessous, sur la planche et sur les poteaux (panneaux debout seulement).
	if not tilted:
		var xf := sign.global_transform
		var bottom := height - size.y / 2.0
		if mount == 0:
			var under_free := true
			var h := 0.1
			while h < bottom - 0.08:
				for x in [-size.x / 2.0 + 0.2, 0.0, size.x / 2.0 - 0.2]:
					if ray_hits_sign(xf * Vector3(x, h, 1.2), xf * Vector3(x, h, -1.2), sign):
						under_free = false
						print("    bloqué sous la planche à x %.2f, h %.2f" % [x, h])
				h += 0.1
			check("%s : rien ne bloque sous la planche (de 0,1 m à %.2f m)" % [name, bottom - 0.08], under_free)
			for side in [-1.0, 1.0]:
				var x: float = side * (size.x / 2.0 + 0.03)
				check("%s : poteau %s bloque (face et côté)" % [name, "gauche" if side < 0 else "droit"],
					ray_hits_sign(xf * Vector3(x, 0.4, 1.2), xf * Vector3(x, 0.4, -1.2), sign)
					and ray_hits_sign(xf * Vector3(x + side * 1.0, 0.4, -0.1), xf * Vector3(x - side * 0.05, 0.4, -0.1), sign))
		# Au mur, le dos est contre la pierre : seule la face se teste.
		check("%s : la planche bloque de face%s" % [name, " et de dos" if mount == 0 else ""],
			ray_hits_sign(xf * Vector3(0, height, 1.2), xf * Vector3(0, height, -1.2), sign)
			and (mount != 0 or ray_hits_sign(xf * Vector3(0, height, -1.2), xf * Vector3(0, height, 1.2), sign)))
		# Au-dessus de la planche et au-delà des poteaux : libre.
		check("%s : rien au-dessus de la planche" % name,
			not ray_hits_sign(xf * Vector3(0, height + size.y / 2.0 + 0.2, 1.2), xf * Vector3(0, height + size.y / 2.0 + 0.2, -1.2), sign))
		check("%s : rien au-delà des bords" % name,
			not ray_hits_sign(xf * Vector3(size.x / 2.0 + 0.35, height, 1.2), xf * Vector3(size.x / 2.0 + 0.35, height, -1.2), sign)
			and not ray_hits_sign(xf * Vector3(-size.x / 2.0 - 0.35, height, 1.2), xf * Vector3(-size.x / 2.0 - 0.35, height, -1.2), sign))

	# Grille de marche.
	var pivot: Node3D = player.get_node("CameraPivot")
	var touched := {}
	var invisible := 0
	var stuck := 0
	var falls := 0
	var other := {}
	var rows: Array[String] = []
	var half_u := size.x / 2.0 + MARGIN
	var v := -MARGIN
	while v <= MARGIN + 0.001:
		var row := ""
		var u := -half_u
		while u <= half_u + 0.001:
			var p := frame * Vector3(u + JITTER, 0.0, v + JITTER)
			var down := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.5, p + Vector3.DOWN * 3.0)
			down.exclude = [player.get_rid()]
			var floor_hit := space.intersect_ray(down)
			if floor_hit.is_empty():
				row += " "
				u += STEP
				continue
			var ground: Vector3 = floor_hit.position
			if ground.y - frame.origin.y > 0.6:
				row += "^"
				u += STEP
				continue
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis(), ground + Vector3.UP * 0.93)
			query.exclude = [player.get_rid()]
			if not space.intersect_shape(query, 1).is_empty():
				row += "#"
				u += STEP
				continue
			var mark := "."
			var moved_max := 0.0
			for index in 8:
				var yaw := TAU * index / 8.0
				player.global_position = ground + Vector3.UP * 0.02
				player.velocity = Vector3.ZERO
				pivot.rotation.y = yaw
				await physics_frame
				Input.action_press("move_forward")
				var start: Vector3 = player.global_position
				for f in WALK_FRAMES:
					await physics_frame
					for c in player.get_slide_collision_count():
						var collision: KinematicCollision3D = player.get_slide_collision(c)
						for k in collision.get_collision_count():
							var normal := collision.get_normal(k)
							if normal.y > 0.7:
								continue
							var contact := collision.get_position(k)
							var collider := collision.get_collider(k)
							var key := Vector3i(roundi(contact.x * 10.0), roundi(contact.y * 10.0), roundi(contact.z * 10.0))
							if is_sign(collider, sign):
								touched[collision.get_collider_shape_index(k)] = true
								if mark == ".":
									mark = "o"
								if not _visible_near(contact, 0.5):
									invisible += 1
									mark = "!"
									print("    mur invisible du panneau : contact %s (point %s, direction %d)" % [contact.snappedf(0.01), ground.snappedf(0.01), index])
							elif not other.has(key):
								other[key] = true
								if not _visible_near(contact, 0.5):
									print("    contact sans modèle visible à 0,5 m (autre objet %s) : %s" % [
										str(collider.get_path()).replace("/root/Desert/", "") if collider is Node else "?", contact.snappedf(0.01)])
				Input.action_release("move_forward")
				var moved: Vector3 = player.global_position - start
				moved_max = maxf(moved_max, Vector2(moved.x, moved.z).length())
				if player.global_position.y < ground.y - 1.0:
					falls += 1
					print("    chute depuis %s" % ground.snappedf(0.01))
			if moved_max < 0.2:
				stuck += 1
				mark = "X"
				print("    joueur coincé en %s" % ground.snappedf(0.01))
			row += mark
			u += STEP
		rows.append(row)
		v += STEP
	print("GRILLE %s (dos en haut, face en bas ; . libre, o bute sur le panneau, ! mur invisible, # occupé, ^ sur un objet, X coincé) :" % name)
	for row in rows:
		print("    |" + row + "|")
	check("%s : aucun mur invisible autour ni dessous (%d)" % [name, invisible], invisible == 0)
	check("%s : joueur jamais coincé (%d)" % [name, stuck], stuck == 0)
	check("%s : aucune chute (%d)" % [name, falls], falls == 0)
	if mount == 0:
		check("%s : on bute sur les deux poteaux et la planche (formes touchées %s)" % [name, touched.keys()], touched.size() == 3)
	else:
		check("%s : on bute sur la planche (formes touchées %s)" % [name, touched.keys()], touched.size() >= 1 or tilted)


## Un triangle visible à moins de r du point : 14 petits segments autour de lui contre les maillages proches.
func _visible_near(point: Vector3, r: float) -> bool:
	var segments: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.UP, Vector3.DOWN]
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				segments.append(Vector3(sx, sy, sz).normalized())
	for mesh in meshes:
		if not is_instance_valid(mesh) or not mesh.is_visible_in_tree():
			continue
		var xform := mesh.global_transform
		if not (xform * mesh.get_aabb()).grow(r).has_point(point):
			continue
		if _segments_hit(tri(mesh.mesh), xform, point, r, segments):
			return true
	for instance in multimeshes:
		if not is_instance_valid(instance) or not instance.is_visible_in_tree():
			continue
		var local_box := instance.multimesh.mesh.get_aabb()
		for index in instance.multimesh.instance_count:
			var xform := instance.global_transform * instance.multimesh.get_instance_transform(index)
			if not (xform * local_box).grow(r).has_point(point):
				continue
			if _segments_hit(tri(instance.multimesh.mesh), xform, point, r, segments):
				return true
	return false


func _segments_hit(shape: TriangleMesh, xform: Transform3D, point: Vector3, r: float, segments: Array[Vector3]) -> bool:
	if shape == null:
		return false
	var inverse := xform.affine_inverse()
	for direction in segments:
		if not shape.intersect_segment(inverse * (point - direction * r), inverse * (point + direction * r)).is_empty():
			return true
	return false


func _shots(sign: Node3D) -> void:
	level.get_node("Hud").visible = false
	var camera := Camera3D.new()
	camera.fov = 60.0
	camera.far = 300.0
	level.add_child(camera)
	camera.current = true
	var frame := frame_of(sign)
	var tilted := absf(sign.global_basis.z.normalized().y) > 0.7
	var center: Vector3 = sign.global_transform * Vector3(0, sign.board_height, 0)
	var views := []
	if tilted:
		views.append(["dessus", center + frame.basis.z * 1.0 + Vector3.UP * 1.4])
	else:
		var distance := clampf(sign.board_size.x * 1.3, 1.6, 3.0)
		views.append(["face", center + frame.basis.z * distance + Vector3.UP * 0.1])
		views.append(["biais", center + frame.basis.z * distance * 1.6 + frame.basis.x * distance * 1.2 + Vector3.UP * 0.6])
		if sign.double_sided:
			views.append(["dos", center - frame.basis.z * distance + Vector3.UP * 0.1])
	# Le joueur, invisible en première personne, est écarté pour ne pas gêner.
	player.global_position = frame.origin + frame.basis.z * 8.0
	for view: Array in views:
		camera.global_position = view[1]
		camera.look_at(center, Vector3.UP)
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out_dir + "%s_%s.png" % [label_of(sign).validate_filename().replace("/", "_"), view[0]])
	camera.queue_free()
	level.get_node("Hud").visible = true
	await process_frame
