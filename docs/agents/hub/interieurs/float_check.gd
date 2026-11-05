extends SceneTree
## Objets qui flottent ou s'enfoncent, modèle par modèle : une copie du décor (hub_props.tscn) est chargée sans
## regroupement en MultiMesh, ses éléments réparables montrés selon les livres posés ; pour chaque modèle posé, le
## dessous de sa boîte (tous ses maillages) est comparé à ce qui le porte, un rayon tiré depuis son pied dans la vraie
## scène. Signale les modèles de 4 à 60 cm au-dessus de leur appui (au-delà : accrochés exprès), et ceux dont le sol
## passe à plus de 35 % de leur hauteur au-dessus de leur pied. -- <livres>
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]
## Intérieurs : les petits objets posés sur les tables et les étagères sont contrôlés aussi. Ne restent écartés que les
## pièces accrochées ou empilées par construction (murs, toits, planches, montants, bannières, boucliers au mur).
const SKIP := ["banner", "flag", "shield", "roof", "chimney", "overhang", "planks", "metal-gate", "wall", "pillar", "tower",
	"crops_", "crop_", "flower", "rug", "watermill", "bridge", "fountain", "campfire_logs", "weapon-sword"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var books := int(OS.get_cmdline_user_args()[0])
	# Seuls les groupes des bâtiments (maisons et lieux du pourtour) : Repairs/<nom>.
	var only := ["House", "School", "Tavern", "Chapel", "Forge", "Farm", "Bakery", "Mill", "Stables", "Barracks", "Apothecary",
		"Scriptorium", "Observatory"]
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	for index in books:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	for i in 40:
		await physics_frame
	var level: Node3D = current_scene
	var space: PhysicsDirectSpaceState3D = level.get_world_3d().direct_space_state
	var props: Node3D = load("res://scenes/levels/hub/hub_props.tscn").instantiate()
	props.set_script(null)
	# Sans collision : seule la vraie scène porte les rayons.
	for body in props.find_children("*", "CollisionObject3D", true, false):
		body.get_parent().remove_child(body)
		body.free()
	level.add_child(props)
	for item in props.get_node("Repairs").get_children():
		var done: bool = books >= int(item.get_meta(&"stage", 1))
		for part_name in ["Ruins", "Rebuilt"]:
			if item.has_node(part_name):
				item.get_node(part_name).visible = done == (part_name == "Rebuilt")
	await process_frame
	var floating := []
	var sunk := []
	for model in props.find_children("*", "Node3D", true, false):
		if model.scene_file_path.is_empty() or not model.is_visible_in_tree():
			continue
		var name := model.scene_file_path.get_file().get_basename()
		var owner_path := String(props.get_path_to(model))
		var wanted := false
		for prefix in only:
			if owner_path.begins_with("Repairs/" + prefix):
				wanted = true
		if not wanted:
			continue
		var skip := false
		for word in SKIP:
			if name.contains(word):
				skip = true
		if skip:
			continue
		var box := AABB()
		var first := true
		for mesh_instance: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			var part: AABB = mesh_instance.global_transform * mesh_instance.get_aabb()
			box = part if first else box.merge(part)
			first = false
		if first or box.size.y < 0.03:
			continue
		var center := box.get_center()
		var ray := PhysicsRayQueryParameters3D.create(Vector3(center.x, box.position.y + 0.03, center.z), Vector3(center.x, box.position.y - 2.0, center.z))
		var hit: Dictionary = space.intersect_ray(ray)
		var group := String(props.get_path_to(model.get_parent()))
		if hit:
			var gap: float = box.position.y - hit.position.y
			if gap > 0.04 and gap < 0.6:
				floating.append([group, name, snappedf(center.x, 0.1), snappedf(center.z, 0.1), snappedf(gap, 0.01)])
		# Enfoncé : le sol, mesuré du dessus, passe nettement au-dessus de son pied.
		var down := PhysicsRayQueryParameters3D.create(Vector3(center.x, box.end.y + 0.5, center.z), Vector3(center.x, box.position.y - 0.5, center.z))
		down.collide_with_bodies = true
		var terrain_hit: Dictionary = space.intersect_ray(down)
		if terrain_hit and terrain_hit.collider == level.get_node("Terrain"):
			var buried: float = terrain_hit.position.y - box.position.y
			if buried > maxf(0.15, box.size.y * 0.35):
				sunk.append([group, name, snappedf(center.x, 0.1), snappedf(center.z, 0.1), snappedf(buried, 0.01)])
	print("FLOTTANTS %d" % floating.size())
	for entry in floating:
		print("  ", entry)
	print("ENFONCES %d" % sunk.size())
	for entry in sunk:
		print("  ", entry)
	state.reset()
	quit()
