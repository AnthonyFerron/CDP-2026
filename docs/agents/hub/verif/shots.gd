extends SceneTree
## Captures du hub depuis des caméras libres, avec un nombre de livres posés :
##   -- <dossier> <livres> <fichier de vues> [colonnes de la planche]
## Fichier de vues : une ligne par capture, « nom x,y,z tx,ty,tz [ortho] ». Une vue sous y = -20 montre l'abri.
## Le décor est regroupé d'un bloc (finish_all) avant les captures. Planches de colonnes x colonnes vues, avec le
## nom de chaque vue dans le journal.
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in count:
		await process_frame

func vec(text: String) -> Vector3:
	var p := text.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))

func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	var out := args[0] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var books := int(args[1])
	var columns := int(args[3]) if args.size() > 3 else 2
	var state: Node = root.get_node("GameState")
	state.reset()
	state.begin_mission()
	state.intro_done = true
	for index in books:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await frames(40)
	var level: Node = current_scene
	level.get_node("Props").finish_all()
	level.get_node("Hud").visible = false
	var player: Node3D = level.get_node("Player")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.visible = false
	var camera := Camera3D.new()
	camera.fov = 75.0
	camera.near = 0.05
	camera.far = 500.0
	level.add_child(camera)
	camera.current = true
	var lines := FileAccess.get_file_as_string(args[2]).split("\n", false)
	var cell := Vector2i(1280 / columns, 720 / columns)
	var sheet: Image
	var sheet_names: Array[String] = []
	var sheet_index := 0
	var inside := false
	var count := 0
	for line in lines:
		var parts := line.strip_edges().split(" ", false)
		if parts.size() < 3 or line.begins_with("#"):
			continue
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		if parts.size() > 3:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = float(parts[3])
		# « x,gH,z » : à H mètres au-dessus du sol où l'on se tient (le premier sol porteur sous le point, la capsule
		# du joueur libre) ; la cible est alors relative à la hauteur de la caméra. Sans sol libre à 1 m près : sautée.
		var ground_relative := parts[1].split(",")[1].begins_with("g")
		if ground_relative:
			var p := parts[1].split(",")
			var spot: Variant = stand(level, float(p[0]), float(p[2]))
			if spot == null:
				print("SAUTEE %s" % parts[0])
				continue
			camera.global_position = spot + Vector3(0, float(p[1].substr(1)), 0)
		else:
			camera.global_position = vec(parts[1])
		var below := camera.global_position.y < -20.0
		if below != inside:
			inside = below
			level.call("_set_location", inside)
		# Le joueur suit la caméra, pour les scripts qui regardent où il est (lumières des intérieurs, villageois).
		player.global_position = camera.global_position - Vector3(0, 1.6, 0)
		var target := vec(parts[2])
		if ground_relative:
			target.y += camera.global_position.y
		var up := Vector3.FORWARD if absf((target - camera.global_position).normalized().y) > 0.99 else Vector3.UP
		camera.look_at(target, up)
		await frames(int(OS.get_environment("IMAGES")) if OS.get_environment("IMAGES") != "" else 8)
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png(out + parts[0] + ".png")
		count += 1
		var small := image.duplicate() as Image
		small.resize(cell.x, cell.y, Image.INTERPOLATE_BILINEAR)
		if sheet == null:
			sheet = Image.create(1280, 720, false, small.get_format())
		var slot := sheet_names.size()
		sheet.blit_rect(small, Rect2i(Vector2i.ZERO, cell), Vector2i((slot % columns) * cell.x, (slot / columns) * cell.y))
		sheet_names.append(parts[0])
		if sheet_names.size() == columns * columns:
			sheet.save_png(out + "planche_%03d.png" % sheet_index)
			print("PLANCHE %03d : %s" % [sheet_index, " ".join(sheet_names)])
			sheet_index += 1
			sheet = null
			sheet_names.clear()
	if sheet != null:
		sheet.save_png(out + "planche_%03d.png" % sheet_index)
		print("PLANCHE %03d : %s" % [sheet_index, " ".join(sheet_names)])
	print("CAPTURES ", count)
	state.reset()
	quit()


## Sol libre le plus proche du point (x, z), à 1 m près : le premier sol porteur sous le point où la capsule du joueur
## tient debout.
func stand(level: Node, x: float, z: float) -> Variant:
	var terrain: Node = level.get_node("Terrain")
	var space := (level as Node3D).get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	var rid: RID = (level.get_node("Player") as CollisionObject3D).get_rid()
	for offset: Vector2 in [Vector2.ZERO, Vector2(0.5, 0), Vector2(-0.5, 0), Vector2(0, 0.5), Vector2(0, -0.5),
			Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var px := x + offset.x
		var pz := z + offset.y
		var top: float = terrain.surface_height(px, pz) + 2.5
		var ray := PhysicsRayQueryParameters3D.create(Vector3(px, top, pz), Vector3(px, top - 6.0, pz))
		ray.exclude = [rid]
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or hit.normal.y < 0.7:
			continue
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis(), hit.position + Vector3(0, 1.0, 0))
		query.exclude = [rid]
		if space.intersect_shape(query, 1).is_empty():
			return hit.position
	return null
