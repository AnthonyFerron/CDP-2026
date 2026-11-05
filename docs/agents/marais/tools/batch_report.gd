extends SceneTree
## Rapport sur le décor regroupé : par maillage fondu, son matériau (transparence, sans ombrage), son ombre, sa
## portée, sa boîte, ses pièces et les lumières ponctuelles qui touchent sa boîte (limite du rendu Compatibility :
## 8 par objet). Puis la liste des maillages restés seuls sous les racines regroupées.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	change_scene_to_file("res://scenes/levels/marais/marais.tscn")
	for i in 10:
		await process_frame
	var level: Node3D = current_scene
	if "--range12" in OS.get_cmdline_user_args():
		for light in level.get_node("Interior").get_children():
			if light is OmniLight3D and String(light.name).begins_with("Light"):
				(light as OmniLight3D).omni_range = 12.0
	var lights: Array[OmniLight3D] = []
	for light in level.find_children("*", "OmniLight3D", true, false):
		lights.append(light)
	var worst := 0
	var transparent := 0
	for path in ["Props/Models", "Grounded", "Scatter/Boardwalks", "Scatter/Lanterns", "Interior/Crypt/Models"]:
		var base: Node3D = level.get_node(path)
		var merged := 0
		var lone := 0
		for node in base.find_children("*", "MeshInstance3D", true, false):
			var item := node as MeshInstance3D
			if not item.mesh:
				continue
			var box := item.global_transform * item.mesh.get_aabb()
			var touching := 0
			for light in lights:
				var center := light.global_position
				var nearest := center.clamp(box.position, box.end)
				if nearest.distance_to(center) < light.omni_range:
					touching += 1
			if not item.has_meta(&"pieces"):
				lone += 1
				continue
			merged += 1
			worst = maxi(worst, touching)
			var material := item.mesh.surface_get_material(0)
			var info := ""
			if material is BaseMaterial3D:
				var base_material := material as BaseMaterial3D
				if base_material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					info += " transparent"
					transparent += 1
				if base_material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
					info += " sans-ombrage"
				if base_material.emission_enabled:
					info += " émissif"
				info += " tex=%s col=%s" % [base_material.albedo_texture.resource_path.get_file() if base_material.albedo_texture else "-", base_material.albedo_color.to_html(false)]
			elif material:
				info += " " + material.get_class()
			var pieces: Array = item.get_meta(&"pieces")
			var names := {}
			for piece in pieces:
				names[piece[0]] = true
			print("LOT %s/%s : %d pièces (%s), ombre %s, portée %.0f, boîte %s, lumières %d%s" % [path, item.name, pieces.size(),
				", ".join(names.keys().slice(0, 4)), item.cast_shadow != 0, item.visibility_range_end,
				box.size.snappedf(0.1), touching, info])
		print("RACINE %s : %d maillages fondus, %d seuls" % [path, merged, lone])
	print("LOTS : lumières max sur un maillage fondu %d, transparents %d" % [worst, transparent])
	# Toutes les formes de collision du niveau (monde), triées : à comparer avant et après le regroupement.
	var lines: PackedStringArray = []
	for node in level.find_children("*", "CollisionShape3D", true, false):
		var shape_node := node as CollisionShape3D
		if not shape_node.shape:
			continue
		var body := shape_node.get_parent() as CollisionObject3D
		var t := shape_node.global_transform
		var desc := shape_node.shape.get_class()
		for property in ["size", "radius", "height"]:
			if property in shape_node.shape:
				desc += " %s=%s" % [property, str(shape_node.shape.get(property)).replace(" ", "")]
		if shape_node.shape is ConvexPolygonShape3D:
			desc += " points=%d" % (shape_node.shape as ConvexPolygonShape3D).points.size()
		if shape_node.shape is ConcavePolygonShape3D:
			desc += " faces=%d" % (shape_node.shape as ConcavePolygonShape3D).get_faces().size()
		lines.append("%s | %s | %s | couche %d | %s" % [str(t.origin.snappedf(0.001)), str(t.basis.get_euler().snappedf(0.001)),
			desc, body.collision_layer if body else -1, "actif" if not shape_node.disabled else "coupé"])
	lines.sort()
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 and not args[0].begins_with("--") else "/tmp/collisions.txt"
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("COLLISIONS %d formes écrites dans %s" % [lines.size(), out])
	state.reset()
	quit()
