extends SceneTree
## Copie de cam_shots.gd, avec des réglages d'ombre à essayer :
## sun=mode,distance[,tranche1] filter=qualité atlas=taille blur=flou bias=biais,biais_normal
## Captures depuis des caméras libres : -- <scène> <dossier> <nom>=x,y,z:tx,ty,tz [ortho=<taille>] ...
## Un dossier relatif est pris sous user://captures/. Les arguments en « -- » (comme --api=…) sont ignorés.
const BASE := "user://captures/"

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
	var out := (args[1] if args[1].is_absolute_path() else BASE + args[1]) + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	change_scene_to_file(args[0])
	await frames(30)
	var level: Node = current_scene
	if level.has_node("Hud"):
		level.get_node("Hud").visible = false
	if level.has_node("Player"):
		level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	var camera := Camera3D.new()
	camera.fov = 75.0
	camera.far = 500.0
	level.add_child(camera)
	camera.current = true
	for entry in args.slice(2):
		# inside : passe le niveau à l'intérieur, comme sa porte.
		# noshadow : coupe les ombres du soleil, pour comparer.
		if entry == "noshadow":
			level.get_node("Sun").shadow_enabled = false
			await frames(4)
			continue
		if entry.begins_with("sun="):
			var v := entry.substr(4).split(",")
			var sun: DirectionalLight3D = level.get_node("Sun") if level.has_node("Sun") else level.get_node("Moon")
			sun.directional_shadow_mode = int(v[0])
			sun.directional_shadow_max_distance = float(v[1])
			if v.size() > 2:
				sun.directional_shadow_split_1 = float(v[2])
			await frames(4)
			continue
		if entry.begins_with("filter="):
			RenderingServer.directional_soft_shadow_filter_set_quality(int(entry.substr(7)) as RenderingServer.ShadowQuality)
			await frames(4)
			continue
		if entry.begins_with("atlas24="):
			RenderingServer.directional_shadow_atlas_set_size(int(entry.substr(8)), false)
			await frames(4)
			continue
		if entry == "noterrain":
			for m: GeometryInstance3D in level.get_node("Terrain").find_children("*", "GeometryInstance3D", true, false):
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			await frames(4)
			continue
		if entry == "terrain":
			for m: GeometryInstance3D in level.get_node("Terrain").find_children("*", "GeometryInstance3D", true, false):
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			await frames(4)
			continue
		if entry.begins_with("blend="):
			var s3: DirectionalLight3D = level.get_node("Sun") if level.has_node("Sun") else level.get_node("Moon")
			s3.directional_shadow_blend_splits = entry.substr(6) == "1"
			await frames(4)
			continue
		if entry.begins_with("margin="):
			for m: GeometryInstance3D in level.get_node("Player/Visual").find_children("*", "GeometryInstance3D", true, false):
				m.extra_cull_margin = float(entry.substr(7))
			await frames(4)
			continue
		if entry.begins_with("pancake="):
			var s4: DirectionalLight3D = level.get_node("Sun") if level.has_node("Sun") else level.get_node("Moon")
			s4.directional_shadow_pancake_size = float(entry.substr(8))
			await frames(4)
			continue
		if entry.begins_with("atlas="):
			RenderingServer.directional_shadow_atlas_set_size(int(entry.substr(6)), true)
			await frames(4)
			continue
		if entry.begins_with("blur="):
			var s2: DirectionalLight3D = level.get_node("Sun") if level.has_node("Sun") else level.get_node("Moon")
			s2.shadow_blur = float(entry.substr(5))
			await frames(4)
			continue
		if entry.begins_with("bias="):
			var values := entry.substr(5).split(",")
			(level.get_node("Sun") if level.has_node("Sun") else level.get_node("Moon")).shadow_bias = float(values[0])
			(level.get_node("Sun") if level.has_node("Sun") else level.get_node("Moon")).shadow_normal_bias = float(values[1])
			await frames(4)
			continue
		if entry == "inside":
			level.set("_inside", true)
			level.call("_apply_location")
			await frames(4)
			continue
		var name := entry.split("=")[0]
		var spec := entry.split("=")[1]
		var parts := spec.split(":")
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		if parts.size() > 2:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = float(parts[2])
		camera.global_position = vec(parts[0])
		var target := vec(parts[1])
		var up := Vector3.FORWARD if absf((target - camera.global_position).normalized().y) > 0.99 else Vector3.UP
		camera.look_at(target, up)
		await frames(8)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + name + ".png")
	state.reset()
	quit()
