extends SceneTree
## Végétation du hub : chaque touffe, fleur, champignon et buisson posé (jardin du roi : pièces des lots fondus ;
## décor dispersé : copies des MultiMesh) contre les cases gravillonnées ou de terre battue du sol (une couleur par
## case de 2 m, prise au centre de la case) et contre les collisions (murs, haies, bancs, socles).
## Arguments : -- <livres>. Une ligne « ALLEE » ou « DANS » par pousse fautive, puis le compte.
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]
const PLANTS := ["grass", "flower", "mushroom", "plant_bush", "bush", "plant_flat", "lily", "reed"]


func _initialize() -> void:
	_run.call_deferred()


func is_plant(text: String) -> bool:
	for word in PLANTS:
		if text.contains(word):
			return true
	return false


func _run() -> void:
	var args := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			args.append(a)
	var books := int(args[0])
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	state.intro_done = true
	for index in books:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	for i in 30:
		await physics_frame
	var level: Node3D = current_scene
	level.get_node("Props").finish_all()
	await physics_frame
	var terrain: Node = level.get_node("Terrain")
	var space := level.get_world_3d().direct_space_state
	var player: CollisionObject3D = level.get_node("Player")
	var plants := []
	for node in level.find_children("*", "GeometryInstance3D", true, false):
		var geometry := node as GeometryInstance3D
		if not geometry.is_visible_in_tree() or geometry.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			continue
		var label := String(level.get_path_to(geometry))
		if geometry.has_meta(&"pieces"):
			for piece: Array in geometry.get_meta(&"pieces"):
				if is_plant(str(piece[0])):
					plants.append([label + " " + str(piece[0]), piece[1]])
		elif geometry is MultiMeshInstance3D and (geometry as MultiMeshInstance3D).multimesh:
			var multimesh := (geometry as MultiMeshInstance3D).multimesh
			if not multimesh.mesh:
				continue
			var name := multimesh.mesh.resource_path.get_file() + " " + multimesh.mesh.resource_name
			if not is_plant(name) and not is_plant(label):
				continue
			var count := multimesh.visible_instance_count if multimesh.visible_instance_count >= 0 else multimesh.instance_count
			for index in count:
				plants.append([label + " " + name, geometry.global_transform * multimesh.get_instance_transform(index) * multimesh.mesh.get_aabb()])
	var on_path := 0
	var inside := 0
	var query := PhysicsShapeQueryParameters3D.new()
	var probe := BoxShape3D.new()
	query.shape = probe
	query.exclude = [player.get_rid()]
	for entry: Array in plants:
		var box: AABB = entry[0 + 1]
		var label: String = entry[0]
		var center := box.get_center()
		if center.y < -20.0:
			continue
		# Emprise au sol : 70 % de la boîte (les feuilles débordent du pied).
		var half := Vector2(box.size.x, box.size.z) * 0.35
		var worst := 0.0
		var where := Vector2.ZERO
		for cx in range(floori((center.x - half.x + 140.0) / 2.0), floori((center.x + half.x + 140.0) / 2.0) + 1):
			for cz in range(floori((center.z - half.y + 140.0) / 2.0), floori((center.z + half.y + 140.0) / 2.0) + 1):
				var cell := Vector2(-140.0 + cx * 2.0 + 1.0, -140.0 + cz * 2.0 + 1.0)
				var mask := maxf(terrain.gravel_mask(cell.x, cell.y), terrain.path_mask(cell.x, cell.y))
				if mask > worst:
					worst = mask
					where = cell
		if worst > 0.5:
			on_path += 1
			print("ALLEE %s (%.1f, %.1f) taille %.1f x %.1f, case %s masque %.2f" % [label, center.x, center.z, box.size.x, box.size.z, where, worst])
		# Dans une collision : boîte à 50 % de l'emprise, du pied (5 cm) à 80 % de la hauteur.
		probe.size = Vector3(maxf(box.size.x * 0.5, 0.05), maxf(box.size.y * 0.75, 0.05), maxf(box.size.z * 0.5, 0.05))
		query.transform = Transform3D(Basis(), Vector3(center.x, box.position.y + 0.05 + probe.size.y * 0.5, center.z))
		for hit in space.intersect_shape(query, 4):
			var collider: Object = hit.collider
			if collider == terrain or collider is Area3D:
				continue
			var name := String(level.get_path_to(collider as Node)) if collider is Node else str(collider)
			if name.begins_with("River/Banks"):
				continue
			inside += 1
			print("DANS %s (%.1f, %.1f, %.1f) taille %.1f x %.1f x %.1f : %s" % [label, center.x, box.position.y, center.z, box.size.x, box.size.y, box.size.z, name])
			break
	print("POUSSES %d livres : %d pousses, %d sur une allée ou un chemin, %d dans une collision" % [books, plants.size(), on_path, inside])
	state.reset()
	quit()
